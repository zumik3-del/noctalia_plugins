--!nonstrict

local API_URL = "https://opencode.ai/console/api/go/status"

local state = {
	rateLimitPercent = -1,
	rateLimitLabel = "",
	rateLimitResetAt = "",
	secondaryRateLimitPercent = -1,
	secondaryRateLimitLabel = "",
	secondaryRateLimitResetAt = "",
	monthlyRateLimitPercent = -1,
	monthlyRateLimitLabel = "",
	monthlyRateLimitResetAt = "",
	secondaryDailyRemaining = -1,
	monthlyDailyRemaining = -1,
	tierLabel = "",
	usageStatusText = "",
	ready = false,
}

local function meterFraction(meter: any): number
	if not meter then
		return -1
	end
	local limit = tonumber(meter.limitMicroCents)
	local used = tonumber(meter.usedMicroCents)
	if not limit or limit <= 0 or not used then
		return -1
	end
	return math.max(0, used / limit)
end

local function formatResetTime(isoTimestamp: string): string
	if not isoTimestamp then
		return ""
	end
	local reset = isoTimestamp
		:gsub("Z", "+00:00")
		:gsub("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)%.?(%d*)([+-]%d+):(%d+)", function(y, mo, d, h, mi, s, ms, oh, om)
			local time = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
			local offset = tonumber(oh) * 3600 + tonumber(om) * 60
			time = time - offset
			return tostring(time)
		end)
	local ok, resetTime = pcall(function()
		return tonumber(reset)
	end)
	if not ok or not resetTime then
		return ""
	end
	local now = os.time()
	local diff = resetTime - now
	if diff <= 0 then
		return "now"
	end
	local hours = math.floor(diff / 3600)
	local mins = math.floor((diff % 3600) / 60)
	if hours > 24 then
		return string.format("%dd %dh", math.floor(hours / 24), hours % 24)
	elseif hours > 0 then
		return string.format("%dh %dm", hours, mins)
	end
	return string.format("%dm", mins)
end

local function formatResetLine(isoTimestamp: string): string
	local text = formatResetTime(isoTimestamp)
	if text == "" then
		return ""
	end
	return "Resets in " .. text
end

local function dailyRemaining(fraction: number, isoTimestamp: string): number
	if fraction < 0 or not isoTimestamp then
		return -1
	end
	local reset = isoTimestamp
		:gsub("Z", "+00:00")
		:gsub("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)%.?(%d*)([+-]%d+):(%d+)", function(y, mo, d, h, mi, s, ms, oh, om)
			local time = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) })
			local offset = tonumber(oh) * 3600 + tonumber(om) * 60
			time = time - offset
			return tostring(time)
		end)
	local ok, resetTime = pcall(function()
		return tonumber(reset)
	end)
	if not ok or not resetTime then
		return -1
	end
	local secs = resetTime - os.time()
	if secs <= 0 then
		return -1
	end
	return (1 - fraction) / math.max(1, math.ceil(secs / 86400))
end

local function pctInt(fraction: number): string
	if fraction < 0 then
		return "0"
	end
	return tostring(math.floor(fraction * 100 + 0.5))
end

local function failState(message: string)
	state.usageStatusText = message
	state.rateLimitPercent = -1
	state.secondaryRateLimitPercent = -1
	state.monthlyRateLimitPercent = -1
	state.secondaryDailyRemaining = -1
	state.monthlyDailyRemaining = -1
	state.ready = true
	noctalia.state.set("usage", state)
end

local function parseUsage(body: string)
	local ok, data = pcall(noctalia.json.decode, body)
	if not ok or not data or data._tag or not data.access or not data.access.meters then
		failState("Usage unavailable (check API key)")
		return
	end

	local meters = data.access.meters
	local fiveHour = meters.fiveHour or nil
	local week = meters.week or nil
	local month = meters.month or nil
	local periodEnd = data.access.endsAt or ""

	state.rateLimitPercent = meterFraction(fiveHour)
	state.rateLimitLabel = "5-hour Usage"
	state.rateLimitResetAt = formatResetLine(fiveHour and fiveHour.resetsAt or "")

	state.secondaryRateLimitPercent = meterFraction(week)
	state.secondaryRateLimitLabel = "Weekly Usage"
	state.secondaryRateLimitResetAt = formatResetLine(week and week.resetsAt or "")
	state.secondaryDailyRemaining = dailyRemaining(state.secondaryRateLimitPercent, week and week.resetsAt or "")

	state.monthlyRateLimitPercent = meterFraction(month)
	state.monthlyRateLimitLabel = "Monthly Usage"
	state.monthlyRateLimitResetAt = formatResetLine(periodEnd)
	state.monthlyDailyRemaining = dailyRemaining(state.monthlyRateLimitPercent, periodEnd)

	state.tierLabel = data.cancelAtPeriodEnd and "Cancelling" or "Active"

	local parts = {}
	if fiveHour then
		table.insert(parts, "5h " .. pctInt(state.rateLimitPercent))
	end
	if week then
		table.insert(parts, "week " .. pctInt(state.secondaryRateLimitPercent))
	end
	if month then
		table.insert(parts, "month " .. pctInt(state.monthlyRateLimitPercent))
	end
	state.usageStatusText = table.concat(parts, " · ")
	state.ready = true

	noctalia.state.set("usage", state)
end

local function fetchUsage()
	local apiKey = noctalia.getConfig("api_key") or ""
	if apiKey == "" then
		failState("Set API key in settings")
		return
	end

	noctalia.http({
		url = API_URL,
		headers = {
			["Authorization"] = "Bearer " .. apiKey,
			["Accept"] = "application/json",
		},
	}, function(res)
		if res.ok then
			parseUsage(res.body)
		else
			failState("Usage unavailable (check API key)")
		end
	end)
end

function update()
	local interval = tonumber(noctalia.getConfig("refresh_interval_sec")) or 1800
	noctalia.setUpdateInterval(interval * 1000)
	fetchUsage()
end

function onIpc(event: string, payload: any)
	if event == "refresh" then
		fetchUsage()
	end
end
