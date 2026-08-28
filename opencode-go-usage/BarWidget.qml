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

    property var mainInstance: pluginApi?.mainInstance
    property var activeProvider: mainInstance?.activeProvider

    function barPercent(p) {
        const mode = mainInstance?.barLimit ?? "5h";
        if (mode === "week")
            return p?.secondaryRateLimitPercent ?? -1;
        if (mode === "month")
            return p?.monthlyRateLimitPercent ?? -1;
        return p?.rateLimitPercent ?? -1;
    }

    function formatPct(fraction) {
        const v = fraction * 100;
        if (!isFinite(v))
            return "\u2014";
        const r = Math.round(v * 10) / 10;
        return (Number.isInteger(r) ? r.toString() : r.toFixed(1)) + "%";
    }

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    property string displayText: {
        if (!activeProvider)
            return "\u2014";
        const pct = barPercent(activeProvider);
        if (!(pct >= 0)) {
            const status = String(activeProvider.usageStatusText ?? "");
            if (status !== "")
                return status;
            return "\u2014";
        }
        return formatPct(pct);
    }

    property string tooltipText: {
        if (!activeProvider)
            return "Opencode Go Usage";
        const name = activeProvider.providerName;
        const mode = mainInstance?.barLimit ?? "5h";
        const label = mode === "week" ? (activeProvider.secondaryRateLimitLabel ?? "week")
                    : mode === "month" ? (activeProvider.monthlyRateLimitLabel ?? "month")
                    : (activeProvider.rateLimitLabel ?? "5h");
        const pct = barPercent(activeProvider);
        if (pct >= 0)
            return name + " \u2014 " + label + ": " + formatPct(pct);
        const status = activeProvider.usageStatusText ?? "";
        return name + (status !== "" ? " \u2014 " + status : "");
    }

    readonly property real contentWidth: isBarVertical ? capsuleHeight : content.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: isBarVertical ? content.implicitHeight + Style.marginM * 2 : capsuleHeight

    anchors.centerIn: parent
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    NPopupContextMenu {
        id: contextMenu
        screen: root.screen

        model: [
            {
                "label": "Refresh",
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": "Settings",
                "action": "settings",
                "icon": "settings"
            },
        ]

        onTriggered: (action, item) => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            if (action === "refresh") {
                mainInstance?.refresh();
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            }
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Item {
            id: content
            anchors.centerIn: parent
            implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth
            implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight

            RowLayout {
                id: rowLayout
                visible: !root.isBarVertical
                spacing: Style.marginS

                NIcon {
                    icon: root.activeProvider?.providerIcon ?? "ai"
                    pointSize: root.barFontSize
                    applyUiScale: false
                    color: Color.mPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                NText {
                    text: root.displayText
                    pointSize: root.barFontSize
                    applyUiScale: false
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            ColumnLayout {
                id: colLayout
                visible: root.isBarVertical
                spacing: Style.marginXS

                NIcon {
                    icon: root.activeProvider?.providerIcon ?? "ai"
                    pointSize: root.barFontSize
                    applyUiScale: false
                    color: Color.mPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                NText {
                    text: root.displayText
                    pointSize: root.barFontSize
                    applyUiScale: false
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                TooltipService.hide();
                pluginApi?.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.RightButton) {
                TooltipService.hide();
                PanelService.showContextMenu(contextMenu, root, root.screen);
            }
        }

        onEntered: {
            TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screenName));
        }

        onExited: {
            TooltipService.hide();
        }
    }
}
