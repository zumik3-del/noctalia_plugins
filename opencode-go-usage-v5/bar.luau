--!nonstrict

local function formatPct(fraction: number): string
	local v = fraction * 100
	if not isfinite(v) then
		return "—"
	end
	local r = math.floor(v * 10 + 0.5) / 10
	if r == math.floor(r) then
		return string.format("%d%%", r)
	end
	return string.format("%.1f%%", r)
end

local function barPercent(usage: any, mode: string): number
	if mode == "week" then
		return usage.secondaryRateLimitPercent or -1
	elseif mode == "month" then
		return usage.monthlyRateLimitPercent or -1
	end
	return usage.rateLimitPercent or -1
end

local function limitLabel(usage: any, mode: string): string
	if mode == "week" then
		return usage.secondaryRateLimitLabel or "week"
	elseif mode == "month" then
		return usage.monthlyRateLimitLabel or "month"
	end
	return usage.rateLimitLabel or "5h"
end

function update()
	local usage = noctalia.state.get("usage") or {}
	local mode = noctalia.getSetting("zumik3-del/opencode-go-usage/bar.bar_limit") or "5h"

	local pct = barPercent(usage, mode)
	local displayText
	if pct >= 0 then
		displayText = formatPct(pct)
	else
		local status = usage.usageStatusText or ""
		displayText = status ~= "" and status or "—"
	end

	local tooltipText
	if usage and next(usage) ~= nil then
		local label = limitLabel(usage, mode)
		if pct >= 0 then
			tooltipText = "Opencode Go — " .. label .. ": " .. formatPct(pct)
		else
			local status = usage.usageStatusText or ""
			tooltipText = status ~= "" and ("Opencode Go — " .. status) or "Opencode Go Usage"
		end
	else
		tooltipText = "Opencode Go Usage"
	end

	barWidget.render({
		ui.box {
			tooltip = tooltipText,
			ui.row {
				ui.icon { glyph = "ai", color = "primary" },
				ui.text { text = displayText, weight = "semibold" },
			},
		},
	})
end

function onClick()
	noctalia.msg("panel-toggle", "zumik3-del/opencode-go-usage:panel")
end

function onContextMenu()
	return {
		{ label = "Refresh", action = "refresh", glyph = "refresh" },
		{ label = "Settings", action = "settings", glyph = "settings" },
	}
end

function onIpc(op: string, payload: any)
	if op == "refresh" then
		noctalia.msg("plugin-ipc", "zumik3-del/opencode-go-usage:usage", "refresh")
	end
end
