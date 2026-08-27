import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// Fullscreen, transparent region selector.
// Replaces slurp: renders immediately (no flicker) and needs no pointer
// event to paint its overlay. Emits the selected geometry as "WxH+X+Y"
// (the same format slurp outputs and grim -g accepts).
ShellWindow {
  id: win

  // set by the caller before showing
  property var targetScreen
  property string bin: ""

  screen: targetScreen
  visibility: Window.FullScreen
  color: "#00000000"
  flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
  visible: false

  signal finished(string geometry) // empty => cancelled

  // selection in window-local coordinates (== global once offset added)
  property bool dragging: false
  property real startX: 0
  property real startY: 0
  property real curX: 0
  property real curY: 0

  readonly property real selX: Math.min(startX, curX)
  readonly property real selY: Math.min(startY, curY)
  readonly property real selW: Math.abs(curX - startX)
  readonly property real selH: Math.abs(curY - startY)

  Process {
    id: startProc
  }

  Item {
    id: focusCatcher
    anchors.fill: parent
    focus: true
    Keys.onPressed: function (e) {
      if (e.key === Qt.Key_Escape) {
        win.visible = false
        win.finished("")
      }
    }
  }

  // faint full-screen dim so the user sees selection mode is active
  Rectangle {
    anchors.fill: parent
    color: "#30000000"
  }

  // strong dim around the selection (classic slurp look)
  Rectangle { x: 0; y: 0; width: win.width; height: selY; color: "#80000000"; visible: win.dragging }
  Rectangle { x: 0; y: selY + selH; width: win.width; height: win.height - selY - selH; color: "#80000000"; visible: win.dragging }
  Rectangle { x: 0; y: selY; width: selX; height: selH; color: "#80000000"; visible: win.dragging }
  Rectangle { x: selX + selW; y: selY; width: win.width - selX - selW; height: selH; color: "#80000000"; visible: win.dragging }

  // selection border
  Rectangle {
    x: selX; y: selY; width: selW; height: selH
    color: "#1f6feb22"
    border.color: "#1f6feb"
    border.width: 2
    visible: win.dragging
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 24
    text: "Drag to select · Click for full screen · Esc to cancel"
    color: "#ffffff"
    font.pointSize: 14
    visible: win.visible
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true

    onPressed: function (m) {
      win.dragging = true
      win.startX = m.x
      win.startY = m.y
      win.curX = m.x
      win.curY = m.y
    }
    onPositionChanged: function (m) {
      if (win.dragging) {
        win.curX = m.x
        win.curY = m.y
      }
    }
    onReleased: function (m) {
      win.dragging = false
      var w = Math.abs(win.curX - win.startX)
      var h = Math.abs(win.curY - win.startY)
      var geom
      if (w < 4 && h < 4) {
        // click without drag => whole screen of this output
        var r = win.targetScreen.rect
        geom = r.width + "x" + r.height + "+" + r.x + "+" + r.y
      } else {
        var off = win.targetScreen.rect
        var gx = Math.min(win.startX, win.curX) + off.x
        var gy = Math.min(win.startY, win.curY) + off.y
        geom = Math.round(w) + "x" + Math.round(h) + "+" + Math.round(gx) + "+" + Math.round(gy)
      }
      startProc.command = [win.bin, "start", geom]
      startProc.running = true
      win.visible = false
      win.finished(geom)
    }
  }
}
