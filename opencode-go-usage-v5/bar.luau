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

local usage = noctalia.state.get("usage") or {}
local isVertical = false

local function render()
	local mode = noctalia.getConfig("bar_limit") or "5h"

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

	barWidget.setTooltip(tooltipText)

	if isVertical then
		barWidget.render(ui.column({ align = "center" }, {
			ui.glyph({ name = "ai", color = "primary" }),
			ui.label({ text = displayText, fontWeight = "semibold", color = "on_surface" }),
		}))
	else
		barWidget.render(ui.row({ gap = 6, align = "center" }, {
			ui.glyph({ name = "ai", color = "primary" }),
			ui.label({ text = displayText, fontWeight = "semibold", color = "on_surface" }),
		}))
	end
end

noctalia.state.watch("usage", function(value)
	usage = value or {}
	render()
end)

function update()
	isVertical = barWidget.isVertical()
	render()
end

function onClick()
	noctalia.togglePanel("zumik3-del/opencode-go-usage:panel")
end

function onIpc(event: string, payload: any)
	if event == "refresh" then
		noctalia.state.set("cmd", "refresh")
	end
end
