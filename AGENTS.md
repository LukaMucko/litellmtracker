# AGENTS.md — LiteLLMBar

Native macOS menu-bar app (SwiftUI, no third-party dependencies). Tracks LiteLLM proxy spend.

## Platform & Toolchain

- **macOS 26 Tahoe+ required**, Apple Silicon only (`arch=arm64`).
- Full Xcode required; `xcodebuild` needs the GUI toolchain:
  ```sh
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```
- **Zero external dependencies** — only Apple frameworks (SwiftUI, Foundation, OSLog, AppKit, Observation, ServiceManagement, Charts).

## Build & Run

```sh
# Build only
xcodebuild -scheme LiteLLMBar -destination 'platform=macOS,arch=arm64' build

# Run tests (Swift Testing, not XCTest)
xcodebuild -scheme LiteLLMBar -destination 'platform=macOS,arch=arm64' test

# Convenience script: build, kill previous instance, then launch / debug / stream logs
script/build_and_run.sh           # build + open
script/build_and_run.sh --debug   # build + lldb
script/build_and_run.sh --logs    # build + open + os_log stream
script/build_and_run.sh --verify  # build + open + assert process exists
```

## Architecture at a Glance

| Directory | Role |
|---|---|
| `LiteLLMBar/App/` | Entry point: `LiteLLMBarApp.swift` (`@main` `MenuBarExtra` app) |
| `LiteLLMBar/Services/` | `SpendStore` (central `@MainActor @Observable` state), `LiteLLMClient` (actor), `ExchangeRateService`, `KeychainStore` |
| `LiteLLMBar/Model/` | `DailyActivity`, `SpendSummary`, `ChartPoint`, `ModelSpend`, etc. |
| `LiteLLMBar/Views/` | SwiftUI views; `PopoverView`, `SettingsView`, `SpendChartView`, … |
| `LiteLLMBar/MenuBar/` | `MenuBarLabel`, `PopoverView` |
| `LiteLLMBar/Utilities/` | `CurrencyFormatter`, `LaunchAtLogin`, `Logger+Category` |
| `Tests/` | Swift Testing targets (`LiteLLMBarTests`) |

- **Single source of truth**: `SpendStore`, injected into views via `.environment(store)`.
- **Networking**: `LiteLLMClient` is an `actor`. It polls `GET {baseURL}/user/daily/activity?start_date=…&end_date=…` with Bearer auth and retries 429 / 5xx.
- **Currency**: USD/EUR toggle; EUR rate fetched live from `api.frankfurter.app`.

## Key Code Conventions

### 1. Lossy JSON Decoding
The LiteLLM API returns numbers as strings, ints, or doubles inconsistently. The model layer (`DailyActivity.swift`) uses custom `KeyedDecodingContainer` helpers:
- `decodeLossyDouble(forKey:)`
- `decodeLossyInt(forKey:)`
- `decodeLossyOptionalInt(forKey:)`

When adding new numeric fields from the API, use these helpers instead of standard `decode(_:forKey:)`.

### 2. UTC Calendar Extension
All date math for API queries uses `Calendar.liteLLMUTC` (a UTC calendar extension). Do not use `Calendar.current` for range calculations that must align with server-side daily buckets.

### 3. API Key Resolution
The app never writes the key itself. It reads (in order):
1. Environment variable `LITELLM_API_KEY`
2. File `~/.config/litellmtracker/api_key`

`APIKeyStore` exposes `load()` and `refreshFromShell()`; tests may need to mock or avoid the keychain/config path.

### 4. Observed State Pattern
`SpendStore` is `@MainActor @Observable` with `@ObservationIgnored` on private internals (tasks, services). Views observe published properties directly; do not add unnecessary `@State` wrappers around store properties.

## Testing Notes

- Framework: **Swift Testing** (`import Testing`, `#expect`).
- Tests import the app module with `@testable import LiteLLMBar`.
- Tests focus on:
  - JSON decoding edge cases (missing fields, empty model breakdowns).
  - `SpendSummary` aggregation logic over date ranges.
- No integration tests against a real LiteLLM proxy; all tests are offline/unit.

## Entitlements & Sandbox

- Only entitlement: `com.apple.security.network.client`.
- App is sandboxed for network-out only; no file-system access beyond user-selected paths.

## Gotchas

- `MenuBarExtra` uses `.menuBarExtraStyle(.window)` (not `.menu`). The popover is a full window, not a traditional NSMenu.
- `LaunchAtLogin` uses `ServiceManagement` (`SMAppService.mainApp.register()`); requires the app to be in `/Applications` or signed for login-item registration to succeed.
- `script/build_and_run.sh` hard-codes the bundle ID `com.litellmtracker.app` and derived-data path `build/DerivedData`; changing the bundle ID in Xcode requires updating the script.
