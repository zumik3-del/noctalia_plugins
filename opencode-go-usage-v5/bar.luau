--!nonstrict
-- Bar widget entry for the Opencode Go usage capsule.
--
--   barWidget.render(tree)      declarative ui.* tree (replaces the default row)
--   barWidget.isVertical()      a row in a horizontal bar, a column in a side bar
--   barWidget.setTooltip(text)  hover text
--   noctalia.state.watch(...)   re-render when the service publishes new usage
--   noctalia.togglePanel(id)    left click opens the details panel
--
-- The widget owns no polling logic: it only reflects the shared "usage" state.

local PLUGIN_ID = "zumik3-del/opencode-go-usage-v5"
local GLYPH = "brand-openai"

local usage = noctalia.state.get("usage")
local isVertical = false

local function formatPct(fraction)
	if type(fraction) ~= "number" or fraction < 0 then
		return nil
	end
	local v = fraction * 100
	if v > 999 then
		v = 999
	end
	local r = math.floor(v * 10 + 0.5) / 10
	if r == math.floor(r) then
		return string.format("%d%%", r)
	end
	return string.format("%.1f%%", r)
end

-- The bar shows one limit, chosen by the widget's own "bar_limit" setting.
local function selectedCard()
	if type(usage) ~= "table" then
		return nil
	end
	local mode = noctalia.getConfig("bar_limit")
	if mode == "week" then
		return usage.week
	elseif mode == "month" then
		return usage.month
	end
	return usage.fiveHour
end

local function render()
	local card = selectedCard()
	local text, tooltip

	if not usage then
		text = "\u{2014}"
		tooltip = "Opencode Go Usage"
	elseif not usage.ok then
		text = "\u{2014}"
		tooltip = "Opencode Go \u{2014} " .. (usage.message or "unavailable")
	else
		local pct = card and formatPct(card.percent)
		if pct then
			text = pct
			tooltip = string.format("Opencode Go \u{2014} %s: %s", card.name, pct)
		else
			-- The selected meter is absent from the payload: fall back to the
			-- compact all-limits summary the service composes.
			local summary = type(usage.message) == "string" and usage.message or ""
			text = summary ~= "" and summary or "\u{2014}"
			tooltip = "Opencode Go \u{2014} " .. text
		end
		if usage.tier == "Cancelling" then
			tooltip = tooltip .. " (cancelling)"
		end
	end

	barWidget.setTooltip(tooltip)

	local container = isVertical and ui.column or ui.row
	barWidget.render(container({ gap = 6, align = "center" }, {
		ui.glyph({ name = GLYPH, color = "primary" }),
		ui.label({ text = text, fontWeight = "semibold" }),
	}))
end

noctalia.state.watch("usage", function(value)
	usage = value
	render()
end)

function update()
	isVertical = barWidget.isVertical()
	render()
end

function onClick()
	noctalia.togglePanel(PLUGIN_ID .. ":panel")
end

-- Draw once immediately: at startup the service has usually not published yet,
// and update() only fires on the first tick.
render()
