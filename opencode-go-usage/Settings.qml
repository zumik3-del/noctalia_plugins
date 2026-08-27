import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    readonly property color sectionBackgroundColor: Color.mSurfaceVariant

    property var editSettings: JSON.parse(JSON.stringify(pluginApi?.pluginSettings ?? pluginApi?.manifest?.metadata?.defaultSettings ?? {}))

    function saveSettings() {
        pluginApi.pluginSettings = JSON.parse(JSON.stringify(root.editSettings));
        pluginApi.saveSettings();
    }

    spacing: Style.marginL

    NText {
        text: "Opencode Go Usage Settings"
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        color: root.sectionBackgroundColor
        radius: Style.radiusS
        implicitHeight: generalColumn.implicitHeight + Style.marginXL

        ColumnLayout {
            id: generalColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginM

            NText {
                text: "General"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: Color.mPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Bar display mode"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }
                NText {
                    text: "Show active provider or cycle between enabled providers"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                NComboBox {
                    Layout.fillWidth: true
                    model: [
                        {
                            key: "active",
                            name: "Active provider"
                        },
                        {
                            key: "cycle",
                            name: "Cycle providers"
                        }
                    ]
                    currentKey: editSettings?.barDisplayMode ?? "active"
                    onSelected: key => {
                        editSettings.barDisplayMode = key;
                    }
                }
            }

            ColumnLayout {
                visible: (editSettings?.barDisplayMode ?? "active") === "cycle"
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Cycle interval (seconds)"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }

                NSpinBox {
                    from: 2
                    to: 60
                    value: editSettings?.barCycleIntervalSec ?? 5
                    stepSize: 1
                    onValueChanged: {
                        editSettings.barCycleIntervalSec = value;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Refresh interval (seconds)"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }
                NText {
                    text: "Fallback polling interval when file watch misses changes"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                NSpinBox {
                    from: 5
                    to: 300
                    value: editSettings?.refreshIntervalSec ?? 30
                    stepSize: 5
                    onValueChanged: {
                        editSettings.refreshIntervalSec = value;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        color: root.sectionBackgroundColor
        radius: Style.radiusS
        implicitHeight: providersColumn.implicitHeight + Style.marginXL

        ColumnLayout {
            id: providersColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginM

            NText {
                text: "Providers"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: Color.mPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    NToggle {
                        checked: editSettings?.providers?.opencodeGo?.enabled ?? false
                        onToggled: value => {
                            if (!editSettings.providers)
                                editSettings.providers = {};
                            if (!editSettings.providers.opencodeGo)
                                editSettings.providers.opencodeGo = {};
                            editSettings.providers.opencodeGo.enabled = value;
                            editSettingsChanged();
                        }
                    }
                    NText {
                        text: "Opencode Go"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                    NText {
                        text: "opencode.ai console"
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                    }
                }

                NTextInput {
                    visible: editSettings?.providers?.opencodeGo?.enabled ?? false
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginXL
                    placeholderText: "Workspace ID, e.g. wrk_XXXXXXXXXXXXXXXXXXXXXXXX"
                    text: editSettings?.providers?.opencodeGo?.workspaceId ?? ""

                    onTextChanged: {
                        if (!editSettings.providers)
                            editSettings.providers = {};
                        if (!editSettings.providers.opencodeGo)
                            editSettings.providers.opencodeGo = {};
                        editSettings.providers.opencodeGo.workspaceId = text;
                    }
                }

                NTextInput {
                    visible: editSettings?.providers?.opencodeGo?.enabled ?? false
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginXL
                    placeholderText: "Session cookie (Cookie header value, auth=...)"
                    text: editSettings?.providers?.opencodeGo?.cookie ?? ""

                    onTextChanged: {
                        if (!editSettings.providers)
                            editSettings.providers = {};
                        if (!editSettings.providers.opencodeGo)
                            editSettings.providers.opencodeGo = {};
                        editSettings.providers.opencodeGo.cookie = text;
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Item {
            Layout.fillWidth: true
        }

        NButton {
            text: "Reset"
            onClicked: {
                root.editSettings = JSON.parse(JSON.stringify(pluginApi?.manifest?.metadata?.defaultSettings ?? {}));
            }
        }
    }
}
