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

function update()
	local usage = noctalia.state.get("usage") or {}

	if not usage or next(usage) == nil then
		panel.render({
			ui.box {
				ui.text { text = "Opencode Go is not enabled. Enable it in Settings.", color = "surface_variant" },
			},
		})
		return
	end

	local pct5h = usage.rateLimitPercent or -1
	local pctWeek = usage.secondaryRateLimitPercent or -1
	local pctMonth = usage.monthlyRateLimitPercent or -1

	local hasAnyLimit = pct5h >= 0 or pctWeek >= 0 or pctMonth >= 0

	if not hasAnyLimit and (usage.usageStatusText or "") == "" then
		panel.render({
			ui.box {
				ui.text { text = "Opencode Go is not enabled. Enable it in Settings.", color = "surface_variant" },
			},
		})
		return
	end

	local children = {}

	table.insert(children, ui.row {
		ui.text { text = "Usage limits", size = "xl", weight = "bold" },
		ui.spacer {},
		if (usage.tierLabel or "") ~= "" then
			ui.box {
				ui.text { text = usage.tierLabel, size = "s", weight = "semibold", color = "primary" },
			}
		else nil,
	})

	if not hasAnyLimit and (usage.usageStatusText or "") ~= "" then
		table.insert(children, ui.box {
			ui.text { text = usage.usageStatusText, color = "error", weight = "semibold" },
		})
	end

	if pct5h >= 0 then
		table.insert(children, ui.box {
			ui.row {
				ui.text { text = usage.rateLimitLabel or "5-hour Usage", size = "s", color = "surface_variant" },
				ui.spacer {},
				ui.text { text = formatPct(pct5h), size = "s", weight = "bold", color = limitColor(pct5h) },
			},
			ui.progress { value = math.min(1.0, math.max(0, pct5h)), color = limitColor(pct5h) },
			ui.row {
				if (usage.rateLimitResetAt or "") ~= "" then
					ui.text { text = usage.rateLimitResetAt, size = "xs", color = "surface_variant" }
				else nil,
				ui.spacer {},
			},
		})
	end

	if pctWeek >= 0 then
		table.insert(children, ui.box {
			ui.row {
				ui.text { text = usage.secondaryRateLimitLabel or "Weekly Usage", size = "s", color = "surface_variant" },
				ui.spacer {},
				ui.text { text = formatPct(pctWeek), size = "s", weight = "bold", color = limitColor(pctWeek) },
			},
			ui.progress { value = math.min(1.0, math.max(0, pctWeek)), color = limitColor(pctWeek) },
			ui.row {
				if (usage.secondaryRateLimitResetAt or "") ~= "" then
					ui.text { text = usage.secondaryRateLimitResetAt, size = "xs", color = "surface_variant" }
				else nil,
				ui.spacer {},
				if (usage.secondaryDailyRemaining or -1) >= -1 then
					ui.text {
						text = formatDaily(usage.secondaryDailyRemaining or 0),
						size = "xs",
						weight = "semibold",
						color = (usage.secondaryDailyRemaining or 0) >= 0 and "primary" or "error",
					}
				else nil,
			},
		})
	end

	if pctMonth >= 0 then
		table.insert(children, ui.box {
			ui.row {
				ui.text { text = usage.monthlyRateLimitLabel or "Monthly Usage", size = "s", color = "surface_variant" },
				ui.spacer {},
				ui.text { text = formatPct(pctMonth), size = "s", weight = "bold", color = limitColor(pctMonth) },
			},
			ui.progress { value = math.min(1.0, math.max(0, pctMonth)), color = limitColor(pctMonth) },
			ui.row {
				if (usage.monthlyRateLimitResetAt or "") ~= "" then
					ui.text { text = usage.monthlyRateLimitResetAt, size = "xs", color = "surface_variant" }
				else nil,
				ui.spacer {},
				if (usage.monthlyDailyRemaining or -1) >= -1 then
					ui.text {
						text = formatDaily(usage.monthlyDailyRemaining or 0),
						size = "xs",
						weight = "semibold",
						color = (usage.monthlyDailyRemaining or 0) >= 0 and "primary" or "error",
					}
				else nil,
			},
		})
	end

	table.insert(children, ui.spacer {})

	panel.render(ui.column(children))
end
