import QtQuick
import Quickshell
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

    property int activeIndex: 0
    property var activeProvider: enabledProviders.length > 0 ? enabledProviders[Math.min(activeIndex, enabledProviders.length - 1)] : null

    property string barDisplayMode: pluginSettings?.barDisplayMode ?? "active"
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 30

    Timer {
        interval: root.barCycleIntervalSec * 1000
        running: root.barDisplayMode === "cycle" && root.enabledProviders.length > 1
        repeat: true
        onTriggered: {
            root.activeIndex = (root.activeIndex + 1) % root.enabledProviders.length;
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    onEnabledProvidersChanged: {
        if (enabledProviders.length === 0) {
            activeIndex = 0;
        } else if (activeIndex >= enabledProviders.length) {
            activeIndex = 0;
        }
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
}
