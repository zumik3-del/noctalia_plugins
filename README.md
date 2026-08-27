# ScreenRec

noctalia plugin for screen recording on Wayland (niri) to **MP4 / WebM / MKV / GIF**
via `grim` + `slurp` + `ffmpeg`.

The bar widget shows recording status (pulsing red `REC m:ss`); left-click toggles
record, right-click opens plugin settings.

## Install

**Via noctalia (recommended):**

1. Settings → Plugins → Sources → add repository `https://github.com/zumik3-del/screenrec.git`
2. Click **refresh** in the available plugins list.
3. Install **ScreenRec**. Updates pull the latest commit from the same repo.

**Manual:** run `./install.sh` to symlink the plugin and script and register it in `plugins.json`.

## Usage

- **Bar:** left-click the widget to start/stop, right-click to open settings.
- **Hotkeys** (add to `~/.config/niri/config.kdl`):

  ```kdl
  bind: Mod+Shift+G { spawn -- "screenrec" "start"; }
  bind: Mod+Shift+X { spawn -- "screenrec" "stop"; }
  ```

  On `start`, `slurp` opens: click a monitor for the whole screen, drag for a region, `Esc` to cancel.

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
