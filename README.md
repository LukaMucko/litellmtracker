# LiteLLM Tracker

A native macOS menu bar app for tracking your [LiteLLM](https://github.com/BerriAI/litellm) proxy spend. Shows today's cost at a glance in the menu bar and opens a Liquid Glass popover with spend totals, an activity chart, and a per-model breakdown.

![macOS 26](https://img.shields.io/badge/macOS-26%20Tahoe-blue)

## Features

- **Menu bar label** — live today's spend, e.g. `💸 $4.21`
- **Spend cards** — Today, 7 days, Month, All time
- **Activity chart** — 7D / 30D smooth area chart with hover tooltips
- **Model breakdown** — spend, tokens, and requests per model
- **USD / EUR** — live exchange rate via frankfurter.app
- **Auto-refresh** — configurable interval (10 s – 1 h)
- **Launch at login**

## Requirements

- macOS 26 Tahoe or later
- Apple Silicon Mac
- A running LiteLLM proxy instance
- A LiteLLM virtual key with at minimum **Default** permissions (needs access to `/user/daily/activity`)

## Installation

Download the latest `.zip` from [Releases](../../releases), unzip, drag `LiteLLMBar.app` to `/Applications`, then right-click → **Open** the first time to bypass Gatekeeper.

## Setup

The app reads your API key from one of two places (in order):

1. **Environment variable** — `LITELLM_API_KEY`
2. **Config file** — `~/.config/litellmtracker/api_key`

To use the config file:
```sh
mkdir -p ~/.config/litellmtracker
echo "sk-your-key-here" > ~/.config/litellmtracker/api_key
```

Then open the app, go to **Settings**, enter your LiteLLM proxy base URL (e.g. `https://your-litellm-instance.example.com`), and click **Test & Refresh**.

## Creating a LiteLLM Virtual Key

In your LiteLLM proxy dashboard, go to **Virtual Keys** and create a new key with:

- **Permissions**: Default (allows management routes including `/user/daily/activity`)
- Copy the `sk-...` value and save it to `~/.config/litellmtracker/api_key` or paste it into the app's Settings

> **Note:** Keys with restricted permissions (e.g. only `api` routes) will not be able to fetch spend data. The app needs access to `/user/daily/activity`.

## Building from Source

```sh
git clone https://github.com/LukaMucko/litellmtracker.git
cd litellmtracker
xcodebuild -scheme LiteLLMBar -destination 'platform=macOS,arch=arm64' build
```

If `xcodebuild` complains about Command Line Tools, point it at full Xcode:
```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

No third-party dependencies — the project uses only Apple frameworks.

## How It Works

The app polls one endpoint:

```
GET {baseURL}/user/daily/activity?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

This returns per-day spend with a per-model breakdown. All data is stored in memory only; the API key is never written by the app (you place it in the config file yourself).

## License

MIT
