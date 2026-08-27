# ScreenRec

noctalia plugin for screen recording on Wayland (niri) to **MP4 / WebM / MKV / GIF**
via `grim` + `slurp` + `ffmpeg`.

The bar widget shows recording status (pulsing red `REC m:ss`); left-click toggles
record, right-click opens plugin settings.

## Install

**Via noctalia (recommended):**

1. Settings → Plugins → Sources → add repository `https://github.com/zumik3-del/screenrec`
2. Click **refresh** in the available plugins list.
3. Install **ScreenRec**. Updates pull the latest commit from the same repo.

**Manual:** run `./install.sh` to symlink the plugin and script and register it in `plugins.json`.

## Usage

- **Bar:** left-click the widget to start/stop, right-click to open settings.
  Starting runs `screenrec start`, which opens `slurp` for region selection
  (click a monitor for the whole screen, drag for a region, `Esc` to cancel).
  On niri, a `ydotool` nudge forces slurp's overlay to paint immediately,
  avoiding the flicker.
- **Hotkeys** (add to `~/.config/niri/config.kdl`):

  ```kdl
  bind: Mod+Shift+G { spawn -- "screenrec" "start"; }
  bind: Mod+Shift+X { spawn -- "screenrec" "stop"; }
  ```

  The hotkey path also uses `slurp` for region selection (same `ydotool`
  nudge applies).

## Settings (plugin panel)

- **Output folder** — default `~/Downloads`.
- **Frame rate** — default 15.
- **Format** — `mp4` (H.264), `webm` (VP9), `mkv` (H.264), `gif`.

## Files

```
screenrec/
├── manifest.json   # plugin manifest
├── Main.qml        # entry point
├── BarWidget.qml   # bar status widget
├── Settings.qml    # settings panel
├── screenrec       # recorder script
└── install.sh      # manual install
```

The script is invoked via `pluginApi.pluginDir`, so it does not need to be on `PATH`.

## Dependencies

`grim`, `slurp`, `ffmpeg` (libx264 + libvpx-vp9), `notify-send`.

Optional but recommended: `ydotool` — when present, both the widget and the
hotkey path nudge the pointer (1px out and back) right after `slurp` maps its
surface, forcing an immediate repaint on niri and removing the start flicker.
Without it, selection still works but shows a brief flicker until you move the
mouse. Requires `ydotoold` to be running and able to access `/dev/uinput`
(e.g. be in the `input` group, or start `ydotoold` as a user service).
