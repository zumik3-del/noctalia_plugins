import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root
    visible: false

    property string providerId: "opencodeGo"
    property string providerName: "Opencode Go"
    property string providerIcon: "ai"
    property bool enabled: false
    property bool ready: false

    property real rateLimitPercent: -1
    property string rateLimitLabel: ""
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: ""
    property string secondaryRateLimitResetAt: ""
    property real monthlyRateLimitPercent: -1
    property string monthlyRateLimitLabel: ""
    property string monthlyRateLimitResetAt: ""

    property string tierLabel: ""
    property string usageStatusText: ""

    property var providerSettings: ({})
    property string workspaceId: providerSettings?.workspaceId ?? ""
    property string sessionCookie: providerSettings?.cookie ?? ""

    onEnabledChanged: {
        if (enabled)
            refresh();
    }

    function updateState() {
        root.tierLabel = root.rateLimitPercent >= 0 ? "Active" : "";
        root.ready = root.rateLimitPercent >= 0 || root.usageStatusText !== "";
    }

    Process {
        id: usageProcess
        running: false
        stdout: StdioCollector {
            id: usageOutput
            onStreamFinished: root.parseUsage(text)
        }
        onExited: (code, status) => {
            if (code !== 0)
                Logger.e("opencode-go-usage", "usage curl failed (exit " + code + ")");
        }
    }

    function refresh() {
        fetchUsage();
    }

    function fetchUsage() {
        if (!root.sessionCookie || !root.workspaceId) {
            root.usageStatusText = "Set workspace ID + cookie in settings";
            root.rateLimitPercent = -1;
            root.secondaryRateLimitPercent = -1;
            root.monthlyRateLimitPercent = -1;
            root.updateState();
            return;
        }
        usageProcess.command = [
            "curl", "-s", "--max-time", "20",
            "-H", "Cookie: auth=" + root.sessionCookie,
            "https://opencode.ai/workspace/" + root.workspaceId + "/go"
        ];
        usageProcess.running = true;
    }

    function parseUsage(body) {
        function grab(key) {
            const m = body.match(new RegExp(key + ":\\$R\\[\\d+\\]=\\{([^}]*)\\}"));
            if (!m)
                return null;
            const obj = {};
            const pairs = m[1].split(",");
            for (let i = 0; i < pairs.length; i++) {
                const colon = pairs[i].indexOf(":");
                if (colon < 0)
                    continue;
                const k = pairs[i].slice(0, colon).trim();
                let v = pairs[i].slice(colon + 1).trim();
                if (v === "null")
                    obj[k] = null;
                else if (v[0] === '"')
                    obj[k] = v.slice(1, -1);
                else
                    obj[k] = parseFloat(v);
            }
            return obj;
        }
        const rolling = grab("rollingUsage");
        const weekly = grab("weeklyUsage");
        const monthly = grab("monthlyUsage");
        if (!rolling && !weekly && !monthly) {
            root.usageStatusText = "No usage data in page (not authed?)";
            root.rateLimitPercent = -1;
            root.secondaryRateLimitPercent = -1;
            root.monthlyRateLimitPercent = -1;
            root.updateState();
            return;
        }
        if (rolling) {
            root.rateLimitPercent = (rolling.usagePercent ?? 0) / 100;
            root.rateLimitLabel = "5-hour Usage";
            root.rateLimitResetAt = rolling.resetInSec != null
                ? root.formatResetTime(new Date(Date.now() + rolling.resetInSec * 1000).toISOString())
                : "";
        } else {
            root.rateLimitPercent = -1;
        }
        if (weekly) {
            root.secondaryRateLimitPercent = (weekly.usagePercent ?? 0) / 100;
            root.secondaryRateLimitLabel = "Weekly Usage";
            root.secondaryRateLimitResetAt = weekly.resetInSec != null
                ? root.formatResetTime(new Date(Date.now() + weekly.resetInSec * 1000).toISOString())
                : "";
        } else {
            root.secondaryRateLimitPercent = -1;
        }
        if (monthly) {
            root.monthlyRateLimitPercent = (monthly.usagePercent ?? 0) / 100;
            root.monthlyRateLimitLabel = "Monthly Usage";
            root.monthlyRateLimitResetAt = monthly.resetInSec != null
                ? root.formatResetTime(new Date(Date.now() + monthly.resetInSec * 1000).toISOString())
                : "";
        } else {
            root.monthlyRateLimitPercent = -1;
        }
        const parts = [];
        if (rolling)
            parts.push("5h " + rolling.usagePercent + "%");
        if (weekly)
            parts.push("week " + weekly.usagePercent + "%");
        if (monthly)
            parts.push("month " + monthly.usagePercent + "%");
        root.usageStatusText = parts.join(" · ");
        root.updateState();
    }

    function formatResetTime(isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const reset = new Date(isoTimestamp);
        const now = new Date();
        const diffMs = reset.getTime() - now.getTime();
        if (diffMs <= 0)
            return "now";
        const hours = Math.floor(diffMs / 3600000);
        const mins = Math.floor((diffMs % 3600000) / 60000);
        if (hours > 24)
            return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + mins + "m";
        return mins + "m";
    }
}
