# LiteLLMBar

Native macOS 26 menu bar app for LiteLLM spend tracking. It shows today's spend in the menu bar, opens a SwiftUI/Liquid Glass popover with range totals and per-model spend, and stores the LiteLLM virtual key only in Keychain.

## Requirements

- macOS 26 Tahoe
- Xcode 26 or later
- Apple Silicon Mac
- LiteLLM virtual key with Default permissions

No third-party SDKs or Swift Package dependencies are used.

## Build

```sh
xcodebuild -scheme LiteLLMBar -destination 'platform=macOS,arch=arm64' build
```

The project is configured for local signing with `CODE_SIGN_IDENTITY = -`, app sandboxing, and outbound network access. If `xcodebuild` reports that Command Line Tools are selected, install/select full Xcode:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

The Codex Run action and `./script/build_and_run.sh` use the same Xcode project and launch the built `.app`.

## Create The LiteLLM Key

Open the LiteLLM dashboard at:

```text
https://llms.apps.aithyra.at/ui
```

Go to the virtual key creation screen. Use these settings:

- Key type: virtual key
- Permissions: Default
- Default means the key can call AI APIs and Management routes
- Copy the generated `sk-...` key once and paste it into LiteLLMBar Settings

The key creation screen should show a permissions selector where Default is the broad preset for ordinary API use plus management endpoints. Do not choose a restricted preset that excludes management routes, because spend activity is served by `/user/daily/activity`.

If a key was pasted into chat or logs during testing, regenerate it in LiteLLM after validation.

## Runtime Behavior

- The menu bar label is plain text, for example `💸 $0.47`.
- The popover uses `menuBarExtraStyle(.window)` and Liquid Glass cards/buttons.
- API requests use `Authorization: Bearer {key}`.
- A 401 response deletes the saved key, stops polling, and asks for an updated key.
- Base URL, refresh interval, and currency are stored in `UserDefaults`.
- The API key is stored using Keychain service `at.aithyra.litellm.menubar` and account `litellm-api-key`.
- Launch at login uses `SMAppService.mainApp`.

## Endpoint

The app fetches:

```text
GET {baseURL}/user/daily/activity?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

Dates are formatted in UTC as `yyyy-MM-dd`. The decoder is tolerant of missing optional breakdown fields and optional cache token fields.

## Developer ID Signing Later

For Developer ID distribution, change signing from local signing to your Developer ID team in Xcode:

- Set a real `DEVELOPMENT_TEAM`
- Use Developer ID Application signing
- Keep the sandbox and network client entitlement enabled
- Archive and notarize the app before distribution
