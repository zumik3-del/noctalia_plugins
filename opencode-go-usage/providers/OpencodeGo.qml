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

    property real secondaryDailyRemaining: -1
    property real monthlyDailyRemaining: -1

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
            "https://opencode.ai/console/" + root.workspaceId + "/go"
        ];
        usageProcess.running = true;
    }

    function parseUsage(body) {
        function extractUsage(label) {
            const idx = body.indexOf(label);
            if (idx < 0)
                return null;
            const section = body.substring(idx, idx + 800);
            const pm = section.match(/aria-valuenow="(\d+)"/);
            if (!pm)
                return null;
            const pct = parseInt(pm[1], 10);
            const tm = section.match(/title="([^"]+)"/);
            const resetText = tm ? tm[1] : "";
            return { percent: pct, resetText: resetText };
        }

        const rolling = extractUsage("Rolling usage");
        const weekly = extractUsage("Weekly usage");
        const monthly = extractUsage("Monthly usage");

        if (!rolling && !weekly && !monthly) {
            root.usageStatusText = "No usage data in page (not authed?)";
            root.rateLimitPercent = -1;
            root.secondaryRateLimitPercent = -1;
            root.monthlyRateLimitPercent = -1;
            root.updateState();
            return;
        }

        if (rolling) {
            root.rateLimitPercent = rolling.percent / 100;
            root.rateLimitLabel = "5-hour Usage";
            root.rateLimitResetAt = rolling.resetText;
        } else {
            root.rateLimitPercent = -1;
        }

        if (weekly) {
            root.secondaryRateLimitPercent = weekly.percent / 100;
            root.secondaryRateLimitLabel = "Weekly Usage";
            root.secondaryRateLimitResetAt = weekly.resetText;
            const rds = root.parseResetDuration(weekly.resetText);
            root.secondaryDailyRemaining = rds >= 0
                ? (1 - root.secondaryRateLimitPercent) / Math.max(1, Math.ceil(rds / 86400))
                : -1;
        } else {
            root.secondaryRateLimitPercent = -1;
            root.secondaryDailyRemaining = -1;
        }

        if (monthly) {
            root.monthlyRateLimitPercent = monthly.percent / 100;
            root.monthlyRateLimitLabel = "Monthly Usage";
            root.monthlyRateLimitResetAt = monthly.resetText;
            const rds = root.parseResetDuration(monthly.resetText);
            root.monthlyDailyRemaining = rds >= 0
                ? (1 - root.monthlyRateLimitPercent) / Math.max(1, Math.ceil(rds / 86400))
                : -1;
        } else {
            root.monthlyRateLimitPercent = -1;
            root.monthlyDailyRemaining = -1;
        }

        const parts = [];
        if (rolling)
            parts.push("5h " + rolling.percent + "%");
        if (weekly)
            parts.push("week " + weekly.percent + "%");
        if (monthly)
            parts.push("month " + monthly.percent + "%");
        root.usageStatusText = parts.join(" \u00b7 ");
        root.updateState();
    }

    function parseResetDuration(text) {
        if (!text)
            return -1;
        let total = 0;
        const dm = text.match(/(\d+)\s*d/);
        const hm = text.match(/(\d+)\s*h/);
        const mm = text.match(/(\d+)\s*m/);
        if (dm) total += parseInt(dm[1], 10) * 86400;
        if (hm) total += parseInt(hm[1], 10) * 3600;
        if (mm) total += parseInt(mm[1], 10) * 60;
        return total > 0 ? total : -1;
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
