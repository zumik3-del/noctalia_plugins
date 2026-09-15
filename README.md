# noctalia plugins

This repo hosts two noctalia plugins, installed together from the same repository.

## Install (both)

1. noctalia → Settings → Plugins → Sources → add `https://github.com/zumik3-del/noctalia_plugins`
2. Refresh, then install **ScreenRec** and/or **Opencode Go Usage**.

Both plugins are installed together from this single repository source; a plugin
folder is never copied or symlinked standalone.

---

## ScreenRec

Screen recording on Wayland (niri) to **MP4 / WebM / MKV / GIF** via `grim` + `slurp` + `ffmpeg`.
Bar widget shows a pulsing red `REC m:ss`; left-click toggles record, right-click opens settings.

### Requirements
The following system tools must be installed:
- `bash` — runs the `screenrec` script.
- `grim` — captures the screen/region.
- `slurp` — selects the recording region.
- `ffmpeg` — encodes frames to video (needs `libx264` for MP4/MKV, `libvpx-vp9` for WebM, and `libvpx`/palette support for GIF).
- `notify-send` (from `libnotify`) — shows start/saved notifications.
- `ydotool` *(optional)* — removes the `slurp` start flicker on niri.

- **Bar:** left-click start/stop (opens `slurp` for region pick, `Esc` cancels).
- **Hotkeys** (`~/.config/niri/config.kdl`):
  ```kdl
  bind: Mod+Shift+G { spawn -- "screenrec" "start"; }
  bind: Mod+Shift+X { spawn -- "screenrec" "stop"; }
  ```
- **Settings:** output folder (default `~/Downloads`), frame rate (15), format.

## Opencode Go Usage

Shows Opencode Go (Zen) AI usage limits in the bar: **5h / weekly / monthly** percentages,
fetched from the opencode.ai console JSON API (`GET https://opencode.ai/console/api/go/status`).

In plugin settings → enable **Opencode Go**, then paste your Opencode API key (`oc_sk_...`).
The key is sent as a `Bearer` token in the `Authorization` header.

### Requirements
The following system tools must be installed:
- `curl` — fetches the API locally (QML can't send an `Authorization` header directly).

You also need an Opencode Go (Zen) account and an API key.

Notes: usage is read from `access.meters.fiveHour` / `.week` / `.month`
(`usedMicroCents` / `limitMicroCents`), with reset times from `resetsAt` (the monthly limit
uses `access.endsAt`). This JSON API may break if opencode.ai changes it.
