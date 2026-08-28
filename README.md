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

- **Bar:** left-click start/stop (opens `slurp` for region pick, `Esc` cancels).
- **Hotkeys** (`~/.config/niri/config.kdl`):
  ```kdl
  bind: Mod+Shift+G { spawn -- "screenrec" "start"; }
  bind: Mod+Shift+X { spawn -- "screenrec" "stop"; }
  ```
- **Settings:** output folder (default `~/Downloads`), frame rate (15), format.
- **Deps:** `grim`, `slurp`, `ffmpeg`, `notify-send`; optional `ydotool` (removes the `slurp` start flicker on niri).

## Opencode Go Usage

Shows Opencode Go (Zen) AI usage limits in the bar: **5h / weekly / monthly** percentages,
scraped from the opencode.ai console via your session cookie.

In plugin settings → enable **Opencode Go**, then:
- **Workspace ID** — from the console URL `https://opencode.ai/workspace/<id>/go`.
- **Session cookie** — copy the `auth` cookie value from browser devtools; it expires on logout.

Notes: QML can't send `Cookie` headers, so a local `curl` is used. The data comes from the
console page HTML and may break if opencode.ai changes its format.
