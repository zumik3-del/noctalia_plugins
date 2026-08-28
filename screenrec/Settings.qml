import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  readonly property string screenrecBin: (pluginApi ? pluginApi.pluginDir : "") + "/screenrec"

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // initial values come from noctalia settings as a fallback; the actual
  // source of truth is screenrec.conf, so we override with `screenrec get`
  // below once it returns.
  property string valueOutDir: cfg.outDir ?? defaults.outDir ?? "~/Downloads"
  property string valueFps: String(cfg.fps ?? defaults.fps ?? 15)
  property string valueFormat: cfg.format ?? defaults.format ?? "mp4"

  // read-only display of hotkeys assigned to screenrec in the niri config
  property string hotkeyInfo: "…"

  function parseHotkeys(text) {
    var startK = "", stopK = ""
    var lines = text.trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var p = lines[i].split(" ")
      if (p[0] === "NOTFOUND") {
        hotkeyInfo = "Not set — edit niri config"
        return
      }
      if (p.length >= 2) {
        if (p[1] === "start") startK = p[0]
        else if (p[1] === "stop") stopK = p[0]
      }
    }
    if (!startK && !stopK)
      hotkeyInfo = "Not set — edit niri config"
    else
      hotkeyInfo = "Start: " + (startK || "—") + "   ·   Stop: " + (stopK || "—")
  }

  Process {
    id: hotkeyProc
    running: true
    command: [screenrecBin, "hotkeys"]
    stdout: StdioCollector {
      onStreamFinished: root.parseHotkeys(this.text)
    }
  }

  Process { id: setDirProc }
  Process { id: setFpsProc }
  Process { id: setFmtProc }

  // read the effective config from screenrec.conf so the UI matches reality
  Process {
    id: getProc
    running: true
    command: [screenrecBin, "get"]
    stdout: StdioCollector {
      onStreamFinished: root.parseGet(this.text)
    }
  }

  function parseGet(text) {
    try {
      var g = JSON.parse(text.trim())
      if (g.outDir) valueOutDir = g.outDir
      if (g.fps) valueFps = String(g.fps)
      if (g.format) valueFormat = g.format
    } catch (e) { }
  }

  function commitOutDir() {
    if (!pluginApi)
      return
    pluginApi.pluginSettings.outDir = valueOutDir
    pluginApi.saveSettings()
    setDirProc.command = [screenrecBin, "set", "out-dir", valueOutDir]
    setDirProc.running = true
  }

  function commitFps() {
    if (!pluginApi)
      return
    pluginApi.pluginSettings.fps = Number(valueFps)
    pluginApi.saveSettings()
    setFpsProc.command = [screenrecBin, "set", "fps", valueFps]
    setFpsProc.running = true
  }

  function commitFormat() {
    if (!pluginApi)
      return
    pluginApi.pluginSettings.format = valueFormat
    pluginApi.saveSettings()
    setFmtProc.command = [screenrecBin, "set", "format", valueFormat]
    setFmtProc.running = true
  }

  spacing: Style.marginL

  NTextInputButton {
    Layout.fillWidth: true
    label: "Output folder"
    description: "Where recorded videos are saved"
    placeholderText: "~/Downloads"
    text: valueOutDir
    buttonIcon: "folder-open"
    buttonTooltip: "Select folder"
    onInputEditingFinished: {
      valueOutDir = text
      commitOutDir()
    }
    onButtonClicked: dirPicker.openFilePicker()
  }

  NFilePicker {
    id: dirPicker
    selectionMode: "folders"
    title: "Output folder"
    initialPath: valueOutDir
    onAccepted: function (paths) {
      if (paths && paths.length > 0) {
        valueOutDir = paths[0]
        commitOutDir()
      }
    }
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Frame rate"
    description: "Frames per second. Higher = smoother but larger file."
    model: [
      { key: "10", name: "10 fps" },
      { key: "15", name: "15 fps" },
      { key: "24", name: "24 fps" },
      { key: "30", name: "30 fps" },
      { key: "60", name: "60 fps" }
    ]
    currentKey: valueFps
    onSelected: function (key) {
      valueFps = key
      commitFps()
    }
  }

  NComboBox {
    Layout.fillWidth: true
    label: "Video format"
    description: "MP4 (compatible), WebM (smaller, VP9), MKV, GIF (no audio)"
    model: [
      { key: "mp4", name: "MP4 (H.264)" },
      { key: "webm", name: "WebM (VP9)" },
      { key: "mkv", name: "MKV (H.264)" },
      { key: "gif", name: "GIF" }
    ]
    currentKey: valueFormat
    onSelected: function (key) {
      valueFormat = key
      commitFormat()
    }
  }

  NText {
    Layout.fillWidth: true
    text: "Hotkeys (from niri config): " + hotkeyInfo
    color: Color.mOnSurfaceVariant
    wrapMode: Text.Wrap
    Layout.topMargin: Style.marginM
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("ScreenRec", "Cannot save settings: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.outDir = valueOutDir
    pluginApi.pluginSettings.fps = Number(valueFps)
    pluginApi.pluginSettings.format = valueFormat
    pluginApi.saveSettings()

    setDirProc.command = [screenrecBin, "set", "out-dir", valueOutDir]
    setDirProc.running = true
    setFpsProc.command = [screenrecBin, "set", "fps", valueFps]
    setFpsProc.running = true
    setFmtProc.command = [screenrecBin, "set", "format", valueFormat]
    setFmtProc.running = true

    Logger.i("ScreenRec", "Settings saved")
  }
}
