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
    property string apiKey: providerSettings?.apiKey ?? ""

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
        if (root.apiKey === "") {
            root.failState("Set API key in settings");
            return;
        }
        usageProcess.command = [
            "curl", "-s", "--max-time", "20",
            "-H", "Authorization: Bearer " + root.apiKey,
            "-H", "Accept: application/json",
            "https://opencode.ai/console/api/go/status"
        ];
        usageProcess.running = true;
    }

    function failState(message) {
        root.usageStatusText = message;
        root.rateLimitPercent = -1;
        root.secondaryRateLimitPercent = -1;
        root.monthlyRateLimitPercent = -1;
        root.secondaryDailyRemaining = -1;
        root.monthlyDailyRemaining = -1;
        root.updateState();
    }

    function meterFraction(meter) {
        if (!meter)
            return -1;
        const limit = Number(meter.limitMicroCents);
        const used = Number(meter.usedMicroCents);
        if (!isFinite(limit) || limit <= 0 || !isFinite(used))
            return -1;
        return Math.max(0, used / limit);
    }

    function parseUsage(body) {
        let data = null;
        try {
            data = JSON.parse(body);
        } catch (e) {
            data = null;
        }

        if (!data || data._tag || !data.access || !data.access.meters) {
            root.failState("Usage unavailable (check API key)");
            return;
        }

        const meters = data.access.meters;
        const fiveHour = meters.fiveHour ?? null;
        const week = meters.week ?? null;
        const month = meters.month ?? null;
        const periodEnd = data.access?.endsAt ?? "";

        root.rateLimitPercent = meterFraction(fiveHour);
        root.rateLimitLabel = "5-hour Usage";
        root.rateLimitResetAt = formatResetLine(fiveHour?.resetsAt);

        root.secondaryRateLimitPercent = meterFraction(week);
        root.secondaryRateLimitLabel = "Weekly Usage";
        root.secondaryRateLimitResetAt = formatResetLine(week?.resetsAt);
        root.secondaryDailyRemaining = dailyRemaining(root.secondaryRateLimitPercent, week?.resetsAt);

        root.monthlyRateLimitPercent = meterFraction(month);
        root.monthlyRateLimitLabel = "Monthly Usage";
        root.monthlyRateLimitResetAt = formatResetLine(periodEnd);
        root.monthlyDailyRemaining = dailyRemaining(root.monthlyRateLimitPercent, periodEnd);

        root.tierLabel = data.cancelAtPeriodEnd ? "Cancelling" : "Active";

        const parts = [];
        if (fiveHour)
            parts.push("5h " + pctInt(root.rateLimitPercent));
        if (week)
            parts.push("week " + pctInt(root.secondaryRateLimitPercent));
        if (month)
            parts.push("month " + pctInt(root.monthlyRateLimitPercent));
        root.usageStatusText = parts.join(" \u00b7 ");
        root.updateState();
    }

    function pctInt(fraction) {
        if (!(fraction >= 0))
            return "0";
        return String(Math.round(fraction * 100));
    }

    function formatResetLine(isoTimestamp) {
        const text = formatResetTime(isoTimestamp);
        return text === "" ? "" : "Resets in " + text;
    }

    function dailyRemaining(fraction, isoTimestamp) {
        if (!(fraction >= 0) || !isoTimestamp)
            return -1;
        const reset = new Date(isoTimestamp).getTime();
        if (!isFinite(reset))
            return -1;
        const secs = (reset - Date.now()) / 1000;
        if (secs <= 0)
            return -1;
        return (1 - fraction) / Math.max(1, Math.ceil(secs / 86400));
    }

    function formatResetTime(isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const reset = new Date(isoTimestamp);
        if (isNaN(reset.getTime()))
            return "";
        const diffMs = reset.getTime() - Date.now();
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
