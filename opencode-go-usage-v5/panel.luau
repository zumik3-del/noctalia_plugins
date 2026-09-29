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

local function formatDaily(fraction: number): string
	local v = fraction * 100
	if not isfinite(v) then
		return "—"
	end
	local r = math.floor(v * 10 + 0.5) / 10
	local sign = v > 0 and "+" or ""
	if r == math.floor(r) then
		return string.format("%s%d%%", sign, r)
	end
	return string.format("%s%.1f%%", sign, r)
end

local function limitColor(fraction: number): string
	if fraction >= 0.97 or fraction > 1.0 then
		return "error"
	elseif fraction >= 0.70 then
		return "warning"
	end
	return "primary"
end

local usage = noctalia.state.get("usage") or {}

local function render()
	if not usage or next(usage) == nil then
		panel.render(ui.column({ gap = 12, padding = 16 }, {
			ui.label({ text = "Opencode Go is not enabled. Enable it in Settings.", color = "surface_variant" }),
		}))
		return
	end

	local pct5h = usage.rateLimitPercent or -1
	local pctWeek = usage.secondaryRateLimitPercent or -1
	local pctMonth = usage.monthlyRateLimitPercent or -1

	local hasAnyLimit = pct5h >= 0 or pctWeek >= 0 or pctMonth >= 0

	if not hasAnyLimit and (usage.usageStatusText or "") == "" then
		panel.render(ui.column({ gap = 12, padding = 16 }, {
			ui.label({ text = "Opencode Go is not enabled. Enable it in Settings.", color = "surface_variant" }),
		}))
		return
	end

	local children = {}

	table.insert(children, ui.row({ align = "center", justify = "space_between", gap = 8 }, {
		ui.label({ text = "Usage limits", fontSize = 16, fontWeight = "bold", color = "on_surface" }),
		if (usage.tierLabel or "") ~= "" then
			ui.box({ fill = "primary/0.15", radius = 8, paddingH = 12, paddingV = 4 }, {
				ui.label({ text = usage.tierLabel, fontSize = 12, fontWeight = "semibold", color = "primary" }),
			})
		else nil,
	}))

	if not hasAnyLimit and (usage.usageStatusText or "") ~= "" then
		table.insert(children, ui.box({ fill = "error/0.12", radius = 8, padding = 12 }, {
			ui.label({ text = usage.usageStatusText, color = "error", fontWeight = "semibold" }),
		}))
	end

	if pct5h >= 0 then
		table.insert(children, ui.column({ gap = 8, padding = 12, fill = "surface_variant/0.4", radius = 8 }, {
			ui.row({ justify = "space_between" }, {
				ui.label({ text = usage.rateLimitLabel or "5-hour Usage", fontSize = 12, color = "surface_variant" }),
				ui.label({ text = formatPct(pct5h), fontSize = 12, fontWeight = "bold", color = limitColor(pct5h) }),
			}),
			ui.progress({ progress = math.min(1.0, math.max(0, pct5h)), fill = limitColor(pct5h), height = 8, radius = 4 }),
			ui.row({ justify = "space_between" }, {
				if (usage.rateLimitResetAt or "") ~= "" then
					ui.label({ text = usage.rateLimitResetAt, fontSize = 10, color = "surface_variant" })
				else nil,
			}),
		}))
	end

	if pctWeek >= 0 then
		table.insert(children, ui.column({ gap = 8, padding = 12, fill = "surface_variant/0.4", radius = 8 }, {
			ui.row({ justify = "space_between" }, {
				ui.label({ text = usage.secondaryRateLimitLabel or "Weekly Usage", fontSize = 12, color = "surface_variant" }),
				ui.label({ text = formatPct(pctWeek), fontSize = 12, fontWeight = "bold", color = limitColor(pctWeek) }),
			}),
			ui.progress({ progress = math.min(1.0, math.max(0, pctWeek)), fill = limitColor(pctWeek), height = 8, radius = 4 }),
			ui.row({ justify = "space_between" }, {
				if (usage.secondaryRateLimitResetAt or "") ~= "" then
					ui.label({ text = usage.secondaryRateLimitResetAt, fontSize = 10, color = "surface_variant" })
				else nil,
				if (usage.secondaryDailyRemaining or -1) >= -1 then
					ui.label({
						text = formatDaily(usage.secondaryDailyRemaining or 0),
						fontSize = 10,
						fontWeight = "semibold",
						color = (usage.secondaryDailyRemaining or 0) >= 0 and "primary" or "error",
					})
				else nil,
			}),
		}))
	end

	if pctMonth >= 0 then
		table.insert(children, ui.column({ gap = 8, padding = 12, fill = "surface_variant/0.4", radius = 8 }, {
			ui.row({ justify = "space_between" }, {
				ui.label({ text = usage.monthlyRateLimitLabel or "Monthly Usage", fontSize = 12, color = "surface_variant" }),
				ui.label({ text = formatPct(pctMonth), fontSize = 12, fontWeight = "bold", color = limitColor(pctMonth) }),
			}),
			ui.progress({ progress = math.min(1.0, math.max(0, pctMonth)), fill = limitColor(pctMonth), height = 8, radius = 4 }),
			ui.row({ justify = "space_between" }, {
				if (usage.monthlyRateLimitResetAt or "") ~= "" then
					ui.label({ text = usage.monthlyRateLimitResetAt, fontSize = 10, color = "surface_variant" })
				else nil,
				if (usage.monthlyDailyRemaining or -1) >= -1 then
					ui.label({
						text = formatDaily(usage.monthlyDailyRemaining or 0),
						fontSize = 10,
						fontWeight = "semibold",
						color = (usage.monthlyDailyRemaining or 0) >= 0 and "primary" or "error",
					})
				else nil,
			}),
		}))
	end

	table.insert(children, ui.spacer {})

	panel.render(ui.column({ gap = 12, padding = 16 }, children))
end

noctalia.state.watch("usage", function(value)
	usage = value or {}
	render()
end)

function onOpen(_context)
	render()
end
