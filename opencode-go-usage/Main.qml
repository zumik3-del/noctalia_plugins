import QtQuick
import Quickshell
import Quickshell.Io
import "providers" as Providers

Item {
    id: root
    visible: false

    property var pluginApi: null
    property var pluginSettings: pluginApi?.pluginSettings ?? ({})

    Providers.OpencodeGo {
        id: opencodeGoProvider
        enabled: root.providerEnabled("opencodeGo")
        providerSettings: root.pluginSettings?.providers?.opencodeGo ?? ({})
    }

    property var providers: [opencodeGoProvider]

    property var enabledProviders: {
        const result = [];
        if (opencodeGoProvider.enabled)
            result.push(opencodeGoProvider);
        return result;
    }

    property var activeProvider: enabledProviders.length > 0 ? enabledProviders[0] : null

    property string barLimit: pluginSettings?.barLimit ?? "5h"
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 1800

    function applySettings() {
        root.barLimit = pluginApi?.pluginSettings?.barLimit ?? "5h";
        root.refreshIntervalSec = pluginApi?.pluginSettings?.refreshIntervalSec ?? 1800;
        refreshTimer.interval = root.refreshIntervalSec * 1000;
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll();
    }

    function refreshAll() {
        for (const p of providers) {
            if (p.enabled)
                p.refresh();
        }
    }

    function secureSettingsFile() {
        if (!pluginApi?.pluginDir)
            return;
        secureProcess.command = ["chmod", "600", pluginApi.pluginDir + "/settings.json"];
        secureProcess.running = true;
    }

    Process {
        id: secureProcess
        running: false
        onExited: (code, status) => {
            if (code !== 0)
                Logger.e("opencode-go-usage", "failed to secure settings.json (exit " + code + ")");
        }
    }

    Component.onCompleted: root.secureSettingsFile()
}
