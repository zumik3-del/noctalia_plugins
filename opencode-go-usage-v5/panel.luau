--!nonstrict
-- Details panel entry: 5-hour / weekly / monthly limit cards with progress bars,
-- reset countdowns and per-period daily headroom.
--
--   panel.render(tree)                 declarative ui.* tree
--   noctalia.state.watch("usage", cb)   re-render when the service publishes
--   noctalia.state.set("usage.cmd", 1)  ask the service to refetch now
--
-- Children lists are built with table.insert rather than `if ... else nil`
-- expressions: a nil in the middle of a constructor leaves a hole, and the host
-- walks the children array positionally.

local WARNING = "#F5A623"

local usage = noctalia.state.get("usage")
local busy = false

local function formatPct(fraction)
	if type(fraction) ~= "number" or fraction < 0 then
		return "\u{2014}"
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

-- Signed average headroom per remaining day, e.g. "+12.3%".
local function formatDaily(fraction)
	if type(fraction) ~= "number" or fraction < 0 then
		return nil
	end
	local v = fraction * 100
	local r = math.floor(v * 10 + 0.5) / 10
	local sign = v > 0 and "+" or ""
	if r == math.floor(r) then
		return string.format("%s%d%%", sign, r)
	end
	return string.format("%s%.1f%%", sign, r)
end

local function limitColor(fraction)
	if fraction >= 0.97 or fraction > 1.0 then
		return "error"
	elseif fraction >= 0.70 then
		return WARNING
	end
	return "primary"
end

local function limitCard(card)
	local children = {}

	table.insert(children, ui.row({ justify = "space_between", align = "center" }, {
		ui.label({ text = card.name, fontSize = 12, color = "on_surface_variant" }),
		ui.label({ text = formatPct(card.percent), fontSize = 12, fontWeight = "bold", color = limitColor(card.percent) }),
	}))

	table.insert(children, ui.progress({
		progress = math.min(1, math.max(0, card.percent)),
		fill = limitColor(card.percent),
		track = "outline/0.2",
		height = 8,
		radius = 4,
	}))

	local footer = {}
	if card.reset and card.reset ~= "" then
		table.insert(footer, ui.label({ text = card.reset, fontSize = 11, color = "on_surface_variant" }))
	end
	table.insert(footer, ui.spacer({ flexGrow = 1 }))
	local daily = formatDaily(card.daily)
	if daily then
		table.insert(footer, ui.label({ text = daily, fontSize = 11, fontWeight = "semibold", color = "primary" }))
	end
	table.insert(children, ui.row({ justify = "space_between", align = "center" }, footer))

	return ui.column({ gap = 8, padding = 12, fill = "surface_variant/0.4", radius = 8 }, children)
end

local function headerRow()
	local children = {
		ui.label({ text = "Opencode Go", fontSize = 16, fontWeight = "bold", color = "on_surface" }),
	}
	table.insert(children, ui.spacer({ flexGrow = 1 }))
	if usage and usage.tier and usage.tier ~= "" then
		table.insert(children, ui.label({
			text = usage.tier,
			fontSize = 12,
			fontWeight = "semibold",
			color = usage.tier == "Cancelling" and "error" or "primary",
		}))
	end
	return ui.row({ align = "center", gap = 8 }, children)
end

local function render()
	local body = {}

	if not usage then
		table.insert(body, ui.label({
			text = "Waiting for the usage service\u2026",
			color = "on_surface_variant",
		}))
	elseif not usage.ok then
		table.insert(body, ui.label({
			text = usage.message or "Usage unavailable",
			color = "error",
			fontWeight = "medium",
		}))
		if usage.message == "Set API key in settings" then
			table.insert(body, ui.label({
				text = "Add your oc_sk_... key under Settings \u{2192} Plugins \u{2192} gear icon.",
				fontSize = 12,
				color = "on_surface_variant",
			}))
		end
	else
		local shown = 0
		for _, key in { "fiveHour", "week", "month" } do
			local card = usage[key]
			if type(card) == "table" and card.percent >= 0 then
				table.insert(body, limitCard(card))
				shown += 1
			end
		end
		if shown == 0 then
			table.insert(body, ui.label({
				text = "No usage meters reported for this account.",
				color = "on_surface_variant",
			}))
		end
	end

	local footer = {
		headerRow(),
	}
	table.insert(footer, ui.spacer({ flexGrow = 1 }))
	table.insert(footer, ui.row({ gap = 8, justify = "end" }, {
		ui.button({
			text = "Refresh",
			glyph = "refresh",
			variant = "secondary",
			enabled = not busy,
			onClick = "onRefresh",
		}),
		ui.button({ text = "Close", variant = "ghost", onClick = "onCloseClicked" }),
	}))

	panel.render(ui.column({ gap = 12, padding = 16, flexGrow = 1 }, { footer }))
end

function onRefresh()
	busy = true
	render()
	noctalia.state.set("usage.cmd", (noctalia.state.get("usage.cmd") or 0) + 1)
end

function onCloseClicked()
	panel.close()
end

noctalia.state.watch("usage", function(value)
	usage = value
	busy = false
	render()
end)

function onOpen(_context)
	render()
end

render()
