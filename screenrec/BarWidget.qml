import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property string screenrecBin: (pluginApi ? pluginApi.pluginDir : "") + "/screenrec"

  property string _icon: "camera-video"
  property string _text: ""
  readonly property bool recording: _text !== ""

  // pulsing effect while recording (README: "pulsing red REC m:ss")
  property real pulseOpacity: 1
  SequentialAnimation {
    id: pulseAnim
    running: root.recording
    loops: Animation.Infinite
    NumberAnimation { target: root; property: "pulseOpacity"; from: 1.0; to: 0.35; duration: 700; easing.type: Easing.InOutSine }
    NumberAnimation { target: root; property: "pulseOpacity"; from: 0.35; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
  }

  readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight
  implicitWidth: isVertical ? capsuleHeight : contentWidth
  implicitHeight: isVertical ? contentWidth : capsuleHeight

  function run(sub) {
    runProc.command = [screenrecBin, sub]
    runProc.running = true
  }

  function parseOutput(text) {
    try {
      var p = JSON.parse(text.trim())
      _icon = p.icon || "camera-video"
      _text = p.text || ""
    } catch (e) { }
  }

  Process {
    id: statusProc
    running: false
    command: [screenrecBin, "status"]
    stdout: StdioCollector {
      onStreamFinished: root.parseOutput(this.text)
    }
  }

  Timer {
    id: pollTimer
    interval: 500
    repeat: true
    running: true
    onTriggered: {
      if (!statusProc.running)
        statusProc.running = true
    }
  }

  Process {
    id: runProc
  }

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Row {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: root._icon
        color: root.recording ? Color.mError : Color.mOnSurface
        opacity: root.recording ? root.pulseOpacity : 1
        applyUiScale: false
      }

      NText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root._text !== ""
        text: root._text
        color: root.recording ? Color.mError : Color.mOnSurface
        opacity: root.recording ? root.pulseOpacity : 1
        pointSize: root.barFontSize
        applyUiScale: false
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function (m) {
      if (m.button === Qt.LeftButton) {
        if (root.recording) {
          root.run("stop")
        } else {
          // start recording; the script falls back to slurp for region
          // selection (with a ydotool nudge to force an immediate repaint
          // on niri, avoiding the flicker)
          root.run("start")
        }
      } else if (m.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        "label": "Settings",
        "action": "widget-settings",
        "icon": "settings"
      }
    ]
    onTriggered: action => {
                   contextMenu.close()
                   PanelService.closeContextMenu(screen)
                   if (action === "widget-settings" && pluginApi) {
                     BarService.openPluginSettings(screen, pluginApi.manifest)
                   }
                 }
  }
}
