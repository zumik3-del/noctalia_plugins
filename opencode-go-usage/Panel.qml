import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import "formatUtils.js" as FormatUtils

Item {
    id: root

    property var pluginApi: null
    property var mainInstance: pluginApi?.mainInstance
    readonly property color sectionBackgroundColor: Color.mSurfaceVariant
    readonly property color usageWarnColor: Qt.alpha(Color.mError, 0.72)

    function limitColor(fraction) {
        if (fraction >= 0.9)
            return Color.mError;
        if (fraction >= 0.7)
            return root.usageWarnColor;
        return Color.mPrimary;
    }

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: contentColumn.implicitHeight + Style.marginL * 2

    anchors.fill: parent

    property int selectedTabIndex: 0
    property var selectedProvider: {
        const ep = mainInstance?.enabledProviders ?? [];
        if (ep.length === 0)
            return null;
        return ep[Math.min(selectedTabIndex, ep.length - 1)];
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: 0

            NText {
                visible: !root.selectedProvider
                text: "Opencode Go is not enabled. Enable it in Settings."
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: Style.marginXL
            }

            RowLayout {
                visible: !!root.selectedProvider
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: "Usage limits"
                    pointSize: Style.fontSizeXL
                    font.weight: Style.fontWeightBold
                    color: Color.mOnSurface
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: (root.selectedProvider?.tierLabel ?? "") !== ""
                    color: Qt.alpha(Color.mPrimary, 0.15)
                    radius: Style.radiusXS
                    implicitWidth: tierText.implicitWidth + Style.marginL
                    implicitHeight: tierText.implicitHeight + Style.marginS

                    NText {
                        id: tierText
                        anchors.centerIn: parent
                        text: root.selectedProvider?.tierLabel ?? ""
                        pointSize: Style.fontSizeS
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mPrimary
                    }
                }
            }

            Rectangle {
                visible: !!root.selectedProvider && (root.selectedProvider?.rateLimitPercent ?? -1) < 0 && (root.selectedProvider?.usageStatusText ?? "") !== ""
                Layout.fillWidth: true
                color: Qt.alpha(Color.mError, 0.12)
                radius: Style.radiusS
                implicitHeight: statusColumn.implicitHeight + Style.marginXL

                ColumnLayout {
                    id: statusColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Style.marginL
                    }
                    spacing: Style.marginXS

                    NText {
                        text: root.selectedProvider?.usageStatusText ?? ""
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mError
                    }
                }
            }

            ColumnLayout {
                id: limitsColumn
                visible: (root.selectedProvider?.rateLimitPercent ?? -1) >= 0
                Layout.fillWidth: true
                spacing: Style.marginM

                Repeater {
                    model: [
                        { pct: "rateLimitPercent", label: "rateLimitLabel", reset: "rateLimitResetAt", daily: "" },
                        { pct: "secondaryRateLimitPercent", label: "secondaryRateLimitLabel", reset: "secondaryRateLimitResetAt", daily: "secondaryDailyRemaining" },
                        { pct: "monthlyRateLimitPercent", label: "monthlyRateLimitLabel", reset: "monthlyRateLimitResetAt", daily: "monthlyDailyRemaining" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        color: root.sectionBackgroundColor
                        radius: Style.radiusS
                        implicitHeight: cardInner.implicitHeight + Style.marginXL

                        ColumnLayout {
                            id: cardInner
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Style.marginL
                            }
                            spacing: Style.marginXS

                            RowLayout {
                                Layout.fillWidth: true
                                NText {
                                    text: root.selectedProvider?.[modelData.label] ?? ""
                                    pointSize: Style.fontSizeS
                                    color: Color.mOnSurfaceVariant
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                NText {
                                    text: {
                                        const u = root.selectedProvider?.[modelData.pct] ?? -1;
                                        if (u < 0)
                                            return "\u2014";
                                        return FormatUtils.formatPct(u);
                                    }
                                    pointSize: Style.fontSizeS
                                    font.weight: Style.fontWeightBold
                                    color: root.limitColor(root.selectedProvider?.[modelData.pct] ?? 0)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                color: Qt.alpha(Color.mOutline, 0.2)
                                radius: Style.radiusXXS

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    radius: Style.radiusXXS
                                    color: root.limitColor(root.selectedProvider?.[modelData.pct] ?? 0)
                                    width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.[modelData.pct] ?? 0))

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                visible: (root.selectedProvider?.[modelData.reset] ?? "") !== "" || (modelData.daily !== "" && (root.selectedProvider?.[modelData.daily] ?? -1) >= -1)
                                Layout.fillWidth: true

                                NText {
                                    text: "Resets in " + (root.selectedProvider?.[modelData.reset] ?? "")
                                    visible: (root.selectedProvider?.[modelData.reset] ?? "") !== ""
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }

                                Item { Layout.fillWidth: true }

                                NText {
                                    visible: modelData.daily !== "" && (root.selectedProvider?.[modelData.daily] ?? -1) >= -1
                                    text: {
                                        const d = root.selectedProvider?.[modelData.daily] ?? -1;
                                        if (d < -1)
                                            return "";
                                        return FormatUtils.formatDaily(d);
                                    }
                                    pointSize: Style.fontSizeXS
                                    font.weight: Style.fontWeightSemiBold
                                    color: (root.selectedProvider?.[modelData.daily] ?? 0) >= 0 ? Color.mPrimary : Color.mError
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
