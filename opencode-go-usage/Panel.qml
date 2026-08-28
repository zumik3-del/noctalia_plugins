import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property var mainInstance: pluginApi?.mainInstance
    readonly property color sectionBackgroundColor: Color.mSurfaceVariant
    readonly property color usageWarnColor: Qt.alpha(Color.mError, 0.72)

    function formatPct(fraction) {
        const v = fraction * 100;
        if (!isFinite(v))
            return "\u2014";
        const r = Math.round(v * 10) / 10;
        return (Number.isInteger(r) ? r.toString() : r.toFixed(1)) + "%";
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

                NIcon {
                    icon: root.selectedProvider?.providerIcon ?? "ai"
                    pointSize: Style.fontSizeXXXL
                    color: Color.mPrimary
                }

                NText {
                    text: (root.selectedProvider?.providerName ?? "") + " Usage"
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
                visible: !!root.selectedProvider
                Layout.fillWidth: true
                height: 1
                color: Color.mOutline
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

            Rectangle {
                visible: (root.selectedProvider?.rateLimitPercent ?? -1) >= 0
                Layout.fillWidth: true
                color: root.sectionBackgroundColor
                radius: Style.radiusS
                implicitHeight: rateLimitColumn.implicitHeight + Style.marginXL

                ColumnLayout {
                    id: rateLimitColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Style.marginL
                    }
                    spacing: Style.marginM

                    NText {
                        text: "Usage Limits"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        RowLayout {
                            Layout.fillWidth: true
                            NText {
                                text: root.selectedProvider?.rateLimitLabel ?? ""
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            NText {
                                text: {
                                    const u = root.selectedProvider?.rateLimitPercent ?? -1;
                                    if (u < 0)
                                        return "\u2014";
                                    return formatPct(u);
                                }
                                pointSize: Style.fontSizeS
                                font.weight: Style.fontWeightBold
                                color: {
                                    const u = root.selectedProvider?.rateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mOnSurface;
                                }
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
                                color: {
                                    const u = root.selectedProvider?.rateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mPrimary;
                                }
                                width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.rateLimitPercent ?? 0))

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Style.animationNormal
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        NText {
                            visible: (root.selectedProvider?.rateLimitResetAt ?? "") !== ""
                            text: "Resets in " + (root.selectedProvider?.rateLimitResetAt ?? "")
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    ColumnLayout {
                        visible: (root.selectedProvider?.secondaryRateLimitPercent ?? -1) >= 0
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        RowLayout {
                            Layout.fillWidth: true
                            NText {
                                text: root.selectedProvider?.secondaryRateLimitLabel ?? ""
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            NText {
                                text: {
                                    const u = root.selectedProvider?.secondaryRateLimitPercent ?? -1;
                                    if (u < 0)
                                        return "\u2014";
                                    return formatPct(u);
                                }
                                pointSize: Style.fontSizeS
                                font.weight: Style.fontWeightBold
                                color: {
                                    const u = root.selectedProvider?.secondaryRateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mOnSurface;
                                }
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
                                color: {
                                    const u = root.selectedProvider?.secondaryRateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mPrimary;
                                }
                                width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.secondaryRateLimitPercent ?? 0))

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Style.animationNormal
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        NText {
                            visible: (root.selectedProvider?.secondaryRateLimitResetAt ?? "") !== ""
                            text: "Resets in " + (root.selectedProvider?.secondaryRateLimitResetAt ?? "")
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    ColumnLayout {
                        visible: (root.selectedProvider?.monthlyRateLimitPercent ?? -1) >= 0
                        Layout.fillWidth: true
                        spacing: Style.marginXS

                        RowLayout {
                            Layout.fillWidth: true
                            NText {
                                text: root.selectedProvider?.monthlyRateLimitLabel ?? ""
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            NText {
                                text: {
                                    const u = root.selectedProvider?.monthlyRateLimitPercent ?? -1;
                                    if (u < 0)
                                        return "\u2014";
                                    return formatPct(u);
                                }
                                pointSize: Style.fontSizeS
                                font.weight: Style.fontWeightBold
                                color: {
                                    const u = root.selectedProvider?.monthlyRateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mOnSurface;
                                }
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
                                color: {
                                    const u = root.selectedProvider?.monthlyRateLimitPercent ?? 0;
                                    if (u >= 0.9)
                                        return Color.mError;
                                    if (u >= 0.7)
                                        return root.usageWarnColor;
                                    return Color.mPrimary;
                                }
                                width: parent.width * Math.min(1.0, Math.max(0, root.selectedProvider?.monthlyRateLimitPercent ?? 0))

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Style.animationNormal
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        NText {
                            visible: (root.selectedProvider?.monthlyRateLimitResetAt ?? "") !== ""
                            text: "Resets in " + (root.selectedProvider?.monthlyRateLimitResetAt ?? "")
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
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
