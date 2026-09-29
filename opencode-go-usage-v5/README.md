# Opencode Go Usage v5

Bar widget for Noctalia v5 (Luau plugin API) that shows Opencode Go (Zen) AI
usage limits.

## Features

- Bar capsule with the usage percentage of the selected limit
- Left-click opens a panel with 5-hour, weekly and monthly limit cards
- Progress bars, reset countdowns and per-period daily headroom
- Color-coded: primary under 70%, warning at 70%, error at 97%
- Configurable refresh interval and bar limit via plugin settings

## Settings

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `api_key` | string | `""` | Opencode Go API key (`oc_sk_...`) |
| `refresh_interval_sec` | number | `1800` | Polling interval in seconds (60–86400) |
| `bar_limit` | select | `5h` | Which limit the bar shows: `5h`, `week`, `month` |

## Usage

1. Add the plugin from Noctalia Settings → Plugins.
2. Add the bar widget from the Add-widget picker.
3. Set the API key in the plugin settings.
4. Click the bar capsule to open the details panel.

## Architecture

- `service.luau` — headless service, polls the usage endpoint and publishes
  the result to `noctalia.state`
- `bar.luau` — bar widget, renders from the shared state
- `panel.luau` — details panel, watches the shared state

## License

MIT
