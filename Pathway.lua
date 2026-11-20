-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
-- Pathway: The core: quests, routes, trips, the guide, the arrow, map pins and everything they lean on.
-- Built from 30 source files by tools/bundle.py; each part runs as its own file did, in the same order.
local _, P = ...; P.SECTIONS = P.SECTIONS or {}
P.SECTIONS["Pathway.lua"] = { 8, "Core", 654, "Theme", 1347, "Notify", 1535, "Engine", 4015, "Travel", 4435, "Walk", 4580, "Trip", 5104, "Arrow", 5422, "QuestLayer", 5577, "Minimap", 5929, "Map", 6940, "Guide", 8627, "Highlight", 8804, "AutoQuest", 9018, "Gear", 9433, "Zones", 9577, "Find", 9749, "Extras", 10333, "Pace", 10477, "Group", 10561, "PvP", 11316, "Meter", 11725, "Buttons", 12011, "Obtain", 12196, "GearFinder", 12422, "Creatures", 12806, "Danger", 13038, "Learn", 13367, "Places", 13800, "WoWProLoad" }
-- ==================== Core.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Core
     Saved variables, a tiny event bus, client compatibility for WoW: Forever,
     map <-> world math, quest log state and the quest data accessors.
     Pathway is free software under the GPLv3; quest data comes from QuestieDB. ]]

local ADDON, P = __addon, __ns
Pathway = P

P.VERSION = "1.4.3"
P.ACCENT = { 0.21, 0.82, 0.5 }             -- Pathway green, the same as GoodMap's glow
P.ACCENT_HEX = "ff6ee7b7"
P.TITLE = "|cff6ee7b7Path|rway"
P.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
P.GoodMap = {}      -- the minimap module's namespace (GoodMap/)
P.settingsProviders = {}
-- modules add their own settings pages: fn(api) calls api.Page(key, title, blurb)
function P:AddSettings(group, fn) self.settingsProviders[#self.settingsProviders + 1] = { group = group, fn = fn } end
P.Fishing = {}      -- the fishing module's namespace (Fishing/)

local floor, sqrt, atan2, pi = math.floor, math.sqrt, math.atan2, math.pi
local pairs, ipairs, wipe, tinsert = pairs, ipairs, wipe, table.insert
local GetTime = GetTime

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
local DEFAULTS = {
	settings = {
		-- navigation
		arrow = true, arrowScale = 1, arrowLocked = false,
		autoContinue = true,          -- start the next nearby set when a route is done
		setRadius = 250,              -- yards: how far a "set" reaches from its first stop
		maxStops = 8,
		arriveDistance = 8,           -- yards
		sound = true,
		-- what gets suggested
		aheadLevels = 2,              -- quests up to this many levels above you
		showLow = false,              -- include gray (too easy) quests
		dungeonQuests = false,        -- include quests that start or end inside dungeons
		repeatable = false,
		-- map
		mapBar = true, mapPins = true, gmPins = true, separateButtons = false, tidyTracker = true, flightPins = "undiscovered",
		pinPickups = true, pinTurnins = true, pinObjectives = true,
		-- guides
		talentHints = true,           -- where your talent points go
		showAdvanced = false,         -- the Advanced pages in settings
		corpseRun = true,             -- the arrow points to your corpse after you release
		skipElite = false,            -- leave elite quests out of suggestions
		barStyle = "animated",        -- quest bar boxes: "animated" faces | "still" faces | "plain" buttons
		barLocked = false, barScale = 1,
		stepKey = true,               -- one key does what the step needs
		targetMarks = true,
		minimapButtons = true,
		flightStops = true,
		followPins = true,
		obtain = true,
		learn = true,                 -- learn quests the data doesn't have yet, as you play                -- Ctrl+Alt-click an item: where to get it, and a guide there            -- drop a map pin and Pathway takes you there, then back to your guide           -- an undiscovered flight path near your route joins it
		townCheck = false,            -- leaving town with things left to do there: ask (off: the guide already routes them)
		nextZoneTip = false,          -- a zone's guide done: suggest the next zone in a popup
		supplyCheck = true,           -- leaving town low on food, water or ammo: ask        -- Journal, Next set, Find and Pathway on the minimap's button bar           -- what a target box finds gets a raid marker
		hearthHints = true,           -- suggest your hearthstone when it's faster
		shareQuests = false,          -- share quests you pick up with your group
		levelPace = true,             -- experience per hour and time to level in the guide window
		dungeonHelp = true,           -- on entering a dungeon, list its quests
		pvpCard = true,               -- a card about players when you hover them
		healerMarks = true,           -- a red cross over enemy healers
		cardReplaces = true,          -- the player card stands in for the game's tooltip
		questStyle = "fast",          -- how to quest: "story" (storyline), "all" (chain to chain) or "fast" (fastest XP)
		travelButton = true,          -- "Go anywhere" on the minimap bar
		outfitsButton = true,         -- your saved outfits on the minimap bar (only when you have some)
		lockWindows = true,           -- windows stay put; Shift-drag moves one
		cardSpot = "fixed",           -- where the card goes: "fixed" (its own spot) or "tooltip"
		wowproTips = true,
		combatPulse = true,           -- the minimap's edge pulses red in combat
		aggroAlert = true,            -- a hostile creature almost close enough to notice you is called out
		aggroSound = true,
		serviceZoom = true,           -- near inns, flight masters and mailboxes the minimap zooms in and shows them            -- WoW-Pro's note for your step, in a small window under the guide
		mobCard = true,               -- hover a rare, elite or boss: a card with what it drops
		cardLinger = 1.5,             -- seconds the card stays after you move off
		pvpDing = "healers",          -- a ding when you target: "healers" (enemy) | "enemies" | "off"
		repairAlert = true,           -- offer the nearest repair when gear is nearly broken
		zoneMinQuests = 3,
		-- gear
		gearAlerts = true, gearAsk = true, gearBoE = true, gearAutoEquip = false,
		-- travel, guide window and helpers
		flights = true, easyTravel = true, minimapPath = true, mapPath = true, questLayer = true, indoorBlips = true,
		guideWindow = true, questBar = false, magicButton = true, stepHints = true, magicScale = 1,
		fps = false, fpsScale = 1, fpsLatency = true, fpsMemory = false,
		meter = true, meterStyle = "detailed", meterGroupLine = true, meterCards = true, meterCombatOnly = false, meterMode = "damage", meterOverall = false, meterScale = 1, meterRows = 8, cardScale = 1,
		autoAccept = true, autoTurnIn = true, autoReward = false, townTurnIns = true, dungeonSweeps = true, xpNudges = true, restNudge = true, campfirePop = true, share = true, firePins = true, questDelete = true, fireTimer = true, popupSpot = "bottom",
		tipLines = true, plateMarks = true, markMobs = false,
		-- modules (a reload applies these)
		bags = true, fishing = true, goodmap = true,
		-- looks
		accent = { 0.21, 0.82, 0.5 }, bgAlpha = 0.95, fontSize = "normal", uiSize = "auto",
	},
	zones = {},                       -- [uiMapID] = "always" | "never"
	pos = {},
	welcomed = false,
}
local CHAR_DEFAULTS = { notOffered = {}, route = nil, ignoredGear = {}, flights = {}, marked = {},
	never = {},                       -- quests you marked completed: never in a guide again on this character
	skipQ = {} }                      -- quests you skipped: left out until your next level

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} end
			merge(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

---------------------------------------------------------------------------
-- Per-part timing for the performance meter: what each part of Pathway costs.
-- Off (one check per call) unless the meter is showing.
---------------------------------------------------------------------------
local Perf = { on = false, cost = {}, rate = {}, since = 0, srcCost = {}, srcRate = {}, srcPart = {} }
P.Perf = Perf
local dps = debugprofilestop
-- the parts, by file, and the setting that turns each off (reload: needs a /reload)
Perf.PARTS = {
	{ name = "Minimap", key = "goodmap", reload = true }, { name = "Bags", key = "bags", reload = true },
	{ name = "Fishing", key = "fishing", reload = true }, { name = "Damage meter", key = "meter" },
	{ name = "Player cards", key = "pvpCard" }, { name = "Rare and elite cards", key = "mobCard" },
	{ name = "Combat and danger alerts", key = "aggroAlert" },
	{ name = "Arrow", key = "arrow" }, { name = "Guide window", key = "guideWindow" },
	{ name = "World map pins", key = "mapBar" }, { name = "Gear upgrades", key = "gearAlerts" },
	{ name = "Talent suggestions", key = "talentHints" }, { name = "Learning new quests", key = "learn" },
	{ name = "Level pace", key = "levelPace" }, { name = "Performance meter", key = "fps" },
	{ name = "Ride effects", key = "map.rideFx" },
	{ name = "Quest routes" },
}
local FILE_PART = {
	GoodMap = "Minimap", Bags = "Bags", Fishing = "Fishing", Meter = "Damage meter", PvP = "Player cards",
	Creatures = "Rare and elite cards", Danger = "Combat and danger alerts", Arrow = "Arrow", Guide = "Guide window", Map = "World map pins",
	Gear = "Gear upgrades", GearFinder = "Gear upgrades", Talents = "Talent suggestions", Learn = "Learning new quests",
	Pace = "Level pace", FPS = "Performance meter",
}
function Perf.PartOf(file)
	if not file then return "Quest routes" end
	local dir = file:match("^(%a+)[/\\]")
	return FILE_PART[dir or ""] or FILE_PART[file:match("([%w_]+)$") or ""] or "Quest routes"
end
-- A spot in the code, as its source file and line ("Engine", 1857). The add-on ships its
-- files joined into a few (tools/bundle.py); P.SECTIONS says where each one starts.
local function Source(file, line)
	local starts = P.SECTIONS and P.SECTIONS[file .. ".lua"]
	if not starts then return file, line end
	local name, first
	for i = 1, #starts, 2 do
		if starts[i] > line then break end
		first, name = starts[i], starts[i + 1]
	end
	if not name then return file, line end
	return name, line - first + 1
end
local function StackSpot(level)
	if not debugstack then return nil end
	local ok, st = pcall(debugstack, level + 1, 1, 0)
	if not ok or type(st) ~= "string" then return nil end
	local file, line = st:match("Pathway[/\\](.-)%.lua\"?%]?:(%d+)")
	if not file then return nil end
	return Source(file, tonumber(line))
end
P.SourceOf = Source
-- where a handler was registered: "Engine.lua:1857", so the meter can name the exact one
function Perf.Where(level)
	local file, line = StackSpot((level or 2) + 1)
	return file and (file .. ".lua:" .. line) or nil
end
-- which part is registering this (from the calling file)
function Perf.Caller(level)
	return Perf.PartOf((StackSpot((level or 2) + 1)))
end
-- src (optional): which handler this is, e.g. "QUEST_LOG_UPDATE  Core.lua:597"
function Perf.W(tag, fn, src)
	if type(fn) ~= "function" or not dps then return fn end
	if src then Perf.srcPart[src] = tag end
	return function(...)
		if not Perf.on then return fn(...) end
		local t = dps()
		local a, b, c, d = fn(...)
		local spent = dps() - t
		Perf.cost[tag] = (Perf.cost[tag] or 0) + spent
		if src then Perf.srcCost[src] = (Perf.srcCost[src] or 0) + spent end
		return a, b, c, d
	end
end
-- wrap a frame's script (OnUpdate, OnEvent) so its time counts for its part
function Perf.Hook(frame, tag, script)
	script = script or "OnUpdate"
	local fn = frame and frame.GetScript and frame:GetScript(script)
	local where = Perf.Where(2)
	if fn then frame:SetScript(script, Perf.W(tag, fn, script .. "  " .. (where or tag))) end
end
-- the costliest handlers right now: { { src, ms a second, part }, ... }
function Perf.Top(n)
	local list = {}
	for src, ms in pairs(Perf.srcRate) do
		if ms >= 0.01 then list[#list + 1] = { src, ms, Perf.srcPart[src] } end
	end
	table.sort(list, function(a, b) return a[2] > b[2] end)
	for i = #list, (n or 8) + 1, -1 do list[i] = nil end
	return list
end
-- every few seconds: milliseconds of work each second, per part
function Perf.Sample()
	local now = GetTime()
	local dt = now - (Perf.since or now)
	Perf.since = now
	if dt <= 0 or dt > 30 then wipe(Perf.cost) return end
	for _, part in ipairs(Perf.PARTS) do
		local v = (Perf.cost[part.name] or 0) / dt
		local was = Perf.rate[part.name]
		Perf.rate[part.name] = was and (was * 0.5 + v * 0.5) or v
	end
	-- the worst each handler has been, kept in saved variables (with where you were and what you
	-- were doing), so a slow moment can be looked at afterwards instead of guessed at
	local peaks = P.db and P.db.perfPeaks
	if P.db and not peaks then peaks = {}; P.db.perfPeaks = peaks end
	for src in pairs(Perf.srcPart) do
		local v = (Perf.srcCost[src] or 0) / dt
		local was = Perf.srcRate[src]
		local r = was and (was * 0.5 + v * 0.5) or v
		Perf.srcRate[src] = r > 0.001 and r or nil
		if peaks and v >= 2 and (not peaks[src] or v > peaks[src].ms) then
			local route = P.route
			peaks[src] = { ms = floor(v * 100 + 0.5) / 100, part = Perf.srcPart[src],
				zone = GetRealZoneText and GetRealZoneText() or nil, fight = InCombatLockdown() and true or nil,
				guide = route and (route.mode .. " " .. #route.stops) or nil, at = date and date("%m-%d %H:%M") or nil }
		end
	end
	wipe(Perf.cost); wipe(Perf.srcCost)
	-- the 20 worst only
	if peaks then
		local n, low, lowK = 0, math.huge, nil
		for k, p in pairs(peaks) do n = n + 1; if p.ms < low then low, lowK = p.ms, k end end
		if n > 20 and lowK then peaks[lowK] = nil end
	end
end
function Perf.Start(on)
	if on and not Perf.on then Perf.since = GetTime(); wipe(Perf.cost) end
	Perf.on = on and true or false
end

---------------------------------------------------------------------------
-- Event bus (same shape as Lil's GoodBags)
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers, messages, pending = {}, {}, {}

function P:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		pcall(eventFrame.RegisterEvent, eventFrame, event)   -- an event missing on this client never breaks loading
	end
	tinsert(handlers[event], Perf.W(Perf.Caller(2), fn, event .. "  " .. (Perf.Where(2) or "?")))
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = handlers[event]
	if list then for i = 1, #list do list[i](event, ...) end end
end)

function P:Listen(msg, fn) messages[msg] = messages[msg] or {}; tinsert(messages[msg], Perf.W(Perf.Caller(2), fn, msg .. "  " .. (Perf.Where(2) or "?"))) end
function P:Send(msg, ...) local l = messages[msg]; if l then for i = 1, #l do l[i](...) end end end

function P:Debounce(key, delay, fn)
	if pending[key] then return end
	pending[key] = true
	C_Timer.After(delay, function() pending[key] = nil; fn() end)
end

function P:Print(msg, ...) print((P.TITLE .. ": " .. msg):format(...)) end

---------------------------------------------------------------------------
-- Quest data accessors (Data/Quests.lua)
---------------------------------------------------------------------------
P.K = {
	NAME = 1, REQ = 2, LVL = 3, RACE = 4, CLS = 5, SN = 6, SO = 7, EN = 8, EO = 9,
	PRE = 10, PREANY = 11, EXCL = 12, NEXT = 13, FLAGS = 14, ZONE = 15,
	ON = 16, OO = 17, OI = 18, TEXT = 19, MAX = 20, PARENT = 21, CRUMB = 22, SKILL = 23,
	TRIGMAP = 24, TRIGPT = 25, SI = 26, USE = 27, SORT = 28,
}

-- packed coordinate -> 0..1 map coordinates
function P.Unpack(p)
	local xi = floor(p / 10001)
	return xi / 10000, (p - xi * 10001) / 10000
end

function P:Entity(kind, id)
	if kind == "N" then return self.N[id] elseif kind == "O" then return self.O[id] end
end

function P:EntityName(kind, id)
	local e = self:Entity(kind, id)
	return e and e[1] or ""
end

-- elite quests: the mobs you have to kill (or that drop what you need) are elites
local eliteCache = {}
function P:QuestElite(qid)
	local c = eliteCache[qid]
	if c ~= nil then return c or nil end
	local q, K = self.Q[qid], self.K
	local lvl = false
	local function check(id)
		local e = self.N[id]
		if e and (e[5] == 1 or e[5] == 2 or e[5] == 3) and type(e[3]) ~= "string" then lvl = math.max(lvl or 0, e[6] or 1) end
	end
	if q then
		for _, id in ipairs(q[K.ON] or {}) do check(id) end
		for _, iid in ipairs(q[K.OI] or {}) do
			local it = self.I[iid]
			if it and it[2] and #it[2] <= 3 then for _, id in ipairs(it[2]) do check(id) end end
		end
	end
	eliteCache[qid] = lvl
	return lvl or nil
end

---------------------------------------------------------------------------
-- Map <-> world. World positions are in yards on a continent:
--   wx grows to the west, wy grows to the north (same axes as UnitPosition).
---------------------------------------------------------------------------
local xform = {}
local v00, v05

function P.ResetMapCache() wipe(xform) end
function P:MapXform(map)
	if not map then return end
	local t = xform[map]
	if t == nil then
		t = false
		if C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
			v00 = v00 or CreateVector2D(0, 0)
			v05 = v05 or CreateVector2D(0.5, 0.5)
			local inst, center = C_Map.GetWorldPosFromMapPos(map, v05)
			local _, topleft = C_Map.GetWorldPosFromMapPos(map, v00)
			if inst and center and topleft then
				local top, left = topleft:GetXY()
				local cTop, cLeft = center:GetXY()
				local w, h = (left - cLeft) * 2, (top - cTop) * 2
				if w ~= 0 and h ~= 0 then t = { inst, left, top, w, h } end
			end
		end
		xform[map] = t
	end
	return t or nil
end

-- map coordinates (0..1) -> instance, wx, wy
function P:WorldPos(map, x, y)
	local t = self:MapXform(map)
	if not t then return end
	return t[1], t[2] - t[4] * x, t[3] - t[5] * y
end

-- world -> map coordinates on a given map (for pins and the "you are here" check)
function P:MapPos(map, wx, wy)
	local t = self:MapXform(map)
	if not t then return end
	return (t[2] - wx) / t[4], (t[3] - wy) / t[5]
end

function P:PlayerPos()
	local wy, wx, _, inst = UnitPosition("player")
	if not wy then return end
	return inst, wx, wy
end

-- distance in yards and the angle to face (radians, counter-clockwise from north)
function P.Vector(px, py, tx, ty)
	local dx, dy = tx - px, ty - py
	local a = atan2(dx, dy)
	if a < 0 then a = a + 2 * pi end
	return sqrt(dx * dx + dy * dy), a
end

-- A map inside a zone (a cave, a building, a tunnel, a floor): Pathway's data
-- is kept for the zone around it. SubMapZone gives that zone (nil for a map that
-- holds its own data), and OnSubMap moves a list of points from the zone onto
-- the smaller map, through the world, keeping only those that are on it.
local subZone = {}
function P:SubMapZone(map)
	if not map then return end
	local z = subZone[map]
	if z == nil then
		z = false
		local info = C_Map.GetMapInfo(map)
		-- only maps the game itself draws below a zone: caves, buildings, floors
		if info and info.mapType and Enum.UIMapType and info.mapType > Enum.UIMapType.Zone then
			local up = self:ZoneOf(map)
			if up and up ~= map then z = up end
		end
		subZone[map] = z
	end
	return z or nil
end
function P:OnSubMap(map, zone, list)
	local out = {}
	for _, e in ipairs(list) do
		local inst, wx, wy = e.wx and true, e.wx, e.wy
		if not wx then inst, wx, wy = self:WorldPos(zone, e.x, e.y) end
		if inst and wx then
			local x, y = self:MapPos(map, wx, wy)
			if x and x > -0.02 and x < 1.02 and y > -0.02 and y < 1.02 then
				local c = {}
				for k, v in pairs(e) do c[k] = v end
				c.x, c.y, c.wx, c.wy = x, y, wx, wy
				out[#out + 1] = c
			end
		end
	end
	return out
end

-- the zone-level map for any map (subzones and micro maps climb to their zone)
local zoneOf = {}
function P:ZoneOf(map)
	if not map then return end
	local z = zoneOf[map]
	if z == nil then
		z = map
		local info = C_Map.GetMapInfo(map)
		local guard = 0
		while info and info.mapType and Enum.UIMapType and info.mapType > Enum.UIMapType.Zone and info.parentMapID and info.parentMapID ~= 0 and guard < 6 do
			z = info.parentMapID
			info = C_Map.GetMapInfo(z)
			guard = guard + 1
		end
		-- a starting area or town drawn as its own map: the zone around it holds its quests
		if not P.questZones then
			P.questZones = {}
			for _, q in pairs(P.Q) do local zz = q[P.K.ZONE]; if zz then P.questZones[zz] = true end end
		end
		guard = 0
		while not P.questZones[z] and info and info.parentMapID and info.parentMapID ~= 0 and guard < 3 do
			local up = C_Map.GetMapInfo(info.parentMapID)
			if not up or (up.mapType and Enum.UIMapType and up.mapType < Enum.UIMapType.Zone) then break end
			z, info = info.parentMapID, up
			guard = guard + 1
		end
		zoneOf[map] = z
	end
	return z
end

function P:PlayerZone()
	local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	return self:ZoneOf(m)
end

function P:MapName(map)
	local info = map and C_Map.GetMapInfo(map)
	return info and info.name or "?"
end

---------------------------------------------------------------------------
-- Quest state: completed quests and the quest log
---------------------------------------------------------------------------
P.done = {}     -- [questID] = true
P.log = {}      -- [questID] = { index =, title =, complete = bool, failed = bool }

local function IsFlaggedDone(id)
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(id) end
	if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(id) end
	return false
end
P.IsFlaggedDone = IsFlaggedDone

function P:LoadCompleted()
	wipe(self.done)
	for _, id in ipairs(C_QuestLog.GetAllCompletedQuestIDs() or {}) do self.done[id] = true end
end

function P:IsDone(id) return self.done[id] == true end

local function LogEntry(i)
	local info = C_QuestLog.GetInfo(i)
	if not info then return end
	return info.title, info.isHeader, info.questID, nil
end

local function NumEntries() return (C_QuestLog.GetNumQuestLogEntries()) end

-- objectives for a quest in the log: { {text=, finished=, type=}, ... }
function P:Objectives(id)
	return C_QuestLog.GetQuestObjectives(id) or {}
end

-- Reading the log. The game sends "the quest log changed" many times a
-- second (and often nothing did), so the log keeps two short signatures:
-- its shape (which quests, done or not) and their progress (the objective
-- counts). Only a change in shape makes Pathway work out again what you can
-- pick up; progress alone just moves the guide along.
local shapeBuf, progBuf = {}, {}
function P:ScanLog()
	local log = self.log
	wipe(log)
	local ns, np = 0, 0
	for i = 1, NumEntries() do
		local title, isHeader, id, isComplete = LogEntry(i)
		if id and id > 0 and not isHeader then
			local e = { index = i, title = title }
			if isComplete == nil and C_QuestLog and C_QuestLog.IsComplete then isComplete = C_QuestLog.IsComplete(id) end
			e.failed = isComplete == -1
			local objs = self:Objectives(id)
			local allDone = true
			for _, o in ipairs(objs) do if not o.finished then allDone = false end end
			e.complete = (isComplete == 1 or isComplete == true) or (allDone and not e.failed)
			e.objectives = objs
			log[id] = e
			ns = ns + 1
			shapeBuf[ns] = id .. (e.complete and "c" or e.failed and "f" or "")
			for _, o in ipairs(objs) do
				np = np + 1
				progBuf[np] = (o.text or "") .. (o.finished and "+" or "")
			end
		end
	end
	for i = #shapeBuf, ns + 1, -1 do shapeBuf[i] = nil end
	for i = #progBuf, np + 1, -1 do progBuf[i] = nil end
	local shape, prog = table.concat(shapeBuf, ","), table.concat(progBuf, "|")
	local shapeChanged, progChanged = shape ~= self.logShape, prog ~= self.logProg
	self.logShape, self.logProg = shape, prog
	if shapeChanged or not self.inferred then self.inferred = true; self:InferDone() end
	return shapeChanged, progChanged
end

-- Quests the server never told us about: anything a done (or in-log) quest
-- needed first must be done too, and a quest its giver no longer offers is
-- treated as done, so guides go straight on to the next one in the chain.
function P:InferDone()
	local Q, K, done = self.Q, self.K, self.done
	if not Q then return end
	for qid in pairs(self.cdb and self.cdb.notOffered or {}) do done[qid] = true end
	-- quests you marked done count as done, so what follows them can open up
	local m = self.cdb and self.cdb.marked
	for qid in pairs(m and m.quests or {}) do done[qid] = true end
	for qid in pairs(m and m.turnins or {}) do done[qid] = true end
	local function back(qid, depth)
		local q = Q[qid]
		if not q or depth > 30 then return end
		for _, p in ipairs(q[K.PRE] or {}) do
			if not done[p] then done[p] = true; back(p, depth + 1) end
		end
	end
	local seeds = {}
	for qid in pairs(done) do seeds[#seeds + 1] = qid end
	for qid in pairs(self.log) do seeds[#seeds + 1] = qid end
	for _, qid in ipairs(seeds) do back(qid, 0) end
end

function P:InLog(id) return self.log[id] ~= nil end

---------------------------------------------------------------------------
-- The player
---------------------------------------------------------------------------
P.me = {}
function P:RefreshPlayer()
	local me = self.me
	me.level = UnitLevel("player")
	me.faction = UnitFactionGroup("player")
	me.race = select(3, UnitRace("player"))
	me.class = select(3, UnitClass("player"))
	me.classFile = select(2, UnitClass("player"))
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
-- "Start fresh": every setting back to how it came. What Pathway learned about
-- quests and places is kept. Other characters reset the next time they log in.
function P:ResetAll()
	local old = PathwayDB or {}
	PathwayDB = { learned = old.learned, places = old.places, epoch = (old.epoch or 0) + 1 }
	PathwayCharDB = { epoch = PathwayDB.epoch }
	PathwayBagsDB, PathwayBagsCharDB, PathwayMapDB, PathwayFishDB = nil, nil, nil, nil
	ReloadUI()
end

P:On("ADDON_LOADED", function(_, name)
	if name ~= ADDON then return end
	local epoch = PathwayDB and PathwayDB.epoch or 0
	if (PathwayCharDB and PathwayCharDB.epoch or 0) ~= epoch then
		PathwayCharDB, PathwayBagsCharDB = { epoch = epoch }, nil
	end
end)

P:On("PLAYER_LOGIN", function()
	PathwayDB = merge(PathwayDB or {}, DEFAULTS)
	PathwayCharDB = merge(PathwayCharDB or {}, CHAR_DEFAULTS)
	P.db, P.cdb = PathwayDB, PathwayCharDB
	-- 1.2.0: no popups about zones or towns unless asked for
	if (PathwayDB.migrated or 0) < 120 then
		PathwayDB.migrated = 120
		PathwayDB.settings.townCheck, PathwayDB.settings.nextZoneTip = false, false
	end
	P:RefreshPlayer()
	P:LoadCompleted()
	P:ScanLog()
	P:Send("READY")
end)

P:On("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
	if isLogin or isReload then
		-- the quest log and completion list can arrive a moment after login
		C_Timer.After(2, function() P:LoadCompleted(); P:ScanLog(); P:Send("QUESTS_CHANGED") end)
	end
end)

-- QUESTS_CHANGED: a quest came or went, or got done (everything is worked
-- out again). QUEST_PROGRESS: only objective counts moved (the guide and the
-- route follow along; what you can pick up hasn't changed). Nothing changed:
-- nothing is sent.
local forceFull = false
local function LogChanged()
	P:Debounce("log", 0.2, function()
		local shape, prog = P:ScanLog()
		if shape or forceFull then forceFull = false; P:Send("QUESTS_CHANGED")
		elseif prog then P:Send("QUEST_PROGRESS") end
	end)
end
P:On("QUEST_LOG_UPDATE", LogChanged)
P:On("UNIT_QUEST_LOG_CHANGED", function(_, unit) if unit == "player" then LogChanged() end end)
P:On("QUEST_ACCEPTED", LogChanged)
P:On("QUEST_REMOVED", function() forceFull = true; LogChanged() end)
P:On("QUEST_TURNED_IN", function(_, id)
	if id then P.done[id] = true end
	forceFull = true
	LogChanged()
end)
P:On("PLAYER_LEVEL_UP", function(_, level)
	P:RefreshPlayer()
	if level then P.me.level = level end
	P:Send("QUESTS_CHANGED")
end)
end part() end
-- ==================== Theme.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Theme
     The look shared by every Pathway frame (the same flat, quiet style as
     Lil's GoodBags), plus toasts and the prompt cards used to ask questions
     ("Equip this?", "Load the Westfall guide?"). ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local floor, max, min = math.floor, math.max, math.min
local tinsert, tremove = table.insert, table.remove

local WHITE = "Interface\\Buttons\\WHITE8X8"
P.WHITE = WHITE
P.DIM = "|cff6b7480"
P.GOLD = "|cffffd27a"

-- shared palette, refilled in place by ApplyTheme so everything follows live
local BG      = { 0.035, 0.04, 0.05, 0.95 }
local EDGE    = { 0.24, 0.26, 0.3, 1 }
local PANEL   = { 0.1, 0.11, 0.13, 0.95 }
local ACCENT_BG   = { A[1] * 0.22, A[2] * 0.22, A[3] * 0.22, 1 }
local ACCENT_EDGE = { A[1], A[2], A[3], 0.7 }
P.colors = { BG = BG, EDGE = EDGE, PANEL = PANEL, ACCENT_BG = ACCENT_BG, ACCENT_EDGE = ACCENT_EDGE }

---------------------------------------------------------------------------
-- Fonts
---------------------------------------------------------------------------
local fontList = {}
local function MakeFont(name, size, flags, r, g, b)
	local f = CreateFont(name)
	f:SetFont(STANDARD_TEXT_FONT, size, flags or "")
	f:SetTextColor(r or 1, g or 1, b or 1)
	fontList[#fontList + 1] = { f, size, flags or "" }
	return f
end
P.fonts = {
	title  = MakeFont("PathwayFontTitle", 13, "", 0.95, 0.96, 0.97),
	head   = MakeFont("PathwayFontHead", 10, "", 0.60, 0.65, 0.71),
	button = MakeFont("PathwayFontButton", 11, "", 0.93, 0.95, 0.96),
	big    = MakeFont("PathwayFontBig", 14, "OUTLINE", 1, 1, 1),
	small  = MakeFont("PathwayFontSmall", 11, "OUTLINE", 0.85, 0.88, 0.92),
}

---------------------------------------------------------------------------
-- Flat frames
---------------------------------------------------------------------------
local painted = setmetatable({}, { __mode = "k" })
local paintHooks = {}
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local WINDOW = { bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 } }

local function Paint(f)
	local d = painted[f]
	if not d then return end
	f:SetBackdrop(d.window and WINDOW or FLAT)
	f:SetBackdropColor(unpack(d.bg))
	f:SetBackdropBorderColor(unpack(d.edge))
end

function P.Flat(f, bg, edge, isWindow)
	painted[f] = { bg = bg or (isWindow and BG) or PANEL, edge = edge or (isWindow and { 0.62, 0.64, 0.7, 1 }) or EDGE, window = isWindow }
	Paint(f)
end

function P:OnPaint(fn) paintHooks[#paintHooks + 1] = fn end

---------------------------------------------------------------------------
-- Cards (players, rares and elites): the game's own tooltip look, with its
-- rounded border, its header and body fonts and gold labels, so a card feels
-- like part of the game. Pathway's touches stay: the colored band and border,
-- the big item level, the odds bar.
---------------------------------------------------------------------------
local TIP = { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
local skinned = setmetatable({}, { __mode = "k" })
local function TipPaint(f)
	f:SetBackdropColor(0.045, 0.05, 0.085, (P.opacity or 0.95))
end
function P:TooltipSkin(f)
	f:SetBackdrop(TIP)
	skinned[f] = true
	TipPaint(f)
end
function P:RepaintCards() for f in pairs(skinned) do TipPaint(f) end end
-- the game's tooltip fonts, where this client has them
P.tipFonts = {
	head = _G.GameTooltipHeaderText or P.fonts.big,
	text = _G.GameTooltipText or P.fonts.button,
	small = _G.GameTooltipTextSmall or P.fonts.head,
}

local function fill(t, r, g, b, a) t[1], t[2], t[3], t[4] = r, g, b, a or 1 end

---------------------------------------------------------------------------
-- Size: one factor for every Pathway window, so text reads the same on any
-- screen. "auto" aims for body text about 13 pixels tall on your screen;
-- the presets are fixed steps around that.
---------------------------------------------------------------------------
local PRESET = { small = 0.9, normal = 1, large = 1.15, huge = 1.3 }
function P:AutoScale()
	local _, ph = GetPhysicalScreenSize and GetPhysicalScreenSize()
	ph = tonumber(ph) or 1080
	local s = UIParent and tonumber(UIParent:GetEffectiveScale()) or 1
	local px = 11 * ph * s / 768                 -- how tall 11-point text is, in pixels
	local k = 13 / max(px, 1)
	return max(1, min(1.45, k))
end
function P:UIScale()
	local s = self.db and self.db.settings
	local size = s and s.uiSize or "auto"
	local base = self:AutoScale()
	if PRESET[size] then return base * PRESET[size] end
	return base
end
-- frame name -> its own size setting on top
local SIZED = {
	PathwayArrow = "arrowScale", PathwayGuide = true, PathwayGuidePill = true, PathwayMagicButton = "magicScale",
	PathwayQuestBar = "barScale", PathwayJournal = true, PathwayPlayerCard = "cardScale", PathwaySettings = true,
	PathwayPrompt = true, PathwayToast = true, PathwaySetup = true, PathwayTip = true, PathwaySetupMap = true, PathwaySetupParts = true, PathwaySetupMeter = true, PathwayNotes = true, PathwayMeter = "meterScale", PathwayFPS = "fpsScale", PathwayFPSPanel = true, PathwayPlaceBar = true, PathwayGoTo = true, PathwayOutfits = true,
}
-- Every window: drag it where you like, and Ctrl + mouse wheel over it makes it
-- bigger or smaller. Both are remembered per window ("Reset windows" in Settings
-- puts them all back).
local function WinScale(name)
	local w = P.db and P.db.winScale
	return w and w[name] or 1
end
-- (a window builds its size before it turns the mouse on, so this waits for that:
-- it's checked again every time sizes are applied, and hooks once)
local NO_WHEEL = { PathwayToast = true, PathwayTip = true, PathwayPlaceBar = true, PathwayPlayerCard = true }
local function Adjustable(f, name)
	if f.pwAdjust or NO_WHEEL[name] then return end
	if f.EnableMouseWheel and f:IsMouseEnabled() then
		f.pwAdjust = true
		f:EnableMouseWheel(true)
		f:HookScript("OnMouseWheel", function(self, delta)
			if IsControlKeyDown() then P:NudgeScale(self, delta) end
		end)
	end
end
-- one notch of Ctrl + mouse wheel: 5% bigger or smaller, remembered per window
function P:NudgeScale(f, delta)
	local name = f and f.GetName and f:GetName()
	if not name or not SIZED[name] then return end
	if InCombatLockdown() and f:IsProtected() then return end
	P.db.winScale = P.db.winScale or {}
	local v = math.max(0.6, math.min(2, WinScale(name) + delta * 0.05))
	P.db.winScale[name] = (math.abs(v - 1) < 0.001) and nil or v
	P:ApplySizes()
	if P.ShowScaleHint then P:ShowScaleHint(f, v) end
end
-- Where each window starts: a layout that keeps the middle of the screen clear
-- (performance meter and arrow up top, the guide under the minimap, the meter and
-- player card on the left, the magic button just above your action bars).
-- Offsets are shares of the screen, so it looks the same on any size.
local DEFAULT_POS = {
	PathwayFPS = { "TOP", "TOP", 0, -6 / 1080 },
	arrow = { "TOP", "TOP", 0, -52 / 1080 },
	PathwayGuide = { "TOPRIGHT", "TOPRIGHT", -58 / 1920, -445 / 1080 },
	PathwayMeter = { "TOPLEFT", "TOPLEFT", 32 / 1920, -665 / 1080 },
	PathwayPlayerCard = { "BOTTOMLEFT", "BOTTOMLEFT", 37 / 1920, 460 / 1080 },
	PathwayMagicButton = { "CENTER", "BOTTOM", 0, 185 / 1080 },
	PathwayQuestBar = { "TOP", "TOP", 0, -205 / 1080 },
}
-- put a window where you left it, or where it starts. key: its saved name
function P:PlaceAt(f, key)
	key = key or f:GetName()
	local pos = P.db and P.db.pos[key]
	f:ClearAllPoints()
	if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) return end
	local d = DEFAULT_POS[key]
	if not d then f:SetPoint("CENTER") return end
	local k = (tonumber(UIParent:GetEffectiveScale()) or 1) / (tonumber(f:GetEffectiveScale()) or 1)
	local w, h = tonumber(UIParent:GetWidth()) or 1920, tonumber(UIParent:GetHeight()) or 1080
	f:SetPoint(d[1], UIParent, d[2], d[3] * w * k, d[4] * h * k)
end
-- Keep a window by its top edge, so a taller one grows down, never up over
-- what sits above it (the minimap, its buttons). Its right side if it's on the
-- right half of the screen, else its left. Saved where it is now, unmoved.
function P:KeepTop(f, key)
	local s, us = tonumber(f:GetEffectiveScale()), tonumber(UIParent:GetEffectiveScale())
	local l, r, t = tonumber(f:GetLeft()), tonumber(f:GetRight()), tonumber(f:GetTop())
	local W, H = tonumber(UIParent:GetWidth()), tonumber(UIParent:GetHeight())
	if not (s and us and l and r and t and W and H and P.db) then return end
	local k = s / us                          -- the window's units to the screen's
	local p, x
	if (l + r) / 2 * k > W / 2 then p, x = "TOPRIGHT", (r * k - W) / k else p, x = "TOPLEFT", l end
	local y = (t * k - H) / k
	f:ClearAllPoints()
	f:SetPoint(p, UIParent, p, x, y)
	P.db.pos[key or f:GetName()] = { p, p, x, y }
end
function P:HasDefaultSpot(key) return DEFAULT_POS[key] ~= nil end

-- Pop-ups (the question cards, the campfire, its timer) share one spot: by default
-- just above the magic button, bottom middle; setup asks where you'd like them.
-- When more than one is up they stack away from it, never on top of each other.
-- Shift-drag any of them to move the spot for all.
local popStack = {}
local function PopBase()
	local W, H = tonumber(UIParent:GetWidth()) or 1920, tonumber(UIParent:GetHeight()) or 1080
	local c = P.db and P.db.pos.popups
	if c then return c[1], c[2], c[3] end
	local spot = P.db and P.db.settings.popupSpot or "bottom"
	if spot == "top" then return "TOP", 0, -150 / 1080 * H end
	if spot == "middle" then return "BOTTOM", 0, H * 0.52 end
	-- just above the magic button, or where it would be
	local y = 225 / 1080 * H
	local m = _G.PathwayMagicButton
	local top = m and m:IsShown() and tonumber(m:GetTop())
	if top then y = top * (tonumber(m:GetEffectiveScale()) or 1) / (tonumber(UIParent:GetEffectiveScale()) or 1) + 12 end
	return "BOTTOM", 0, y
end
function P:PopupLayout()
	local p, x, y = PopBase()
	local dir = p == "BOTTOM" and 1 or -1
	local us = tonumber(UIParent:GetEffectiveScale()) or 1
	for _, f in ipairs(popStack) do
		if f:IsShown() then
			local k = us / (tonumber(f:GetEffectiveScale()) or 1)
			f:ClearAllPoints(); f:SetPoint(p, UIParent, p, x * k, y * k)
			y = y + dir * ((tonumber(f:GetHeight()) or 0) / k + 8)
		end
	end
end
local function Unstack(f) for i = #popStack, 1, -1 do if popStack[i] == f then tremove(popStack, i) end end end
function P:PopupFrame(f)
	f:SetClampedToScreen(true)
	f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
	f:HookScript("OnShow", function(self)
		Unstack(self); popStack[#popStack + 1] = self
		P:PopupLayout()
	end)
	f:HookScript("OnHide", function(self) Unstack(self); P:PopupLayout() end)
	f:SetScript("OnDragStart", function(self) if P:CanDrag() then self:StartMoving() end end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local s, us = tonumber(self:GetEffectiveScale()) or 1, tonumber(UIParent:GetEffectiveScale()) or 1
		local cx, top, bottom = tonumber((self:GetCenter())), tonumber(self:GetTop()), tonumber(self:GetBottom())
		if not (cx and top and bottom and P.db) then return end
		local k = s / us
		local H = tonumber(UIParent:GetHeight()) or 1080
		local x = cx * k - (tonumber(UIParent:GetWidth()) or 1920) / 2
		-- in the bottom half it's kept by its bottom (the stack grows up), else by its top
		local p, y = "BOTTOM", bottom * k
		if (top + bottom) / 2 * k > H / 2 then p, y = "TOP", top * k - H end
		-- the spot is where the first one in the stack would sit
		local dir = p == "BOTTOM" and 1 or -1
		for _, o in ipairs(popStack) do
			if o == self then break end
			if o:IsShown() then y = y - dir * ((tonumber(o:GetHeight()) or 0) * (tonumber(o:GetEffectiveScale()) or 1) / us + 8) end
		end
		P.db.pos.popups = { p, x, y }
		P:PopupLayout()
	end)
end
-- the older name: every pop-up now shares the one spot
function P:PinnedSpot(f) P:PopupFrame(f) end
-- choosing a spot in settings or setup puts them there (a dragged spot gives way)
local lastSpot
P:Listen("SETTINGS_CHANGED", function()
	local v = P.db and P.db.settings.popupSpot
	if lastSpot and v ~= lastSpot then P.db.pos.popups = nil; P:PopupLayout() end
	lastSpot = v
end)
P:Listen("READY", function() lastSpot = P.db.settings.popupSpot end)
-- spots each pop-up kept on its own before: the shared one does it now
P:Listen("READY", function() P.db.pos.prompt, P.db.pos.campfire = nil, nil end)

-- Windows stay where you put them: once setup has placed them, Shift-drag
-- moves one (Settings > Home turns the lock off). While placing, anything goes.
function P:CanDrag(protected)
	if protected and InCombatLockdown() then return false end
	if P.placing then return true end
	if not (P.db and P.db.settings.lockWindows) then return true end
	return IsShiftKeyDown()
end

function P:ResetWindows()
	if not self.db then return end
	wipe(self.db.pos); self.db.winScale = nil
	self:ApplySizes()
	for key in pairs(DEFAULT_POS) do
		local f = _G[key == "arrow" and "PathwayArrow" or key]
		if f and not (InCombatLockdown() and f:IsProtected()) then self:PlaceAt(f, key) end
	end
	self:Toast("Windows are back where they started")
end
local hint
function P:ShowScaleHint(f, v)
	if not hint then
		hint = UIParent:CreateFontString(nil, "OVERLAY"); hint:SetFontObject(P.fonts.title)
	end
	hint:ClearAllPoints(); hint:SetPoint("BOTTOM", f, "TOP", 0, 4)
	hint:SetText(("%d%%"):format(math.floor(v * 100 + 0.5)))
	hint:Show(); hint:SetAlpha(1)
	C_Timer.After(1.2, function() if hint then hint:Hide() end end)
end

local retry, tries = false, 0
function P:ApplySizes()
	local s = self.db and self.db.settings
	if not s then return end
	local k = self:UIScale()
	local waiting
	for name, own in pairs(SIZED) do
		local f = _G[name]
		if f and f.SetScale and not (InCombatLockdown() and f.IsProtected and f:IsProtected()) then
			f:SetScale(k * ((type(own) == "string" and s[own]) or 1) * WinScale(name))
			Adjustable(f, name)
			if not f.pwAdjust and not NO_WHEEL[name] then waiting = true end
		end
	end
	-- a window still turning its mouse on: look again in a moment
	if waiting and not retry and tries < 20 then
		retry, tries = true, tries + 1
		C_Timer.After(0.5, function() retry = false; P:ApplySizes() end)
	end
end
P:On("UI_SCALE_CHANGED", function() P:ApplySizes() end)
P:On("DISPLAY_SIZE_CHANGED", function() P:ApplySizes() end)

function P:ApplyTheme()
	local s = self.db and self.db.settings
	if not s then return end
	local ac = s.accent or A
	A[1], A[2], A[3] = ac[1], ac[2], ac[3]
	self.ACCENT_HEX = ("ff%02x%02x%02x"):format(floor(A[1] * 255 + 0.5), floor(A[2] * 255 + 0.5), floor(A[3] * 255 + 0.5))
	self.TITLE = "|c" .. self.ACCENT_HEX .. "Path|rway"
	-- one opacity for every Pathway window: solid at 100%, see-through below.
	-- Panels inside a window follow it, so the game shows through the whole window.
	local op = max(0, min(1, s.bgAlpha or 0.95))
	P.opacity = op
	fill(BG, 0.035, 0.04, 0.05, op)
	fill(PANEL, 0.1, 0.11, 0.13, op >= 1 and 1 or op * 0.9)
	fill(ACCENT_BG, A[1] * 0.22, A[2] * 0.22, A[3] * 0.22, 1)
	fill(ACCENT_EDGE, A[1], A[2], A[3], 0.7)
	for f in pairs(painted) do Paint(f) end
	self:RepaintCards()
	local bump = ({ small = -1, normal = 0, large = 1.5 })[s.fontSize or "normal"] or 0
	for _, e in ipairs(fontList) do e[1]:SetFont(STANDARD_TEXT_FONT, e[2] + bump, e[3]) end
	for _, fn in ipairs(paintHooks) do fn() end
	self:ApplySizes()
end

-- put a window at its usual spot, then slide it left past any of these that it would cover
function P:PlaceBeside(w, names, default)
	if InCombatLockdown() and w:IsProtected() then return end
	w:ClearAllPoints()
	w:SetPoint(default[1], UIParent, default[2], default[3], default[4])
	local s = w:GetEffectiveScale()
	local wl, wb, ww, wh = w:GetRect()
	if not wl then return end
	wl, wb, ww, wh = wl * s, wb * s, ww * s, wh * s
	local shift = 0
	for _, name in ipairs(names) do
		local o = _G[name]
		if o and o:IsShown() and o ~= w then
			local os = o:GetEffectiveScale()
			local ol, ob, ow, oh = o:GetRect()
			if ol then
				ol, ob, ow, oh = ol * os, ob * os, ow * os, oh * os
				local right = wl + ww - shift
				if wl - shift < ol + ow and right > ol and wb < ob + oh and wb + wh > ob then
					shift = shift + (right - ol) + 8 * s
				end
			end
		end
	end
	if shift > 0 then
		w:ClearAllPoints()
		w:SetPoint(default[1], UIParent, default[2], default[3] - shift / s, default[4])
	end
end

function P:FlatButton(parent, label, accent)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetHeight(20)
	b.text = b:CreateFontString(nil, "OVERLAY")
	b.text:SetFontObject(P.fonts.button)
	b.text:SetPoint("CENTER")
	b.edge = accent and ACCENT_EDGE or EDGE
	P.Flat(b, accent and ACCENT_BG or PANEL, b.edge)
	b:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(A[1], A[2], A[3], 1)
		if self.tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(self.edge)); GameTooltip:Hide() end)
	function b:SetLabel(t) self.text:SetText(t); self:SetWidth(max(self.minW or 0, self.text:GetStringWidth() + 18)) end
	b:SetLabel(label or "")
	return b
end

function P:CloseButton(parent, onClick)
	local c = CreateFrame("Button", nil, parent)
	c:SetSize(20, 20)
	c.t = c:CreateFontString(nil, "OVERLAY"); c.t:SetFontObject(P.fonts.title); c.t:SetPoint("CENTER"); c.t:SetText("×")
	c.t:SetTextColor(0.6, 0.65, 0.7)
	c:SetScript("OnEnter", function(s)
		s.t:SetTextColor(1, 0.45, 0.45)
		if s.tip then GameTooltip:SetOwner(s, "ANCHOR_TOP"); GameTooltip:SetText(s.tip, 1, 1, 1, 1, true); GameTooltip:Show() end
	end)
	c:SetScript("OnLeave", function(s) s.t:SetTextColor(0.6, 0.65, 0.7); if s.tip then GameTooltip:Hide() end end)
	c:SetScript("OnClick", onClick)
	return c
end

---------------------------------------------------------------------------
-- Toast
---------------------------------------------------------------------------
local toast
function P:Toast(msg)
	if not toast then
		toast = CreateFrame("Frame", "PathwayToast", UIParent, "BackdropTemplate")
		if P.ApplySizes then P:ApplySizes() end
		P.Flat(toast, BG, ACCENT_EDGE)
		toast:SetFrameStrata("DIALOG")
		toast:SetHeight(26)
		toast:SetPoint("TOP", UIParent, "TOP", 0, -150)
		toast.text = toast:CreateFontString(nil, "OVERLAY")
		toast.text:SetFontObject(P.fonts.button)
		toast.text:SetPoint("CENTER")
		local ag = toast:CreateAnimationGroup()
		local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.15); a1:SetOrder(1)
		local a2 = ag:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.45); a2:SetStartDelay(2.2); a2:SetOrder(2)
		ag:SetScript("OnFinished", function() toast:Hide() end)
		toast.anim = ag
	end
	toast.text:SetText(msg)
	toast:SetWidth(toast.text:GetStringWidth() + 28)
	toast:SetAlpha(0)
	toast:Show()
	toast.anim:Stop(); toast.anim:Play()
end

---------------------------------------------------------------------------
-- Prompt cards: one question at a time, queued, never in your face in combat
--   P:Ask{ key=, icon=, title=, text=, buttons = { {label, fn, accent, "link"?}, ... }, item = link }
--   (a button marked "link" is a quiet text link on the left: "Never ask")
---------------------------------------------------------------------------
local card, queue, shownKey = nil, {}, nil

local function BuildCard()
	card = CreateFrame("Frame", "PathwayPrompt", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	P.Flat(card, BG, ACCENT_EDGE)
	card:SetFrameStrata("DIALOG")
	card:SetSize(370, 96)
	card:SetClampedToScreen(true)
	-- the pop-up spot (above the magic button unless you chose or dragged elsewhere)
	P:PopupFrame(card)
	card:Hide()

	local bar = card:CreateTexture(nil, "ARTWORK")
	bar:SetPoint("TOPLEFT", 1, -1); bar:SetPoint("BOTTOMLEFT", 1, 1); bar:SetWidth(3)
	card.bar = bar

	card.icon = card:CreateTexture(nil, "ARTWORK")
	card.icon:SetSize(34, 34); card.icon:SetPoint("TOPLEFT", 14, -12)
	card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	card.iconBtn = CreateFrame("Button", nil, card)
	card.iconBtn:SetAllPoints(card.icon)
	card.iconBtn:SetScript("OnEnter", function(self)
		if card.item then GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetHyperlink(card.item); GameTooltip:Show() end
	end)
	card.iconBtn:SetScript("OnLeave", GameTooltip_Hide)

	card.title = card:CreateFontString(nil, "OVERLAY")
	card.title:SetFontObject(P.fonts.title)
	card.title:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, 0)
	card.title:SetJustifyH("LEFT"); card.title:SetWordWrap(false)
	card.text = card:CreateFontString(nil, "OVERLAY")
	card.text:SetFontObject(P.fonts.button)
	card.text:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -5)
	card.text:SetJustifyH("LEFT"); card.text:SetSpacing(2)

	card.close = P:CloseButton(card, function() P:AnswerPrompt(nil) end)
	card.close:SetPoint("TOPRIGHT", -4, -4)
	card.buttons = {}

	P:OnPaint(function() bar:SetColorTexture(A[1], A[2], A[3], 1) end)
	bar:SetColorTexture(A[1], A[2], A[3], 1)
end

-- The card fits what it holds: wide enough for its buttons (up to a limit, then
-- they take a second row), tall enough for its text at that width. "Never ask" and
-- the like are a quiet link on the left, not one more button.
local CARD_MIN, CARD_MAX, PAD, GAP = 370, 520, 12, 6
local TEXT_LEFT = 14 + 34 + 10                    -- the icon and its margin
local function Show(entry)
	if not card then BuildCard() end
	shownKey = entry.key
	card.entry = entry
	card.item = entry.item
	card.icon:SetTexture(entry.icon or 134400)
	card.title:SetText(entry.title or "")
	card.text:SetText(entry.text or "")
	for _, b in ipairs(card.buttons) do b:Hide() end
	if card.link then card.link:Hide() end
	-- the buttons and the quiet link, measured first
	local btns, link = {}, nil
	for _, def in ipairs(entry.buttons) do
		if def[4] == "link" then link = def
		else
			local n = #btns + 1
			local b = card.buttons[n]
			if not b then b = P:FlatButton(card, "", false); card.buttons[n] = b end
			b.edge = def[3] and ACCENT_EDGE or EDGE
			P.Flat(b, def[3] and ACCENT_BG or PANEL, b.edge)
			b.minW = 64
			b:SetLabel(def[1])
			b:SetScript("OnClick", function() P:AnswerPrompt(def[2]) end)
			btns[#btns + 1] = b
		end
	end
	local linkW = 0
	if link then
		if not card.link then
			local l = CreateFrame("Button", nil, card)
			l:SetHeight(20)
			l.t = l:CreateFontString(nil, "OVERLAY"); l.t:SetFontObject(P.fonts.button); l.t:SetPoint("LEFT")
			l:SetScript("OnEnter", function(self) self.t:SetTextColor(1, 0.55, 0.5) end)
			l:SetScript("OnLeave", function(self) self.t:SetTextColor(0.5, 0.53, 0.57) end)
			card.link = l
		end
		card.link.t:SetText(link[1]); card.link.t:SetTextColor(0.5, 0.53, 0.57)
		card.link:SetWidth(card.link.t:GetStringWidth() + 4)
		card.link:SetScript("OnClick", function() P:AnswerPrompt(link[2]) end)
		linkW = card.link:GetWidth() + 16
	end
	local rowW = 0
	for _, b in ipairs(btns) do rowW = rowW + b:GetWidth() + GAP end
	rowW = max(0, rowW - GAP)
	local W = math.min(CARD_MAX, max(CARD_MIN, PAD * 2 + linkW + rowW))
	card:SetWidth(W)
	-- the buttons, right to left; a second row when one won't hold them
	local room = W - PAD * 2 - linkW
	local rows, x, prev = 1, 0, nil
	for i = #btns, 1, -1 do
		local b = btns[i]
		b:ClearAllPoints()
		if prev and x + GAP + b:GetWidth() > room then
			rows, x, prev = rows + 1, 0, nil
			room = W - PAD * 2
		end
		if prev then b:SetPoint("RIGHT", prev, "LEFT", -GAP, 0); x = x + GAP + b:GetWidth()
		else b:SetPoint("BOTTOMRIGHT", -PAD, 10 + (rows - 1) * 26); x = b:GetWidth() end
		b:Show()
		prev = b
	end
	if link then card.link:ClearAllPoints(); card.link:SetPoint("BOTTOMLEFT", PAD + 2, 10); card.link:Show() end
	-- the text at its real width, so its height is right
	card.text:SetWidth(W - TEXT_LEFT - 14)
	card.title:SetWidth(W - TEXT_LEFT - 28)
	local textH = card.text:GetStringHeight()
	card:SetHeight(max(96, 12 + 16 + 5 + textH + 14 + rows * 26 + 4))
	card:Show()
	P:PopupLayout()
	if P.db.settings.sound then PlaySound(SOUNDKIT.IG_MAINMENU_OPEN or 850) end
end

local function Next()
	shownKey = nil
	if card then card:Hide() end
	if InCombatLockdown() then return end
	local e = tremove(queue, 1)
	if e then Show(e) end
end

function P:Ask(entry)
	if entry.key then
		if shownKey == entry.key then return end
		for _, q in ipairs(queue) do if q.key == entry.key then return end end
	end
	if card and card:IsShown() or InCombatLockdown() then tinsert(queue, entry) else Show(entry) end
end

function P:AnswerPrompt(fn)
	if fn then
		local ok = fn()
		if ok == false then return end        -- the action asked to keep the card open
	end
	Next()
end

function P:DismissPrompt(key)
	for i = #queue, 1, -1 do if queue[i].key == key then tremove(queue, i) end end
	if shownKey == key then Next() end
end

P:On("PLAYER_REGEN_ENABLED", function() if not (card and card:IsShown()) then Next() end end)
P:On("PLAYER_REGEN_DISABLED", function()
	-- step aside in combat; the question comes back when the fight is over
	if card and card:IsShown() and card.entry then tinsert(queue, 1, card.entry); shownKey = nil; card:Hide() end
end)

---------------------------------------------------------------------------
-- A small context menu with the same builder calls as Blizzard's MenuUtil,
-- for clients that don't have it. Submenus open in place when clicked.
---------------------------------------------------------------------------
local Node = {}
Node.__index = Node
local function NewNode() return setmetatable({ items = {} }, Node) end
function Node:CreateTitle(text) self.items[#self.items + 1] = { kind = "title", text = text }; return self end
function Node:CreateDivider() self.items[#self.items + 1] = { kind = "div" } end
function Node:CreateButton(text, fn)
	local child = NewNode()
	self.items[#self.items + 1] = { kind = "button", text = text, fn = fn, node = child }
	return child
end
function Node:CreateCheckbox(text, get, set) self.items[#self.items + 1] = { kind = "check", text = text, get = get, set = set } end
function Node:CreateRadio(text, get, set, value)
	self.items[#self.items + 1] = { kind = "radio", text = text, get = function() return get(value) end, set = function() set(value) end }
end

local menuFrame, menuRows, menuRoot, menuOpen = nil, {}, nil, {}
local function RenderMenu()
	local rows, y, width = 0, -4, 140
	local function row()
		rows = rows + 1
		local b = menuRows[rows]
		if not b then
			b = CreateFrame("Button", nil, menuFrame)
			b:SetHeight(18)
			b.text = b:CreateFontString(nil, "OVERLAY"); b.text:SetFontObject(P.fonts.button); b.text:SetPoint("LEFT", 8, 0)
			b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.06)
			b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetHeight(1); b.line:SetColorTexture(1, 1, 1, 0.08)
			b.line:SetPoint("LEFT", 6, 0); b.line:SetPoint("RIGHT", -6, 0)
			menuRows[rows] = b
		end
		b:ClearAllPoints(); b:SetPoint("TOPLEFT", 4, y); b:SetPoint("RIGHT", -4, 0)
		b:Show(); b.line:Hide(); b:EnableMouse(true); b.hl:Show()
		return b
	end
	local function walk(node, depth)
		for _, it in ipairs(node.items) do
			local b = row()
			local pad = ("    "):rep(depth)
			if it.kind == "div" then
				b:SetHeight(8); b.text:SetText(""); b.line:Show(); b:EnableMouse(false); b.hl:Hide(); y = y - 8
			else
				b:SetHeight(18); y = y - 18
				if it.kind == "title" then
					b.text:SetText(pad .. P.DIM .. it.text .. "|r"); b:EnableMouse(false); b.hl:Hide()
				elseif it.kind == "button" then
					local hasKids = #it.node.items > 0
					b.text:SetText(pad .. it.text .. (hasKids and (menuOpen[it] and "  " .. P.DIM .. "-|r" or "  " .. P.DIM .. "+|r") or ""))
					b:SetScript("OnClick", function()
						if hasKids then menuOpen[it] = not menuOpen[it]; RenderMenu() else menuFrame:Hide(); if it.fn then it.fn() end end
					end)
				else
					local on = it.get()
					local mark = on and "|TInterface\\Buttons\\UI-CheckBox-Check:14:14|t" or "|TInterface\\Buttons\\UI-CheckBox-Up:14:14|t"
					b.text:SetText(pad .. mark .. it.text)
					b:SetScript("OnClick", function() it.set(); RenderMenu() end)
				end
				width = math.max(width, b.text:GetStringWidth() + 24)
			end
			if it.kind == "button" and menuOpen[it] then walk(it.node, depth + 1) end
		end
	end
	walk(menuRoot, 0)
	for i = rows + 1, #menuRows do menuRows[i]:Hide() end
	menuFrame:SetSize(width, -y + 4)
end

P.MiniMenu = {
	CreateContextMenu = function(owner, generator)
		if not menuFrame then
			menuFrame = CreateFrame("Frame", "PathwayMenu", UIParent, "BackdropTemplate")
			P.Flat(menuFrame, BG, EDGE)
			menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			menuFrame:SetClampedToScreen(true)
			menuFrame:EnableMouse(true)
			tinsert(UISpecialFrames, "PathwayMenu")
		end
		menuRoot = NewNode()
		wipe(menuOpen)
		generator(owner, menuRoot)
		menuFrame:ClearAllPoints()
		menuFrame:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
		RenderMenu()
		menuFrame:Show()
	end,
}
end part() end
-- ==================== Notify.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Notifications
     Everything Pathway told you lately, in one place: the bell beside your
     minimap (under the holiday button on Pathway's minimap). Upgrades wait there with an Equip
     button until they're on (or gone), so a prompt you clicked away isn't lost.
     A number on the bell counts what you haven't seen. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local floor, max, min, time = math.floor, math.max, math.min, time
local tinsert, tremove = table.insert, table.remove

local MAX_KEEP, ROWS = 30, 8
local notes, unread = {}, 0
P.notes = notes

local panel, rows = nil, {}

local function Ago(t)
	local d = time() - t
	if d < 60 then return "now" end
	if d < 3600 then return floor(d / 60) .. "m" end
	return floor(d / 3600) .. "h"
end

function P:NotesChanged()
	local b = _G.PathwayNotesButton
	if b and b.badge then
		b.badge:SetShown(unread > 0)
		b.badgeText:SetText(unread > 9 and "9+" or unread)
		b.badgeText:SetShown(unread > 0)
	end
	if b and b.def and b.def.show then
		local want = P.db and P.db.settings.minimapButtons ~= false and b.def.show() and true or false
		if want ~= b:IsShown() then b:SetShown(want); if want and P.PlaceNotesButton then P:PlaceNotesButton() end end
	end
	if panel and panel:IsShown() then P:RenderNotes() end
end

-- e = { text, sub, icon, item, key, kind, action = { label, fn } }
function P:Notify(e)
	if not e or not e.text then return end
	if e.key then
		for i = #notes, 1, -1 do if notes[i].key == e.key then tremove(notes, i) end end
	end
	e.t = time()
	tinsert(notes, 1, e)
	while #notes > MAX_KEEP do tremove(notes) end
	if not (panel and panel:IsShown()) then unread = unread + 1 end
	self:NotesChanged()
end

function P:ClearNote(key)
	for i = #notes, 1, -1 do if notes[i].key == key then tremove(notes, i) end end
	self:NotesChanged()
end

-- A toast is a moment: "You're there", "Fly to Thor", "Guide and arrow on". Only the ones
-- worth coming back to (a level, an upgrade, a full quest log) also land in the list:
-- P:Toast(msg, true). Guide steps never do; the guide already shows them.
local Toast = P.Toast
function P:Toast(msg, keep)
	Toast(self, msg)
	if keep ~= true then return end
	local last = notes[1]
	if last and last.text == msg and time() - last.t < 30 then return end
	self:Notify({ text = msg, kind = "info" })
end

-- an upgrade that's no longer in your bags leaves the list
P:On("BAG_UPDATE_DELAYED", function()
	local changed
	for i = #notes, 1, -1 do
		local n = notes[i]
		if n.kind == "gear" and n.item and P.GearInBags and not P:GearInBags(n.item) then tremove(notes, i); changed = true end
	end
	if changed then P:NotesChanged() end
end)

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
local function Row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, panel)
	r:SetHeight(38)
	r:SetPoint("TOPLEFT", 8, -32 - (i - 1) * 40)
	r:SetPoint("RIGHT", -8, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.04)
	r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(28, 28); r.icon:SetPoint("LEFT", 2, 0)
	r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	r.text = r:CreateFontString(nil, "OVERLAY"); r.text:SetFontObject(P.fonts.button)
	r.text:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1); r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
	r.sub = r:CreateFontString(nil, "OVERLAY"); r.sub:SetFontObject(P.fonts.button)
	r.sub:SetPoint("TOPLEFT", r.text, "BOTTOMLEFT", 0, -3); r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
	r.ago = r:CreateFontString(nil, "OVERLAY"); r.ago:SetFontObject(P.fonts.head); r.ago:SetPoint("TOPRIGHT", -2, -3)
	r.btn = P:FlatButton(r, "", true); r.btn.minW = 58
	r.btn:SetPoint("BOTTOMRIGHT", -2, 3)
	r:SetScript("OnEnter", function(self)
		if self.note and self.note.item then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetHyperlink(self.note.item); GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", GameTooltip_Hide)
	rows[i] = r
	return r
end

function P:RenderNotes()
	local shown = 0
	for i = 1, ROWS do
		local n, r = notes[i], Row(i)
		if n then
			shown = i
			r.note = n
			r.icon:SetTexture(n.icon or (P.MEDIA .. "Icon"))
			r.text:SetText(n.text)
			r.sub:SetText(n.sub or "")
			r.sub:SetShown(n.sub ~= nil)
			r.ago:SetText(P.DIM .. Ago(n.t) .. "|r")
			local act = n.action
			r.btn:SetShown(act ~= nil)
			r.text:SetPoint("RIGHT", r, "RIGHT", -34, 0)
			r.sub:SetPoint("RIGHT", r, "RIGHT", act and -66 or -4, 0)
			if act then
				r.btn:SetLabel(act[1])
				r.btn:SetScript("OnClick", function()
					if act[2]() ~= false and n.key then P:ClearNote(n.key) end
				end)
			end
			r:Show()
		else
			r:Hide()
		end
	end
	panel.empty:SetShown(shown == 0)
	panel:SetHeight(32 + max(1, shown) * 40 + 8)
end

local function BuildPanel()
	panel = CreateFrame("Frame", "PathwayNotes", UIParent, "BackdropTemplate")
	P.Flat(panel, nil, nil, true)
	panel:SetFrameStrata("DIALOG")
	panel:SetWidth(330)
	panel:SetClampedToScreen(true)
	panel:EnableMouse(true)
	panel.title = panel:CreateFontString(nil, "OVERLAY"); panel.title:SetFontObject(P.fonts.title)
	panel.title:SetPoint("TOPLEFT", 12, -10); panel.title:SetText("Recent")
	panel.close = P:CloseButton(panel, function() panel:Hide() end); panel.close:SetPoint("TOPRIGHT", -4, -4)
	local clear = CreateFrame("Button", nil, panel)
	clear:SetSize(60, 18); clear:SetPoint("RIGHT", panel.close, "LEFT", -4, 0)
	clear.t = clear:CreateFontString(nil, "OVERLAY"); clear.t:SetFontObject(P.fonts.head); clear.t:SetPoint("RIGHT")
	clear.t:SetText("Clear all")
	clear:SetScript("OnEnter", function(s) s.t:SetTextColor(1, 1, 1) end)
	clear:SetScript("OnLeave", function(s) s.t:SetTextColor(0.6, 0.65, 0.71) end)
	clear:SetScript("OnClick", function() wipe(notes); P:NotesChanged() end)
	panel.empty = panel:CreateFontString(nil, "OVERLAY"); panel.empty:SetFontObject(P.fonts.button)
	panel.empty:SetPoint("TOPLEFT", 14, -40); panel.empty:SetText(P.DIM .. "Nothing new.|r")
	-- close when you click anywhere else
	panel:SetScript("OnShow", function() panel:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
	panel:SetScript("OnHide", function() panel:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
	panel:SetScript("OnEvent", function()
		if not (panel:IsMouseOver() or (_G.PathwayNotesButton and _G.PathwayNotesButton:IsMouseOver())) then panel:Hide() end
	end)
	panel:Hide()
	if P.ApplySizes then P:ApplySizes() end
end

function P:ToggleNotes(owner)
	if not panel then BuildPanel() end
	if panel:IsShown() then panel:Hide() return end
	unread = 0
	panel:ClearAllPoints()
	if owner then
		local _, y = owner:GetCenter()
		local up = y and y < UIParent:GetHeight() / 2
		panel:SetPoint(up and "BOTTOMRIGHT" or "TOPRIGHT", owner, up and "TOPRIGHT" or "BOTTOMRIGHT", 0, up and 4 or -4)
	else
		panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -240)
	end
	panel:Show()
	self:RenderNotes()
	self:NotesChanged()
end
end part() end
-- ==================== Engine.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Engine
     Which quests suit you right now, where everything is, and the routes the
     arrow follows. A route is an ordered list of stops:
       · an NPC/object stop: turn in what's done here, pick up what's offered
       · an objective stop: go where the mobs, objects or drops for one objective are
     Stops close themselves as the quest log changes, and when a route runs out
     Pathway can start the next nearby set on its own. ]]

local ADDON, P = __addon, __ns
local K = P.K
local Unpack = P.Unpack
local pairs, ipairs, wipe, tinsert, tremove, sort = pairs, ipairs, wipe, table.insert, table.remove, table.sort
local floor, max, min, sqrt = math.floor, math.max, math.min, math.sqrt
local EMPTY = {}

local function S() return P.db.settings end

---------------------------------------------------------------------------
-- Indexes: who starts and who ends which quest
---------------------------------------------------------------------------
-- Kept by number underneath (no string made per entry), and built the first time
-- something asks rather than at every login or /reload. P.startsBy["N123"] and
-- P.endsBy["O45"] still read as before: looked up once, then remembered.
local SN, SO, EN, EO = {}, {}, {}, {}
local indexed = false
local once = false                                -- a learned quest: never listed twice
local function Add(t, id, qid)
	local l = t[id]
	if not l then l = {}; t[id] = l end
	if once then for i = 1, #l do if l[i] == qid then return end end end
	l[#l + 1] = qid
end
local function IndexOne(qid, q)
	local l = q[K.SN]; if l then for i = 1, #l do Add(SN, l[i], qid) end end
	l = q[K.SO]; if l then for i = 1, #l do Add(SO, l[i], qid) end end
	l = q[K.EN]; if l then for i = 1, #l do Add(EN, l[i], qid) end end
	l = q[K.EO]; if l then for i = 1, #l do Add(EO, l[i], qid) end end
end
local function BuildIndex()
	indexed = true
	for qid, q in pairs(P.Q) do IndexOne(qid, q) end
end
local function Lookup(npcs, objs)
	return setmetatable({}, { __index = function(t, key)
		if type(key) ~= "string" then return nil end
		if not indexed then BuildIndex() end
		local c, id = key:byte(1), tonumber(key:sub(2))
		local src = id and (c == 78 and npcs or c == 79 and objs) or nil      -- N, O
		local l = src and src[id] or false
		rawset(t, key, l)
		return l
	end })
end
P.startsBy, P.endsBy = Lookup(SN, SO), Lookup(EN, EO)
-- a quest added or changed after the index is built (learned in play)
function P:IndexQuest(qid, q)
	if not indexed then return end                -- the build will take it in
	once = true; IndexOne(qid, q); once = false
	for _, f in ipairs({ { K.SN, "N", P.startsBy }, { K.SO, "O", P.startsBy }, { K.EN, "N", P.endsBy }, { K.EO, "O", P.endsBy } }) do
		for _, id in ipairs(q[f[1]] or EMPTY) do rawset(f[3], f[2] .. id, nil) end
	end
end

---------------------------------------------------------------------------
-- Is this quest one you can and should pick up now?
---------------------------------------------------------------------------
-- a quest this many levels below you is gray, the way the game's own colors say it
local function GrayAtOrBelow(level)
	local range = UnitQuestTrivialLevelRange and UnitQuestTrivialLevelRange("player")
	if type(range) == "number" then return level - range - 1 end
	if level <= 5 then return 0 end
	if level <= 39 then return level - 5 - floor(level / 10) end
	return level - 1 - floor(level / 5)
end
P.GrayAtOrBelow = GrayAtOrBelow

-- quest categories that only run during world events and holidays
local HOLIDAY = { [-22] = true, [-364] = true, [-365] = true, [-366] = true, [-368] = true, [-369] = true,
	[-370] = true, [-376] = true, [-1002] = true, [-1003] = true, [-1005] = true }

local function RaceOK(race)
	if not race then return true end
	local me = P.me
	if race == "A" then return me.faction == "Alliance" end
	if race == "H" then return me.faction == "Horde" end
	for _, r in ipairs(race) do if r == me.race then return true end end
	return false
end

local function ClassOK(mask)
	if not mask or mask == 0 or not P.me.class then return true end
	return bit.band(mask, 2 ^ (P.me.class - 1)) ~= 0
end

-- a quest filed under a class (its log category) is that class's, even when
-- the data has no class on it
local SORT_CLASS = { [-81] = 1, [-141] = 2, [-261] = 3, [-162] = 4, [-262] = 5, [-82] = 7, [-161] = 8, [-61] = 9, [-263] = 11 }
local function SortOK(sort)
	local c = sort and SORT_CLASS[sort]
	return not c or not P.me.class or c == P.me.class
end

-- "Special" hand-ins: a book or item you found, brought to a librarian or a
-- collector. You can only take them with the item in your bags.
local function HandInOK(q)
	if q[K.SORT] ~= -284 then return true end
	-- nothing to do and nothing said: a reputation or collection hand-in
	if not (q[K.ON] or q[K.OO] or q[K.OI]) and not (q[K.TEXT] and q[K.TEXT] ~= "") then return false end
	local items = q[K.OI]
	if not items or #items == 0 or (q[K.ON] and #q[K.ON] > 0) or (q[K.OO] and #q[K.OO] > 0) then return true end
	local count = (C_Item and C_Item.GetItemCount) or GetItemCount
	for _, id in ipairs(items) do if count and (count(id) or 0) > 0 then return true end end
	return false
end

-- an NPC who only talks to the other faction (the same quest giver often
-- stands in Stormwind and in Undercity) is never a stop for you
local function MyLetter() return (P.me and P.me.faction == "Horde") and "H" or "A" end
function P:FriendlyTo(kind, id)
	if kind ~= "N" then return true end
	local e = self:Entity("N", id)
	local f = e and e[4]
	return not (type(f) == "string" and f ~= "" and not f:find(MyLetter(), 1, true))
end

local function HasLocation(kind, ids)
	for _, id in ipairs(ids or EMPTY) do
		local e = P:Entity(kind, id)
		if e and e[2] and (not e[3] or S().dungeonQuests) and P:FriendlyTo(kind, id) then return true end
	end
	return false
end

-- a quest this character could ever do (race, class, not a holiday)
function P:ForMe(qid)
	local q = self.Q[qid]
	if not q then return false end
	if q[K.SORT] and HOLIDAY[q[K.SORT]] then return false end
	if bit.band(q[K.FLAGS] or 0, 1) ~= 0 and not S().repeatable then return false end
	return RaceOK(q[K.RACE]) and ClassOK(q[K.CLS]) and SortOK(q[K.SORT])
end

-- done | ready | active | available | low | high | locked | elsewhere
local REASON = { level = "high", ["too hard"] = "high", gray = "low", ["no location"] = "elsewhere", profession = "locked" }
function P:QuestStatus(qid)
	if self.done[qid] then return "done" end
	local e = self.log[qid]
	if e then return e.complete and "ready" or "active" end
	local ok, why = self:Available(qid)
	if ok then return "available" end
	return REASON[why] or "locked", why
end

-- reason is returned for debugging (/pw why <questID>)
function P:Available(qid)
	local q = self.Q[qid]
	if not q then return false, "unknown" end
	if self.done[qid] then return false, "done" end
	if self.log[qid] then return false, "in log" end
	local s, lvl = S(), self.me.level or 1
	local flags = q[K.FLAGS] or 0
	if bit.band(flags, 1) ~= 0 and not s.repeatable then return false, "repeatable" end
	if q[K.SORT] and HOLIDAY[q[K.SORT]] then return false, "holiday" end
	if not RaceOK(q[K.RACE]) then return false, "race" end
	if not ClassOK(q[K.CLS]) or not SortOK(q[K.SORT]) then return false, "class" end
	if not HandInOK(q) then return false, "needs the item" end
	if (q[K.REQ] or 0) > lvl then return false, "level" end
	if q[K.MAX] and lvl > q[K.MAX] then return false, "too high" end
	local ql = q[K.LVL] or 0
	if ql > 0 then
		-- (a few quests are meant for anyone past their level, whatever theirs says: P.ANY_LEVEL)
		if ql > lvl + s.aheadLevels and not (P.ANY_LEVEL and P.ANY_LEVEL[qid]) then return false, "too hard" end
		if not s.showLow and ql <= GrayAtOrBelow(lvl) then return false, "gray" end
	end
	if q[K.SKILL] then return false, "profession" end
	if self.cdb and self.cdb.notOffered and self.cdb.notOffered[qid] then return false, "not offered" end
	if self:Marked("quests", qid) then return false, "marked done" end
	if self:Hidden(qid) then return false, "left out" end
	if s.skipElite and self:QuestElite(qid) then return false, "elite" end
	for _, id in ipairs(q[K.PRE] or EMPTY) do if not self.done[id] then return false, "needs " .. id end end
	local pa = q[K.PREANY]
	if pa then
		local ok = false
		for _, id in ipairs(pa) do if self.done[id] then ok = true; break end end
		if not ok then return false, "needs one of " .. table.concat(pa, ",") end
	end
	for _, id in ipairs(q[K.EXCL] or EMPTY) do if self.done[id] or self.log[id] then return false, "excluded by " .. id end end
	local nx = q[K.NEXT]
	if nx and (self.done[nx] or self.log[nx]) then return false, "chain moved on" end
	if q[K.PARENT] and not self.log[q[K.PARENT]] then return false, "needs parent" end
	local crumb = q[K.CRUMB]
	if crumb and (self.done[crumb] or self.log[crumb]) then return false, "breadcrumb not needed" end
	if not HasLocation("N", q[K.SN]) and not HasLocation("O", q[K.SO]) then return false, "no location" end
	return true
end

-- where a quest in your log takes you next: the zone of its hand-in when it's
-- done, else of its closest objective. Second value: true when it's on another
-- continent (a boat or a flight away)
local whereCache, FAR_YD = {}, 1e6
function P:QuestWhere(qid)
	local c = whereCache[qid]
	if c and GetTime() - c.t < 5 then return c.name, c.far, c.yd end
	local q, e = self.Q[qid], self.log[qid]
	local inst, px, py = self:PlayerPos()
	local map, best2
	if q and e and e.complete then
		local ents = {}
		for _, id in ipairs(q[K.EN] or EMPTY) do ents[#ents + 1] = { "N", id } end
		for _, id in ipairs(q[K.EO] or EMPTY) do ents[#ents + 1] = { "O", id } end
		local d, m = self:Nearest(ents, inst, px, py)
		if not m then d, m = self:Nearest(ents, nil, px, py); d = nil end
		map, best2 = m, d
	elseif q then
		local bestM, bestD
		for _, t in ipairs(self:ObjectiveTargets(qid)) do
			local d, m
			if t.point then m, d = t.point[1], math.huge
			else d, m = self:Nearest(t.ents or EMPTY, nil, px, py) end
			if m and (not bestM or (d or math.huge) < (bestD or math.huge)) then bestM, bestD = m, d end
		end
		map = bestM or q[K.ZONE]
		if bestD and bestD < math.huge then best2 = bestD end
	end
	local name = map and self:MapName(self:ZoneOf(map) or map)
	local t = map and self:MapXform(map)
	local far = inst and t and t[1] ~= inst or false
	-- yards from you (squared distances come back from Nearest); another continent is "far"
	local yd = (not far and best2) and sqrt(best2) or FAR_YD
	whereCache[qid] = { t = GetTime(), name = name, far = far, yd = yd }
	return name, far, yd
end

-- a quest whose targets are all inside a dungeon
local dungeonCache = {}
function P:DungeonQuest(qid)
	local c = dungeonCache[qid]
	if c ~= nil then return c end
	local q = self.Q[qid]
	c = false
	if q then
		local any, inside = false, true
		for _, id in ipairs(q[K.ON] or EMPTY) do local e = self:Entity("N", id); if e then any = true; if not e[3] then inside = false end end end
		for _, id in ipairs(q[K.OO] or EMPTY) do local e = self:Entity("O", id); if e then any = true; if not e[3] then inside = false end end end
		-- items: dropped by (or found on) things that are all inside a dungeon
		for _, iid in ipairs(q[K.OI] or EMPTY) do
			local it = self.I[iid]
			if it then
				for _, id in ipairs(it[2] or EMPTY) do local e = self:Entity("N", id); if e then any = true; if not e[3] then inside = false end end end
				for _, id in ipairs(it[3] or EMPTY) do local e = self:Entity("O", id); if e then any = true; if not e[3] then inside = false end end end
			end
		end
		c = any and inside
	end
	dungeonCache[qid] = c
	return c
end

-- an elite quest you can't take on alone yet: its elites are above your level
-- (or any elite at all, on the fastest route) and you're not in a group
function P:TooHardSolo(qid, fast)
	if IsInGroup and IsInGroup() then return false end
	if self.eliteOK and self.eliteOK[qid] then return false end      -- you met it: it's in, with a warning
	local elite = self:QuestElite(qid)
	if not elite then return false end
	return fast or elite > (self.me.level or 1)
end

-- "I can't get this quest here": the giver doesn't offer it (yet). The guide
-- leaves it until your next level, when it may well be offered.
function P:NotOfferedHere(s)
	s = s or self:Current()
	if not (s and s.key and self.cdb) then return end
	local pick = self:EntityWork(s.key)
	if #pick == 0 then return end
	for _, qid in ipairs(pick) do self.cdb.notOffered[qid] = true end
	self:Toast(#pick == 1 and "Okay: that quest is left out until your next level" or ("Okay: those %d quests are left out until your next level"):format(#pick))
	self:Send("QUESTS_CHANGED")
end

-- The quests this character could ever pick up: right race, class and side,
-- not a holiday or a profession quest, with a giver somewhere. That never
-- changes while you play, so it's worked out once; "what can I pick up now"
-- then only looks at these (a fraction of the whole list).
local candidates, candKey
function P:ResetCandidates() candidates = nil end
local function Candidates()
	local s, me = S(), P.me
	local key = (me.race or "") .. ":" .. (me.class or "") .. ":" .. (me.faction or "") .. ":" .. tostring(s.repeatable) .. ":" .. tostring(s.dungeonQuests)
	if candidates and candKey == key then return candidates end
	candidates, candKey = {}, key
	for qid, q in pairs(P.Q) do
		local flags = q[K.FLAGS] or 0
		if not (bit.band(flags, 1) ~= 0 and not s.repeatable) and not (q[K.SORT] and HOLIDAY[q[K.SORT]])
			and RaceOK(q[K.RACE]) and ClassOK(q[K.CLS]) and SortOK(q[K.SORT]) and not q[K.SKILL]
			and (HasLocation("N", q[K.SN]) or HasLocation("O", q[K.SO])) then
			candidates[#candidates + 1] = qid
		end
	end
	return candidates
end

local availCache
function P:AvailableList()
	if not availCache then
		availCache = {}
		for _, qid in ipairs(Candidates()) do if self:Available(qid) then availCache[#availCache + 1] = qid end end
	end
	return availCache
end

---------------------------------------------------------------------------
-- Spawns and distances
---------------------------------------------------------------------------
-- Object spots you've already walked up to (crates, ore, herbs): skipped for a
-- few minutes so the arrow moves on to the next spot instead of "You're here".
local checked, checkedN = {}, 0
local CHECK_FOR = 300
function P:CheckSpot(map, p)
	if not map or not p then return end
	local m = checked[map]
	if not m then m = {}; checked[map] = m end
	if not m[p] then checkedN = checkedN + 1 end
	m[p] = GetTime() + CHECK_FOR
	P.spotVer = (P.spotVer or 0) + 1
	P:Send("SPOTS_CHANGED")
end
local function Checked(map, p, now)
	local m = checked[map]
	local t = m and m[p]
	if not t then return false end
	if t > now then return true end
	m[p] = nil; checkedN = checkedN - 1
	return false
end
function P:SpotChecked(map, p)
	return checkedN > 0 and p ~= nil and Checked(map, p, GetTime())
end

-- nearest spawn of any entity in `ents` ({{"N",id},...}) to a world point
local function NearestPass(self, ents, inst, px, py, onlyMap, skip, now)
	local bestD, bm, bx, by, bwx, bwy, bent, bp
	local skipped = false
	for _, ent in ipairs(ents) do
		local e = self:Entity(ent[1], ent[2])
		local spawns = e and e[2]
		if spawns then
			local obj = skip and ent[1] == "O"
			for map, pts in pairs(spawns) do
				if not onlyMap or map == onlyMap then
					local t = self:MapXform(map)
					if t and (not inst or t[1] == inst) then
						for i = 1, #pts do
							local p = pts[i]
							if obj and Checked(map, p, now) then
								skipped = true
							else
								local x, y = Unpack(p)
								local wx, wy = t[2] - t[4] * x, t[3] - t[5] * y
								local d = px and ((wx - px) ^ 2 + (wy - py) ^ 2) or 0
								if not bestD or d < bestD then
									bestD, bm, bx, by, bwx, bwy, bent, bp = d, map, x, y, wx, wy, ent, p
									if not px then break end
								end
							end
						end
					end
				end
			end
		end
	end
	return bestD, bm, bx, by, bwx, bwy, bent, bp, skipped
end

function P:Nearest(ents, inst, px, py, onlyMap)
	local skip = checkedN > 0 and px ~= nil
	local now = skip and GetTime()
	local bestD, bm, bx, by, bwx, bwy, bent, bp, skipped = NearestPass(self, ents, inst, px, py, onlyMap, skip, now)
	if not bestD and skipped then             -- every spot checked: start the round again
		bestD, bm, bx, by, bwx, bwy, bent, bp = NearestPass(self, ents, inst, px, py, onlyMap, false)
	end
	if not bestD then return end
	return sqrt(bestD), bm, bx, by, bwx, bwy, bent, bp
end

-- how many spots, and the zone they're in, for the step text
function P:SpotCount(ents)
	local n, zone = 0, nil
	for _, ent in ipairs(ents or EMPTY) do
		local e = self:Entity(ent[1], ent[2])
		for map, pts in pairs(e and e[2] or EMPTY) do
			n = n + #pts
			zone = zone or map
		end
	end
	return n, zone
end

---------------------------------------------------------------------------
-- Objectives: what to go to for each unfinished objective of a quest
---------------------------------------------------------------------------
-- The game's own quest area for a quest ({ map, x, y }), for objectives our
-- data can't place. Your zone first, then the quest's zone, then the game's
-- next waypoint. Asked at most every few seconds per quest.
local areaCache, areaAt = {}, {}
function P:GameArea(qid)
	local now = GetTime()
	if areaAt[qid] and now - areaAt[qid] < 5 then return areaCache[qid] or nil end
	areaAt[qid] = now
	local found
	local QL = C_QuestLog
	if QL and QL.GetQuestsOnMap then
		local q = self.Q[qid]
		local tried = {}
		for _, map in ipairs({ self:PlayerZone() or 0, q and q[K.ZONE] or 0 }) do
			if map ~= 0 and not tried[map] then
				tried[map] = true
				local ok, list = pcall(QL.GetQuestsOnMap, map)
				for _, info in ipairs(ok and list or EMPTY) do
					if info.questID == qid and info.x and info.y and info.x > 0 then found = { map, info.x, info.y } break end
				end
				if found then break end
			end
		end
	end
	if not found and QL and QL.GetNextWaypoint then
		local ok, map, x, y = pcall(QL.GetNextWaypoint, qid)
		if ok and map and x and y and x > 0 then found = { map, x, y } end
	end
	areaCache[qid] = found or false
	return found
end

local function DbObjectives(q)
	local list = {}
	for _, id in ipairs(q[K.ON] or EMPTY) do list[#list + 1] = { kind = "N", id = id, name = P:EntityName("N", id) } end
	for _, id in ipairs(q[K.OO] or EMPTY) do list[#list + 1] = { kind = "O", id = id, name = P:EntityName("O", id) } end
	for _, id in ipairs(q[K.OI] or EMPTY) do
		local it = P.I[id]
		list[#list + 1] = { kind = "I", id = id, name = it and it[1] or "" }
	end
	return list
end

local OBJECTIVE_KIND = { monster = "N", npc = "N", item = "I", object = "O", gameobject = "O" }

local function Targets(o)
	if o.kind ~= "I" then return { { o.kind, o.id } } end
	local it = P.I[o.id]
	local out = {}
	if it then
		for _, id in ipairs(it[2] or EMPTY) do out[#out + 1] = { "N", id } end
		for _, id in ipairs(it[3] or EMPTY) do out[#out + 1] = { "O", id } end
	end
	return out
end

-- { {index=, text=, ents=, point=}, ... } for unfinished objectives we can locate
function P:ObjectiveTargets(qid)
	local q, e = self.Q[qid], self.log[qid]
	if not q or not e or e.complete then return EMPTY end
	local db = DbObjectives(q)
	local used, out = {}, {}
	for j, o in ipairs(e.objectives or EMPTY) do
		if not o.finished then
			local text = (o.text or ""):lower()
			local want = OBJECTIVE_KIND[(o.type or ""):lower()]
			local match
			-- Match the objective text first, but never map an objective to an
			-- unrelated database target merely because both occupy the same index.
			for k, d in ipairs(db) do
				if not used[k] and (not want or d.kind == want) and d.name ~= "" and text:find(d.name:lower(), 1, true) then
					match = k; break
				end
			end
			-- If text doesn't include the target's name, use a type match only
			-- when exactly one unused database target has that type.
			if not match and want then
				local candidate, count
				for k, d in ipairs(db) do
					if not used[k] and d.kind == want then candidate = k; count = (count or 0) + 1 end
				end
				if count == 1 then match = candidate end
			end
			if match then
				used[match] = true
				local ents = Targets(db[match])
				local spots = 0
				for _, en in ipairs(ents) do
					local e2 = P:Entity(en[1], en[2])
					if e2 and e2[2] and next(e2[2]) then spots = 1 break end
				end
				if spots > 0 then
					out[#out + 1] = { index = j, text = o.text, ents = ents }
				else
					local pt = P:GameArea(qid)
					if pt then out[#out + 1] = { index = j, text = o.text, point = pt, area = true } end
				end
			elseif q[K.TRIGMAP] and q[K.TRIGPT] then
				out[#out + 1] = { index = j, text = o.text, point = { q[K.TRIGMAP], Unpack(q[K.TRIGPT]) } }
			else
				-- nothing in our data: the quest area the game itself shows on your map
				local pt = P:GameArea(qid)
				if pt then out[#out + 1] = { index = j, text = o.text, point = pt, area = true } end
			end
		end
	end
	return out
end

---------------------------------------------------------------------------
-- Stops
---------------------------------------------------------------------------
-- what's waiting at an NPC/object right now
local TURN_ONLY = { turnin = true, turnins = true }
P.TURN_ONLY = TURN_ONLY
function P:EntityWork(key, filter)
	local extra, turnOnly
	if filter == nil then
		local r = self.route
		filter, extra = r and r.quests, r and r.extra
		turnOnly = r and TURN_ONLY[r.mode]                 -- a turn-in run hands in, it doesn't take new quests
	elseif filter == false then filter = nil end
	local pick, turn = {}, {}
	for _, qid in ipairs(self.endsBy[key] or EMPTY) do
		local e = self.log[qid]
		if e and e.complete and (not filter or filter[qid] or (extra and extra[qid])) and not self:Marked("turnins", qid) and not self:Hidden(qid) then turn[#turn + 1] = qid end
	end
	if turnOnly then return pick, turn end
	for _, qid in ipairs(self.startsBy[key] or EMPTY) do
		if (not filter or filter[qid]) and self:Available(qid) then pick[#pick + 1] = qid end
	end
	return pick, turn
end

-- Is a spot on the guide's way? Close to one of its next few stops, or a small
-- detour between you and the next one. Things that join the guide by themselves
-- (an undiscovered flight path, the inn to set your hearthstone) ask this, so they
-- never pull you somewhere the guide isn't going. near: yards to count as close to
-- a stop; slack: extra yards a detour may add.
function P:OnTheWay(inst, wx, wy, near, slack)
	local r = self.route
	if not (r and r.stops and inst and wx) then return false end
	local s1 = r.stops[1]
	if s1 and (s1.travel or s1.trip) then s1 = r.stops[2] end
	for i = 1, math.min(#r.stops, 4) do
		local s = r.stops[i]
		if s.wx and s.inst == inst and (s.wx - wx) ^ 2 + (s.wy - wy) ^ 2 < near * near then return true, i end
	end
	local pi, px, py = self:PlayerPos()
	if s1 and s1.wx and pi == inst and s1.inst == inst then
		local function d(ax, ay, bx, by) return sqrt((ax - bx) ^ 2 + (ay - by) ^ 2) end
		if d(px, py, wx, wy) + d(wx, wy, s1.wx, s1.wy) - d(px, py, s1.wx, s1.wy) < slack then return true, 0 end
	end
	return false
end

-- Finished quests handed in where the guide already takes you: any turn-in in the
-- same town or city as one of its stops joins it, right after that stop, whatever
-- guide you're on. Only towns the guide goes to: the town you happen to be standing
-- in doesn't pull a step ahead of where the guide is taking you.
local function TownOf(s)
	if s.town == nil then s.town = (s.wx and P.TownAt and P:TownAt(s.map, s.inst, s.wx, s.wy)) or false end
	return s.town or nil
end
function P:AddTownTurnIns(r)
	r = r or self.route
	if not r or r.single or TURN_ONLY[r.mode] or r.mode == "flights" or not S().townTurnIns then return end
	local towns, have, at = {}, {}, {}
	for i, st in ipairs(r.stops) do
		if st.key then have[st.key] = true end
		-- where you fly or sail from isn't somewhere the guide is going
		local t = not (st.travel or st.trip) and TownOf(st)
		if t and not towns[t] then towns[t] = i end
	end
	for k in pairs(r.skipped or EMPTY) do have[k] = true end
	if not next(towns) then return end
	local added
	for _, st in ipairs(self:Stops(self.MODES.turnin, nil, nil)) do
		local t = TownOf(st)
		local after = t and towns[t]
		if after then
			-- handed in here too, even where the guide already stops for something else
			r.extra = r.extra or {}
			for _, qid in ipairs(st.turn or EMPTY) do r.extra[qid] = true end
			if not have[st.key] then at[#at + 1] = { st, after }; have[st.key] = true end
		end
	end
	if #at == 0 then return end
	-- latest first, so earlier places stay put
	sort(at, function(a, b) return a[2] > b[2] end)
	for _, p in ipairs(at) do
		tinsert(r.stops, min(p[2] + 1, #r.stops + 1), p[1])
		r.total = (r.total or 0) + 1
		added = true
	end
	return added
end

-- far: also place it on another continent (the trip planner gets you there)
local FAR = 1e7
local function PlaceStop(stop, inst, px, py, onlyMap, far)
	if stop.point then
		local m, x, y = stop.point[1], stop.point[2], stop.point[3]
		local i, wx, wy = P:WorldPos(m, x, y)
		if not i then return false end
		if inst and i ~= inst and not (far or stop.far) then return false end
		stop.map, stop.x, stop.y, stop.wx, stop.wy, stop.inst = m, x, y, wx, wy, i
		stop.dist = (inst and i ~= inst) and FAR or (px and sqrt((wx - px) ^ 2 + (wy - py) ^ 2) or 0)
		return not onlyMap or m == onlyMap
	end
	local d, m, x, y, wx, wy, ent, pt = P:Nearest(stop.ents, inst, px, py, onlyMap)
	if not d and far then
		d, m, x, y, wx, wy, ent, pt = P:Nearest(stop.ents, nil, nil, nil, onlyMap)
		if d then d = FAR end
	end
	if not d then return false end
	stop.dist, stop.map, stop.x, stop.y, stop.wx, stop.wy, stop.at, stop.atPt = d, m, x, y, wx, wy, ent, pt
	local t = P:MapXform(m)
	stop.inst = t and t[1]
	return true
end
P.PlaceStop = PlaceStop

local ALL = { pickup = true, objective = true, turnin = true }
P.MODES = {
	next = ALL, zone = ALL, fast = { pickup = true, objective = true, turnin = true, fast = true },
	pickup = { pickup = true }, objective = { objective = true }, turnin = { turnin = true }, turnins = { turnin = true },
}

-- quest sets you asked for by name (one quest, a chain, a dungeon): nothing in them is left out
local ASKED = setmetatable({}, { __mode = "k" })

-- every stop of the given kinds; placed relative to the player
function P:Stops(kinds, onlyMap, filter, far)
	local inst, px, py = self:PlayerPos()
	local list, byKey = {}, {}
	local function entityStop(kind, id)
		local key = kind .. id
		local s = byKey[key]
		if s == nil and not self:FriendlyTo(kind, id) then byKey[key] = false; return nil end
		if not s then
			s = { key = key, ents = { { kind, id } }, name = self:EntityName(kind, id) }
			if PlaceStop(s, inst, px, py, onlyMap, far) then byKey[key] = s; list[#list + 1] = s else byKey[key] = false end
		end
		return s or nil
	end
	if kinds.turnin then
		for qid, e in pairs(self.log) do
			local q = self.Q[qid]
			if q and e.complete and (not filter or filter[qid]) and not self:Marked("turnins", qid) and not self:Hidden(qid) then
				for _, id in ipairs(q[K.EN] or EMPTY) do if entityStop("N", id) then break end end
				for _, id in ipairs(q[K.EO] or EMPTY) do entityStop("O", id) end
			end
		end
	end
	if kinds.pickup then
		local dq, asked = S().dungeonQuests, filter and ASKED[filter]
		for _, qid in ipairs(self:AvailableList()) do
			-- a quest, chain or dungeon you asked for keeps its quests; otherwise no
			-- dungeon quests and no elites you can't do alone
			if (not filter or filter[qid]) and (asked or ((dq or not self:DungeonQuest(qid)) and not self:TooHardSolo(qid, kinds.fast))) then
				local q = self.Q[qid]
				for _, id in ipairs(q[K.SN] or EMPTY) do entityStop("N", id) end
				for _, id in ipairs(q[K.SO] or EMPTY) do entityStop("O", id) end
			end
		end
	end
	-- entity stops only count if something is actually waiting there
	for i = #list, 1, -1 do
		local s = list[i]
		s.pick, s.turn = self:EntityWork(s.key, filter or false)
		if not kinds.pickup then s.pick = EMPTY end
		if not kinds.turnin then s.turn = EMPTY end
		if #s.pick == 0 and #s.turn == 0 then tremove(list, i) end
	end
	if kinds.objective then
		local inside = IsInInstance and IsInInstance()
		for qid, e in pairs(self.log) do
			-- a dungeon's quest waits for the dungeon (or a group): no walking to its door alone
			local asked = filter and ASKED[filter]
			if not e.complete and (not filter or filter[qid]) and not self:Hidden(qid)
				and (inside or asked or ((S().dungeonQuests or not self:DungeonQuest(qid)) and not self:TooHardSolo(qid, kinds.fast))) then
				for _, t in ipairs(self:ObjectiveTargets(qid)) do
					local s = { key = "q" .. qid .. ":" .. t.index, quest = qid, index = t.index, text = t.text, ents = t.ents, point = t.point, area = t.area }
					if not self:Marked("steps", s.key) and PlaceStop(s, inst, px, py, onlyMap, far) then list[#list + 1] = s end
				end
			end
		end
	end
	return list, inst ~= nil
end

local function Arrived(s, yards)
	local inst, px, py = P:PlayerPos()
	return inst and s.wx and sqrt((s.wx - px) ^ 2 + (s.wy - py) ^ 2) <= yards
end

function P:StopDone(s)
	if s.trip then return self:TripDone(s) end
	if s.travel then return self:TravelDone(s) end
	if s.flight then return self.cdb.flights[s.flight] == true end
	if s.used then return true end                 -- you opened the mailbox, the flight map, the vendor...
	if s.inZone and self:PlayerZone() == s.inZone then return true end   -- the zone you were heading for
	if s.bind and self.HearthAt and self:HearthAt(s.wx, s.wy, s.inst) then return true end
	if s.sweep then
		-- the door stays until the run's over and you're back out
		local b = self.cdb and self.cdb.fastSet
		if not (b and b.kind == "sweep" and b.name == s.sweep) then return true end
		return not b.inside and self:SweepPhase(b) ~= "run"
	end
	if s.key and self:Marked("steps", s.key) then return true end
	if s.goal then return Arrived(s, s.reach or 15) end
	if s.quest then
		if self:Hidden(s.quest) then return true end
		local e = self.log[s.quest]
		if not e or e.complete then return true end
		local o = e.objectives and e.objectives[s.index]
		return o == nil or o.finished == true
	end
	if s.skipped then return true end
	local pick, turn = self:EntityWork(s.key)
	return #pick == 0 and #turn == 0
end

-- short label for a stop: "Turn in · Kobold Camp Cleanup  +1"
function P:StopLabel(s)
	if s.flight then return "Flight master", s.name end
	if s.sweep then
		local b = self.cdb and self.cdb.fastSet
		if b and b.inside then
			local _, _, inside = self:SweepPhase(b)
			return inside > 0 and ("Your quests here: " .. inside .. " to go") or "All done here: head back out", s.name
		end
		return s.goal, s.name
	end
	if s.goal then return s.goal, s.name or "" end
	if s.travel then
		return "Fly to " .. self:MapName(s.flyMap), s.name, s.flyName
	end
	if s.quest then
		local q = self.Q[s.quest]
		local elite = self:QuestElite(s.quest)
		-- the objective as it stands now ("Defias Thug slain: 6/8"), count in white
		local e = self.log[s.quest]
		local o = e and e.objectives and e.objectives[s.index]
		local text = (o and o.text and o.text ~= "" and o.text) or s.text
		if text then text = text:gsub("(%d+)%s*/%s*(%d+)%s*$", "|cffffffff%1/%2|r") end
		return (text and text ~= "" and text or "Objective") .. (elite and ("  |cffff8c4dElite " .. elite .. "|r") or ""),
			(q and q[K.NAME] or "")
	end
	local pick, turn = self:EntityWork(s.key)
	local verb, list
	if #turn > 0 then verb, list = "Turn in", turn else verb, list = "Pick up", pick end
	local first = list[1] and self.Q[list[1]]
	local extra = (#pick + #turn) - 1
	local title = verb .. "  " .. (first and first[K.NAME] or "")
	if extra > 0 then title = title .. "  |cff6b7480+" .. extra .. "|r" end
	return title, s.name
end

function P:StopKind(s)
	if s.flight then return "flight" end
	if s.trip then return "travel" end
	if s.goal then return "goal" end
	if s.travel then return "travel" end
	if s.quest then return "objective" end
	local _, turn = self:EntityWork(s.key)
	return #turn > 0 and "turnin" or "pickup"
end

---------------------------------------------------------------------------
-- Routes
---------------------------------------------------------------------------
local function score(s)
	local kind = P:StopKind(s)
	return s.dist * (kind == "turnin" and 0.8 or 1)
end

-- The default route is chain-first: finish current objectives and turn in
-- completed quests before making a separate trip for unrelated pickups. A
-- pickup at the current hub or at the same NPC as a turn-in is still batched.
local HUB = 80

local function FocusStops(stops, inst, px, py, filter)
	local hasQuestWork = false
	for _, s in ipairs(stops) do
		if s.quest then hasQuestWork = true; break end
		local _, turn = P:EntityWork(s.key, filter or false)
		if #turn > 0 then hasQuestWork = true; break end
	end
	if not hasQuestWork then return stops end
	local focused = {}
	for _, s in ipairs(stops) do
		if s.quest then
			focused[#focused + 1] = s
		else
			local pick, turn = P:EntityWork(s.key, filter or false)
			if #turn > 0 then
				focused[#focused + 1] = s
			elseif #pick > 0 and s.wx and px then
				local d2 = (s.wx - px) ^ 2 + (s.wy - py) ^ 2
				if d2 <= HUB * HUB then focused[#focused + 1] = s end
			end
		end
	end
	return focused
end

local followupCache
local function UnlocksFollowup(qid)
	if not followupCache then
		followupCache = {}
		for _, q in pairs(P.Q) do
			for _, id in ipairs(q[K.PRE] or EMPTY) do followupCache[id] = true end
			for _, id in ipairs(q[K.PREANY] or EMPTY) do followupCache[id] = true end
			if q[K.PARENT] then followupCache[q[K.PARENT]] = true end
		end
	end
	return followupCache[qid] == true
end

local function Weight(s)
	if s.quest then return 1 end
	local pick, turn = P:EntityWork(s.key)
	if #turn == 0 then return 1 end
	if #pick > 0 then return 0.8 end
	for _, qid in ipairs(turn) do
		local q = P.Q[qid]
		if q and (q[K.NEXT] or UnlocksFollowup(qid)) then return 0.85 end
	end
	return 1.12
end

local function NearestNeighbour(stops, px, py)
	local out, left = {}, {}
	local hub = {}
	for _, s in ipairs(stops) do
		if not s.quest and s.wx and px and ((s.wx - px) ^ 2 + (s.wy - py) ^ 2) <= HUB * HUB then hub[#hub + 1] = s
		else left[#left + 1] = s end
	end
	-- 1. the hub you're standing in, closest first
	table.sort(hub, function(a, b) return ((a.wx - px) ^ 2 + (a.wy - py) ^ 2) < ((b.wx - px) ^ 2 + (b.wy - py) ^ 2) end)
	for _, s in ipairs(hub) do out[#out + 1] = s end
	local weight = {}
	for _, s in ipairs(left) do weight[s] = Weight(s) end
	local last = out[#out]
	local cx, cy, cz = last and last.wx or px, last and last.wy or py, P:PlayerZone()
	-- next stop: the closest by the way you'd really walk (a zone away means
	-- the road through the pass, not a line over the mountains)
	local zoneOf = {}
	local function Zone(s)
		local z = zoneOf[s]
		if z == nil then z = s.map and P:ZoneOf(s.map) or false; zoneOf[s] = z end
		return z or nil
	end
	while #left > 0 do
		local bi, bd = 1, nil
		for i, s in ipairs(left) do
			local d = (s.wx - cx) ^ 2 + (s.wy - cy) ^ 2
			local z = Zone(s)
			if z and cz and z ~= cz and P.WalkYards then
				local yd = P:WalkYards(cz, cx, cy, z, s.wx, s.wy)
				if yd < math.huge then d = yd * yd end
			end
			d = d * (weight[s] or 1) ^ 2
			if not bd or d < bd then bi, bd = i, d end
		end
		local s = tremove(left, bi)
		out[#out + 1] = s
		cx, cy, cz = s.wx, s.wy, Zone(s) or cz
	end
	return out
end

-- a guide follows its own quests, but a quest giver right next to you is
-- part of the guide too: you'd pick it up anyway while you're standing there
local NEAR_GIVER = 40
local function AddGiversHere(quests, inst, px, py)
	if not (quests and inst) then return end
	for _, qid in ipairs(P:AvailableList()) do
		if not quests[qid] then
			local q = P.Q[qid]
			local ents = {}
			for _, id in ipairs(q[K.SN] or EMPTY) do ents[#ents + 1] = { "N", id } end
			for _, id in ipairs(q[K.SO] or EMPTY) do ents[#ents + 1] = { "O", id } end
			local d = #ents > 0 and P:Nearest(ents, inst, px, py)
			if d and d <= NEAR_GIVER then quests[qid] = true end
		end
	end
end

---------------------------------------------------------------------------
-- Fastest XP: after every step, the most experience for the time it takes.
-- Each stop is worth what it brings you closer to: a hand-in pays the quest's
-- experience, an objective most of it, a pickup the promise of it. The route
-- takes the best value per second (walking at your speed) from where you are,
-- again and again, and is worked out fresh after every hand-in.
---------------------------------------------------------------------------
local XP_DROP = { [6] = 0.8, [7] = 0.6, [8] = 0.4, [9] = 0.2 }
-- A quest's experience at your level. The real reward when the game shows it
-- (it's in your log), else what it's known to pay on Forever (QuestieDB's
-- QuestXP data, Data/QuestXP.lua) with the game's own rule for quests below
-- you: full up to five levels under, then less. Quests nobody has measured
-- are estimated from their level.
-- What a quest really pays. The data's numbers are the old world's (Forever pays
-- dungeon quests far more), so whenever the game shows a reward (the quest window,
-- the quest log) Pathway notes it, as the quest's full reward before any penalty
-- for being high above it, for all your characters. One number a quest.
-- P.XP[qid] = experience * 1000 + (1 if it's Forever's own number) * 100 + the quest's level
local function QuestLevel(qid)
	local packed = P.XP and P.XP[qid]
	if packed then return packed % 100 end
	local q = P.Q[qid]
	return q and q[K.LVL] or 0
end
local DUNGEON_STANDIN = 2.2
local function Penalty(L, me)
	local m = 2 * (L - me) + 20
	if m < 1 then m = 1 elseif m > 10 then m = 10 end
	return m / 10
end
function P:LearnQuestXP(qid, xp)
	if not (qid and qid > 0 and type(xp) == "number" and self.db) or (issecretvalue and issecretvalue(xp)) or xp <= 0 then return end
	local L = QuestLevel(qid)
	-- only rewards without the penalty (the quest isn't far below you) say what it pays
	if L <= 0 or Penalty(L, self.me.level or 1) < 1 then return end
	local packed = P.XP and P.XP[qid]
	local known = packed and floor(packed / 100) % 10 == 1 and floor(packed / 1000) == xp
	local t = self.db.questXP
	if known then
		if t and t[qid] then t[qid] = nil end              -- the data has this one: nothing to keep
		return
	end
	if not t then t = {}; self.db.questXP = t end
	if t[qid] ~= xp then
		t[qid] = xp
		if self.ShareQuestXP then self:ShareQuestXP(qid, xp) end     -- other Pathway players learn it too
	end
end
function P:QuestXP(qid, estimate)
	local real = self.log[qid] and GetQuestLogRewardXP and select(2, pcall(GetQuestLogRewardXP, qid))
	if type(real) == "number" and not (issecretvalue and issecretvalue(real)) and real > 0 then
		self:LearnQuestXP(qid, real)
		if not estimate then return real end
	end
	local me = self.me.level or 1
	local learned = self.db and self.db.questXP and self.db.questXP[qid]
	if learned then return learned * Penalty(QuestLevel(qid), me) end
	-- what other Pathway players saw, when it's newer than the data (see Share.lua)
	local heard = self.PeerXP and self:PeerXP(qid)
	if heard then return heard * Penalty(QuestLevel(qid), me) end
	local packed = self.XP and self.XP[qid]
	if packed then
		local xp = floor(packed / 1000)
		-- only the old world's number for a dungeon quest: Forever pays about 2.2 times that
		-- (1.8 to 2.7 by dungeon, since October 1) until the real one is seen
		if floor(packed / 100) % 10 == 0 and self:DungeonQuest(qid) then xp = floor(xp * DUNGEON_STANDIN / 50 + 0.5) * 50 end
		return xp * Penalty(packed % 100, me)
	end
	local q = self.Q[qid]
	local L = q and q[K.LVL] or 0
	if L <= 0 then return 0 end                       -- no level and no measurement: not something to chase for XP
	local base = L * L * 5 + L * 45 + 80             -- close to the old world's quest rewards by level
	local diff = me - L
	if diff >= 10 then return base * 0.1 end
	return base * (XP_DROP[diff] or 1)
end

local function StopValue(s)
	if s.quest then
		local e = P.log[s.quest]
		local n = math.max(1, e and e.objectives and #e.objectives or 1)
		return P:QuestXP(s.quest) * 0.7 / n, 60          -- the work there: about a minute
	end
	if s.sweep then return 1e6, 0 end                     -- a dungeon's door: the run is the point
	-- what's waiting there for the set being worked out (the stop knows; the route may be the old one)
	local pick, turn = s.pick, s.turn
	if not (pick and turn) then pick, turn = P:EntityWork(s.key) end
	local v = 0
	for _, qid in ipairs(turn) do v = v + P:QuestXP(qid) end
	for _, qid in ipairs(pick) do v = v + P:QuestXP(qid) * 0.35 end
	return v, 8
end

function P:FastOrder(stops, px, py, count)
	local speed = (P.TravelSpeed and P.TravelSpeed()) or 7
	local left, out = {}, {}
	for _, s in ipairs(stops) do
		local v, work = StopValue(s)
		if v > 0 then left[#left + 1] = { s = s, v = v, work = work, z = s.map and P:ZoneOf(s.map) } end
	end
	local cx, cy, cz = px, py, P:PlayerZone()
	while #left > 0 and #out < (count or 12) do
		local bi, best
		for i, c in ipairs(left) do
			local s = c.s
			local yd = sqrt((s.wx - cx) ^ 2 + (s.wy - cy) ^ 2)
			if c.z and cz and c.z ~= cz and P.WalkYards then
				local w = P:WalkYards(cz, cx, cy, c.z, s.wx, s.wy)
				if w < math.huge then yd = w end
			end
			local rate = c.v / (yd / speed + c.work + 5)
			if not best or rate > best then bi, best = i, rate end
		end
		local c = tremove(left, bi)
		out[#out + 1] = c.s
		cx, cy, cz = c.s.wx, c.s.wy, c.z or cz
	end
	return out
end

---------------------------------------------------------------------------
-- Fastest XP, in sets. Only the quickest experience counts: the top 25%, by
-- experience a minute, of everything you could pick up at your level (and a
-- quest that opens a chain where a later part makes the cut). A delivery
-- that pays 400 in forty seconds beats twelve drops for 1100. Quests are
-- grouped by the zone their giver is in, and the next set is the zone that
-- gives the most experience per minute: what its quests pay, against the
-- real trip there (flights, boats, the tram, on either continent) and the
-- time each quest takes. A big set a flight away beats one lone quest next
-- door. Once a set is picked up nothing else is: you finish it and hand it
-- in, then the next set is worked out. The next part of a chain in the set
-- joins it when it makes the cut, since you're standing at its giver anyway.
---------------------------------------------------------------------------
local QUEST_SECS = 240                    -- a quest Pathway can't size up: about four minutes

-- How long a quest takes, in seconds, from what it asks: who to kill or talk
-- to, what to collect and where, how far that is from its giver, how spread
-- out, how many (your quest log's own counts once you have it, else what any
-- of your characters saw, else a usual number), elites, and a hand-in
-- somewhere else. Then your own pace: Pathway times your sets and learns how
-- you compare (P:FastPace), so the guess becomes yours.
local KILL_SECS, LOOT_SECS, TALK_SECS = 24, 12, 8      -- find and kill one; pick one up; a word
local DROP_CHANCE = 0.6                                 -- a quest item off a mob, most of the time
local secsCache = {}
local function WorldOf(e)
	-- the middle of an entity's spawns on its busiest map, and how spread out they are
	local bestMap, best
	for map, pts in pairs(e and e[2] or EMPTY) do
		if type(pts) == "table" and (not best or #pts > #best) then bestMap, best = map, pts end
	end
	if not best or #best == 0 then return nil end
	local inst, sx, sy, n = nil, 0, 0, 0
	local step = math.max(1, floor(#best / 24))         -- a sample is plenty
	local pts = {}
	for i = 1, #best, step do
		local x, y = P.Unpack(best[i])
		local wi, wx, wy = P:WorldPos(bestMap, x, y)
		if wi then inst = wi; sx, sy, n = sx + wx, sy + wy, n + 1; pts[#pts + 1] = wx; pts[#pts + 1] = wy end
	end
	if n == 0 then return nil end
	local cx, cy = sx / n, sy / n
	local spread = 0
	for i = 1, #pts, 2 do spread = spread + sqrt((pts[i] - cx) ^ 2 + (pts[i + 1] - cy) ^ 2) end
	return inst, cx, cy, spread / n, #best
end
local function Where(kind, ids)
	for _, id in ipairs(ids or EMPTY) do
		local inst, x, y = WorldOf(P:Entity(kind, id))
		if inst then return inst, x, y end
	end
end
-- how many of each objective, in order: the log's counts (what's left of them), or remembered ones
local function Counts(qid)
	local e = P.log[qid]
	local seen = P.db and P.db.objCounts and P.db.objCounts[qid]
	if not (e and e.objectives) then return seen, nil end
	local need, left = {}, {}
	for i, o in ipairs(e.objectives) do
		local tGot, tReq = (o.text or ""):match("(%d+)%s*/%s*(%d+)")
		local req = o.numRequired or tonumber(tReq)
		local got = o.numFulfilled or tonumber(tGot) or 0
		need[i] = req or 1
		left[i] = o.finished and 0 or math.max(0, (req or 1) - got)
	end
	-- remembered for next time (one small list a quest, shared by your characters)
	if P.db and #need > 0 then
		P.db.objCounts = P.db.objCounts or {}
		local prev = P.db.objCounts[qid]
		local same = prev and #prev == #need
		if same then for i = 1, #need do if prev[i] ~= need[i] then same = false end end end
		if not same then P.db.objCounts[qid] = need end
	end
	return need, left
end
function P:QuestSecs(qid)
	local inLog = self.log[qid]
	local c = not inLog and secsCache[qid]
	if c then return c * self:FastPace() end
	local q = self.Q[qid]
	if not q then return QUEST_SECS end
	local speed = (P.TravelSpeed and P.TravelSpeed()) or 7
	local need, left = Counts(qid)
	local counts = left or need
	local gi, gx, gy = Where("N", q[K.SN])
	if not gi then gi, gx, gy = Where("O", q[K.SO]) end
	local secs, far, k = 25, 0, 0                  -- picking it up and handing it in
	local function trip(inst, x, y)
		if not (gi and inst) then far = math.max(far, 300) return end
		if inst ~= gi then far = math.max(far, 1500) return end
		far = math.max(far, sqrt((x - gx) ^ 2 + (y - gy) ^ 2))
	end
	local function count(default)
		k = k + 1
		local n = counts and counts[k]
		return n or default
	end
	-- mobs to kill, or people to talk to
	for _, id in ipairs(q[K.ON] or EMPTY) do
		local inst, x, y, spread, spots = WorldOf(self.N[id])
		local few = (spots or 0) <= 3                 -- a named one, or someone to see
		local n = count(few and 1 or 8)
		local e = self.N[id]
		local elite = e and (e[5] == 1 or e[5] == 2 or e[5] == 3)
		-- someone the quest has you talk to (they're its giver or its hand-in), or one to find and kill
		local talk = false
		for _, nid in ipairs(q[K.SN] or EMPTY) do if nid == id then talk = true end end
		for _, nid in ipairs(q[K.EN] or EMPTY) do if nid == id then talk = true end end
		local each = talk and TALK_SECS or (few and KILL_SECS * 1.6 or KILL_SECS)
		secs = secs + n * each * (elite and not talk and 2.2 or 1)
		if spread and n > 1 then secs = secs + math.min(spread, 250) / speed * 0.6 end
		trip(inst, x, y)
	end
	-- things to collect: off mobs, or picked up
	for _, iid in ipairs(q[K.OI] or EMPTY) do
		local it = self.I[iid]
		local fromNPC, fromObj = it and it[2], it and it[3]
		local n = count((fromNPC and #fromNPC <= 1) and 1 or 6)
		if fromObj and #fromObj > 0 and not (fromNPC and #fromNPC > 0) then
			secs = secs + n * LOOT_SECS
			local inst, x, y, spread = Where("O", fromObj)
			trip(inst, x, y)
		elseif fromNPC and #fromNPC > 0 then
			local inst, x, y, spread = WorldOf(self.N[fromNPC[1]])
			local e = self.N[fromNPC[1]]
			local elite = e and (e[5] == 1 or e[5] == 2 or e[5] == 3)
			secs = secs + n * KILL_SECS / DROP_CHANCE * (elite and 2.2 or 1)
			if spread and n > 1 then secs = secs + math.min(spread, 250) / speed * 0.6 end
			trip(inst, x, y)
		else
			secs = secs + n * 20
		end
	end
	-- things to use or click
	for _, id in ipairs(q[K.OO] or EMPTY) do
		local n = count(1)
		secs = secs + n * LOOT_SECS
		local inst, x, y = WorldOf(self.O[id])
		trip(inst, x, y)
	end
	-- somewhere to go
	if q[K.TRIGMAP] then far = math.max(far, 400) end
	-- the hand-in, when it isn't back where you started
	local ei, ex, ey = Where("N", q[K.EN])
	if not ei then ei, ex, ey = Where("O", q[K.EO]) end
	local there = 0
	if gi and ei then there = ei ~= gi and 1500 or sqrt((ex - gx) ^ 2 + (ey - gy) ^ 2) end
	-- out to the objectives and back, or on to the hand-in, whichever is longer
	secs = secs + math.max(far * 2, there + far) / speed
	-- an elite quest you'd do alone is slow whatever it asks
	if self:QuestElite(qid) then secs = secs * 1.3 end
	secs = math.max(40, math.min(1800, secs))
	if not inLog then secsCache[qid] = secs end
	return secs * self:FastPace()
end
-- experience a minute a quest gives, by itself
function P:QuestRate(qid, xp)
	return (xp or self:QuestXP(qid, true)) / self:QuestSecs(qid) * 60
end
-- 23650 -> "23.7k"
function P.Short(x)
	x = floor(x or 0)
	if x < 1000 then return tostring(x) end
	return (("%.1fk"):format(x / 1000):gsub("%.0k$", "k"))
end
local function FastOK(qid)
	return (S().dungeonQuests or not P:DungeonQuest(qid)) and not P:TooHardSolo(qid, true)
end
-- the experience a quest has to pay to make the cut. It's set once per level
-- (and kept over a reload), so finishing the best quests doesn't lower it:
-- a zone with only lesser quests left sends you on to the next zone. Only
-- when nothing anywhere makes the cut is it worked out again.
function P:FastBar(fresh)
	local c, lvl = self.cdb, self.me.level
	if not fresh and c and c.fastBar and c.fastBar.lvl == lvl and c.fastBar.v == 3 then return c.fastBar.bar end
	local xs = {}
	for _, qid in ipairs(self:AvailableList()) do
		if FastOK(qid) then
			local x = self:QuestXP(qid, true)
			if x > 0 then xs[#xs + 1] = self:QuestRate(qid, x) end
		end
	end
	sort(xs)
	local bar = #xs > 0 and xs[max(1, math.ceil(#xs * 0.75))] or 0
	if c and #xs > 0 then c.fastBar = { lvl = lvl, bar = bar, v = 3 } end
	return bar
end
-- the later parts of a quest's chain, while they're still to do
local function ChainAfter(qid, depth)
	local out, q, seen = {}, P.Q[qid], { [qid] = true }
	for _ = 1, depth or 5 do
		local nx = q and q[K.NEXT]
		if not nx or seen[nx] or P.done[nx] then break end
		seen[nx] = true
		out[#out + 1] = nx
		q = P.Q[nx]
	end
	return out
end
-- does a quest make the cut, and what's it worth: its own experience, plus most
-- of what the rest of its chain pays when a later part makes the cut
-- (the bar is experience a minute)
local function FastWorth(qid, bar)
	local own = P:QuestXP(qid, true)
	local more, opens = 0, false
	for i, nx in ipairs(ChainAfter(qid, 4)) do
		local x = P:QuestXP(nx, true)
		if x > 0 and P:QuestRate(nx, x) >= bar then opens = true end
		more = more + x * (0.8 ^ i)
	end
	if own > 0 and P:QuestRate(qid, own) >= bar then return true, own + more * 0.5 end
	if opens then return true, own + more * 0.5 end
	return false, own
end
P.FastWorth = FastWorth
-- which zone a quest belongs to: where its giver is (else its own zone), and that giver's spot
local function QuestZone(qid, inst, px, py)
	local q = P.Q[qid]
	local ents = {}
	for _, id in ipairs(q[K.SN] or EMPTY) do ents[#ents + 1] = { "N", id } end
	for _, id in ipairs(q[K.SO] or EMPTY) do ents[#ents + 1] = { "O", id } end
	local d, m, wx, wy, _
	if #ents > 0 then
		d, m, _, _, wx, wy = P:Nearest(ents, inst, px, py)
		if not d then d, m, _, _, wx, wy = P:Nearest(ents, nil, px, py); d = d and FAR * FAR end
	end
	m = m or q[K.ZONE]
	return m and (P:ZoneOf(m) or m), d or FAR * FAR, m, wx, wy
end
P.QuestZone = QuestZone

-- how long it takes to get somewhere, in seconds: the trip planner's answer
-- (flights, boats, the tram, hearth-free), else on foot
-- second answer: the effort, where time sitting on a flight or boat counts for less
local function TravelSecs(map, wx, wy, inst, px, py)
	local t = map and P:MapXform(map)
	if not (t and wx) then return 900, 900 end
	local speed = (P.TravelSpeed and P.TravelSpeed()) or 7
	if t[1] == inst then
		local walk = P:WalkYards(P:PlayerZone(), px, py, P:ZoneOf(map) or map, wx, wy) / speed
		if walk < 90 or not P.PlanWay then return walk, walk end
	end
	if P.PlanWay then
		local ok, _, total, _, effort = pcall(P.PlanWay, P, { map = map, wx = wx, wy = wy, inst = t[1] })
		if ok and total then return total, effort or total end
	end
	local w = t[1] == inst and P:WalkYards(P:PlayerZone(), px, py, P:ZoneOf(map) or map, wx, wy) / speed or 900
	return w, w
end
P.TravelSecs = TravelSecs

-- every zone with quests that make the cut, each with how much they pay and
-- how much experience a minute going there gives
local function FastZones(self, bar, inst, px, py)
	local zones = {}
	local function add(qid, worth, inLog)
		local z, d, m, wx, wy = QuestZone(qid, inst, px, py)
		if not z then return end
		local g = zones[z]
		if not g then g = { zone = z, d = math.huge, quests = {}, xp = 0, n = 0 }; zones[z] = g end
		g.quests[#g.quests + 1] = qid
		g.xp, g.n = g.xp + worth, g.n + 1
		g.secs = (g.secs or 0) + self:QuestSecs(qid)
		if d < g.d then g.d, g.map, g.wx, g.wy = d, m, wx, wy end
	end
	for _, qid in ipairs(self:AvailableList()) do
		if FastOK(qid) then
			local ok, worth = FastWorth(qid, bar)
			if ok then add(qid, worth) end
		end
	end
	-- top quests already in your log count as well
	for qid, e in pairs(self.log) do
		if self.Q[qid] and not e.failed and not self:Hidden(qid) then
			local ok, worth = FastWorth(qid, bar)
			if ok then add(qid, worth, true) end
		end
	end
	local here = self:PlayerZone()
	for _, g in pairs(zones) do
		local travel, effort = 0, 0
		if g.zone ~= here then travel, effort = TravelSecs(g.map, g.wx, g.wy, inst, px, py) end
		g.travel = travel
		-- ranked by the effort of getting there: a zone a flight away beats one a long run away
		g.rate = g.xp / (effort + (g.secs or g.n * QUEST_SECS) + 60) * 60   -- experience a minute
		if g.zone == here then g.rate = g.rate * 1.15 end                -- no trip at all: a little head start
	end
	return zones
end

---------------------------------------------------------------------------
-- Dungeon sweeps. Forever pays dungeon quests very well and dungeon kills poorly,
-- so a dungeon is worth one run with all its quests. When one fits your level,
-- Fastest XP asks (once a dungeon; "never" turns it off), and if you say yes the
-- next set is the sweep: gather its quests, find a group at the door, run it
-- once, hand in. Quests you don't finish inside stay in your log.
---------------------------------------------------------------------------
-- where a dungeon's door is: its own people stand there on the zone map
local function DungeonDoor(d)
	for _, qid in ipairs(d.quests) do
		local q = P.Q[qid]
		for _, list in ipairs({ { "N", q[K.ON] }, { "O", q[K.OO] }, { "N", q[K.EN] }, { "N", q[K.SN] } }) do
			for _, id in ipairs(list[2] or EMPTY) do
				local e = P:Entity(list[1], id)
				if e and e[3] == d.name and type(e[2]) == "table" then
					for map, pts in pairs(e[2]) do
						if pts[1] then local x, y = Unpack(pts[1]); return { map, x, y } end
					end
				end
			end
		end
	end
end
-- a dungeon's quests you could take into it now, and what they pay
local function SweepQuests(d)
	local me, out, xp = P.me.level or 1, {}, 0
	for _, qid in ipairs(d.quests) do
		local q = P.Q[qid]
		local open = P.log[qid] or P:Available(qid)
		if q and open and not P.done[qid] and not P:Hidden(qid) and (q[K.LVL] or 0) >= me - 5 then
			local x = P:QuestXP(qid, true)
			if x > 0 then out[#out + 1] = qid; xp = xp + x end
		end
	end
	return out, xp
end
function P:SweepOptions()
	if not (self.Cat and self.Cat.Build) then return {} end
	self.Cat:Build()
	local me, list = self.me.level or 1, {}
	for _, d in ipairs(self.Cat.dungeonList or EMPTY) do
		if d.lo and me >= d.lo and me <= (d.hi or d.lo) + 1 then
			local qs, xp = SweepQuests(d)
			if #qs >= 2 then list[#list + 1] = { d = d, quests = qs, xp = xp } end
		end
	end
	sort(list, function(a, b) return a.xp > b.xp end)
	return list
end
-- one question at a time, and only about a dungeon you haven't answered for
function P:MaybeAskSweep()
	local c = self.cdb
	if not (c and P.db and S().dungeonSweeps ~= false and self.route and self.route.mode == "fast") then return end
	if c.sweep then return end
	c.sweeps = c.sweeps or {}
	for _, o in ipairs(self:SweepOptions()) do
		local name = o.d.name
		if not c.sweeps[name] then
			local door = DungeonDoor(o.d)
			if door then
				c.sweeps[name] = "asked"
				self:Ask({ key = "sweep", icon = "Interface\\Icons\\INV_Misc_Key_03", title = name .. " fits your level",
					text = ("%d quests for one run, about |cffffffff%s XP|r or more. Forever pays dungeon quests well and dungeon kills poorly, so one run with every quest is the way.\n" ..
						P.DIM .. "Fastest XP gathers them, takes you to the door to find a group, then to the hand-ins.|r"):format(#o.quests, P.Short(o.xp)),
					buttons = {
						{ "Never ask", function()
							S().dungeonSweeps = false
							P:Toast("Dungeon sweeps are off (Settings, Quest help, to turn them back on)")
						end, nil, "link" },
						{ "Not this one", function() c.sweeps[name] = "no" end },
						{ "Add it", function()
							local qs = {}
							for _, qid in ipairs(o.quests) do qs[qid] = true end
							c.sweep = { name = name, quests = qs, door = door, xp = floor(o.xp), n = #o.quests }
							c.sweeps[name] = "yes"
							P:Toast(("Fastest XP: the %s sweep is next, after this set"):format(name))
						end, true },
					} })
				return
			end
		end
	end
end
-- where the sweep is at: gathering its quests, the run, then the hand-ins
function P:SweepPhase(b)
	local pick, inside, ready = 0, 0, 0
	for qid in pairs(b.quests) do
		local e = self.log[qid]
		if e then if e.complete then ready = ready + 1 else inside = inside + 1 end
		elseif self:Available(qid) then pick = pick + 1 end
	end
	if b.ran then return "turnin", pick, inside, ready end
	if pick > 0 then return "gather", pick, inside, ready end
	if inside > 0 then return "run", pick, inside, ready end
	return "turnin", pick, inside, ready
end
-- the quests a sweep works on now
local function SweepFilter(self, b)
	local phase = self:SweepPhase(b)
	local f = {}
	for qid in pairs(b.quests) do
		local e = self.log[qid]
		if (e and e.complete) or (phase == "gather" and not e) then f[qid] = true end
	end
	ASKED[f] = true                       -- dungeon quests are the point here
	return f
end
-- the door: a stop of its own while the run is next
function P:SweepStops(b, list)
	if not (b and b.kind == "sweep") then return list end
	if self:SweepPhase(b) ~= "run" then return list end
	local inst, px, py = self:PlayerPos()
	local st = { key = "sweep:" .. b.name, sweep = b.name, goal = "Find a group for " .. b.name, name = b.name, point = b.door, reach = 40,
		tip = "Your quests for it are in your log. Look for a group here (or in the group finder), then go in: the guide waits at the door." }
	if PlaceStop(st, inst, px, py, nil, true) then tinsert(list, 1, st) end
	return list
end
-- inside, then out again: the run's done (whatever's left stays in your log)
P:On("PLAYER_ENTERING_WORLD", function()
	local b = P.cdb and P.cdb.fastSet
	if not (b and b.kind == "sweep") then return end
	local inInst = IsInInstance and IsInInstance()
	local name = GetInstanceInfo and GetInstanceInfo()
	if inInst and name and name:lower() == b.name:lower() then b.inside = true
	elseif b.inside and not inInst then
		b.inside, b.ran = nil, true
		local left = 0
		for qid in pairs(b.quests) do
			local e = P.log[qid]
			if e and not e.complete then b.quests[qid] = nil; left = left + 1 end
		end
		if left > 0 then P:Toast(("%s: %d quest%s not finished, still in your log"):format(b.name, left, left == 1 and "" or "s"), true) end
		if P.route and P.route.mode == "fast" then P:RefreshRoute() end
	end
end)

function P:FastSet(retry)
	local c = self.cdb
	if not c then return end
	local bar = self:FastBar()
	local inst, px, py = self:PlayerPos()
	local b = c.fastSet
	if b and b.v ~= 2 then b = nil; c.fastSet = nil end
	if b then
		-- what's left of the set you're on
		local left = false
		for qid in pairs(b.quests) do
			if self.done[qid] or self:Hidden(qid) or not (self.log[qid] or self:Available(qid))
				or (b.kind == "sweep" and b.ran and not self.log[qid]) then b.quests[qid] = nil else left = true end
		end
		-- the next part of a chain in the set, when it makes the cut (a sweep keeps to its dungeon's quests)
		for _, qid in ipairs(b.kind ~= "sweep" and self:AvailableList() or EMPTY) do
			if not b.quests[qid] and FastOK(qid) then
				local q = self.Q[qid]
				local follows = q[K.PARENT] and b.had[q[K.PARENT]]
				for _, p in ipairs(q[K.PRE] or EMPTY) do if b.had[p] then follows = true break end end
				for _, p in ipairs(q[K.PREANY] or EMPTY) do if b.had[p] then follows = true break end end
				if follows and FastWorth(qid, bar) then b.quests[qid], b.had[qid], left = true, true, true end
			end
		end
		if left then return b, bar end
		P:FastSetDone(b)
		c.fastSet = nil
	end
	if not inst then return nil, bar end
	-- a dungeon sweep you said yes to comes next
	local sw = c.sweep
	if sw and S().dungeonSweeps ~= false then
		c.sweep = nil
		local qs, n = {}, 0
		for qid in pairs(sw.quests) do
			if not self.done[qid] and (self.log[qid] or self:Available(qid)) then qs[qid] = true; n = n + 1 end
		end
		if n > 0 and sw.door then
			local had = {}
			for qid in pairs(qs) do had[qid] = true end
			b = { v = 2, kind = "sweep", name = sw.name, door = sw.door, zone = self:ZoneOf(sw.door[1]) or sw.door[1], quests = qs, had = had,
				at = time(), xp = sw.xp, n = n, est = floor(n * QUEST_SECS * 2 / self:FastPace()), active = 0, got = 0 }
			c.fastSet = b
			self:Toast(("Fastest XP: the %s sweep (%d quests)"):format(sw.name, n))
			if P.BoostMoment then C_Timer.After(3, function() if P.cdb and P.cdb.fastSet == b then P:BoostMoment(b) end end) end
			return b, bar
		end
	end
	-- a new set: the zone that gives the most experience a minute
	local zones = FastZones(self, bar, inst, px, py)
	local here = self:PlayerZone()
	local pick, second
	for _, g in pairs(zones) do
		if not pick or g.rate > pick.rate then pick, second = g, pick
		elseif not second or g.rate > second.rate then second = g end
	end
	if not pick then
		-- nothing anywhere makes the cut any more: the cut moves down to what's left
		if not retry and self:FastBar(true) < bar then return self:FastSet(true) end
		return nil, bar
	end
	b = { v = 2, zone = pick.zone, quests = {}, had = {}, at = time(), xp = floor(pick.xp), n = pick.n,
		next = second and { zone = second.zone, n = second.n, xp = floor(second.xp) } or nil,
		-- for the score: the time Pathway expects it to take (before your pace), and the clock
		est = floor((pick.secs or pick.n * QUEST_SECS) / self:FastPace() + pick.travel), active = 0, got = 0 }
	for _, qid in ipairs(pick.quests) do b.quests[qid], b.had[qid] = true, true end
	c.fastSet = b
	if P.MaybeAskSweep then C_Timer.After(2, function() P:MaybeAskSweep() end) end
	if P.BoostMoment then C_Timer.After(3, function() if P.cdb and P.cdb.fastSet == b then P:BoostMoment(b) end end) end
	if pick.zone ~= here and P.db then
		self:Toast(("Fastest XP: the next set is in %s (%d quests, %s XP)"):format(self:MapName(pick.zone), pick.n, P.Short(pick.xp)))
	end
	return b, bar
end

-- Your pace and the score. While a Fastest XP set is on, Pathway keeps its own clock
-- (only while you're at the keyboard) and counts the experience you get. When the set's
-- done it scores it in experience an hour, and learns how your time compares with its
-- guess, so the next sets are sized to you. The last 10 sets are kept, nothing more.
function P:FastPace()
	local p = self.cdb and self.cdb.fastPace
	return p and p.f and math.max(0.6, math.min(2, p.f)) or 1
end
local lastXP
function P:FastClock(dt)
	local b = self.cdb and self.cdb.fastSet
	local xp = self.session and self.session.xp or 0
	if lastXP == nil or xp < lastXP then lastXP = xp end
	if not (b and b.active and self.route and self.route.mode == "fast") then lastXP = xp return end
	if not (UnitIsAFK and UnitIsAFK("player")) then b.active = b.active + dt end
	b.got = (b.got or 0) + (xp - lastXP)
	lastXP = xp
end
function P:FastSetDone(b)
	if not (b and b.active and b.active >= 120 and (b.got or 0) > 0 and self.cdb) then return end
	local c = self.cdb
	local xph = b.got / b.active * 3600
	c.fastLog = c.fastLog or {}
	table.insert(c.fastLog, 1, { zone = b.zone, xph = floor(xph), mins = floor(b.active / 60 + 0.5), n = b.n, at = time() })
	for i = #c.fastLog, 11, -1 do c.fastLog[i] = nil end
	-- how your time compared with the guess (a set cut short by other things says little)
	if b.est and b.est > 0 then
		local ratio = math.max(0.4, math.min(2.5, b.active / b.est))
		local p = c.fastPace or { f = 1, n = 0 }
		p.f = p.f * 0.7 + ratio * 0.3
		p.n = (p.n or 0) + 1
		c.fastPace = p
		wipe(secsCache)
	end
	self:Toast(("Fastest XP: %s done, %s XP an hour"):format(self:MapName(b.zone) or "set", P.Short(xph)))
end
-- the last sets' scores, newest first
function P:FastLog() return self.cdb and self.cdb.fastLog or EMPTY end
-- a new level: travel speed and what you can do change, so quests are sized up again
P:On("PLAYER_LEVEL_UP", function() wipe(secsCache) end)

-- "Fastest XP: Wetlands · 3 of 7 left"
local PHASE = { gather = "gather its quests", run = "find a group", turnin = "hand in" }
function P:FastTitle(b)
	if b.kind == "sweep" then
		local phase, pick, _, ready = self:SweepPhase(b)
		local n = phase == "gather" and pick or phase == "turnin" and ready or nil
		return "Fastest XP: " .. b.name .. "  ·  " .. PHASE[phase] .. (n and n > 0 and (" (" .. n .. ")") or "")
	end
	local left = 0
	for _ in pairs(b.quests) do left = left + 1 end
	local all = math.max(b.n or left, left)
	-- named for where the guide is sending you now (a set can reach into the next zone)
	local s = self.Current and self:Current()
	local m = s and not (s.travel or s.trip) and s.map
	local zone = (m and (self:ZoneOf(m) or m)) or b.zone
	return "Fastest XP: " .. self:MapName(zone) .. (all > 1 and ("  ·  " .. left .. " of " .. all .. " left") or "")
end

-- what's left of the set, for the card: quests to go and the set after it
function P:FastStatus()
	local b = self.cdb and self.cdb.fastSet
	if not b then return end
	local n = 0
	for _ in pairs(b.quests) do n = n + 1 end
	return n, b.n or n, b.zone, b.next
end

-- the quests the fastest route works on now: the set, plus hand-ins you
-- already have ready where the set is (handing in is never a detour there)
function P:FastFilter()
	local b = self:FastSet()
	if not b then return nil end
	if b.kind == "sweep" then return SweepFilter(self, b), b end
	local f = {}
	for qid in pairs(b.quests) do f[qid] = true end
	-- ready ones from the set's own zone; ones handed in where the set goes join as
	-- town turn-ins. Never just because you're standing in their zone.
	for qid, e in pairs(self.log) do
		local q = self.Q[qid]
		if q and e.complete and not f[qid] then
			local z = q[K.ZONE] and (self:ZoneOf(q[K.ZONE]) or q[K.ZONE])
			if z == b.zone then f[qid] = true end
		end
	end
	return f, b
end

local TITLES = { fast = "Fastest XP", next = "Nearest set", pickup = "Pick up", objective = "Objectives", turnin = "Turn in", turnins = "Turn in all", zone = "Guide" }

---------------------------------------------------------------------------
-- Turn in all: every quest that's ready, in the order that takes the least
-- time from where you stand. Travel times come from the trip planner (walking,
-- your flight paths, boats, zeppelins, the tram; your hearthstone from where
-- you start), and the order is the best one there is for up to 10 places,
-- else a very good one.
---------------------------------------------------------------------------
local function TourCost(m, order)
	local c, at = 0, 0
	for _, j in ipairs(order) do c = c + m[at][j]; at = j end
	return c
end
local function BestTour(m, n)
	if n <= 1 then return n == 1 and { 1 } or {} end
	if n <= 10 then
		-- exact: the best path over every subset (Held-Karp)
		local full = 2 ^ n - 1
		local cost, back = {}, {}
		local bit = {}
		for i = 1, n do bit[i] = 2 ^ (i - 1) end
		for i = 1, n do cost[bit[i] * 16 + i] = m[0][i] end
		for set = 1, full do
			for last = 1, n do
				local c = cost[set * 16 + last]
				if c and c < math.huge then
					for nx = 1, n do
						if floor(set / bit[nx]) % 2 == 0 then
							local key = (set + bit[nx]) * 16 + nx
							local v = c + m[last][nx]
							if not cost[key] or v < cost[key] then cost[key], back[key] = v, last end
						end
					end
				end
			end
		end
		local bestLast, best = nil, math.huge
		for last = 1, n do local c = cost[full * 16 + last] if c and c < best then bestLast, best = last, c end end
		if bestLast then
			local order, set, last = {}, full, bestLast
			while last do
				table.insert(order, 1, last)
				local prev = back[set * 16 + last]
				set = set - bit[last]
				last = prev
			end
			return order
		end
	end
	-- many places: nearest first, then untangled (2-opt) until nothing improves
	local order, used, at = {}, {}, 0
	for _ = 1, n do
		local bj, bd
		for j = 1, n do if not used[j] and (not bd or m[at][j] < bd) then bj, bd = j, m[at][j] end end
		used[bj] = true; order[#order + 1] = bj; at = bj
	end
	local improved, guard = true, 0
	while improved and guard < 50 do
		improved, guard = false, guard + 1
		local base = TourCost(m, order)
		for i = 1, n - 1 do
			for j = i + 1, n do
				local o = {}
				for k = 1, i - 1 do o[k] = order[k] end
				for k = i, j do o[k] = order[j - (k - i)] end
				for k = j + 1, n do o[k] = order[k] end
				local c = TourCost(m, o)
				if c < base - 0.5 then order, base, improved = o, c, true end
			end
		end
	end
	return order
end

P._BestTour = BestTour
function P:TurnInOrder(stops)
	local pts, keep = {}, {}
	for _, st in ipairs(stops) do
		if st.inst and st.wx then
			pts[#pts + 1] = { inst = st.inst, x = st.wx, y = st.wy, zone = st.map and (self:ZoneOf(st.map) or st.map) }
			keep[#keep + 1] = st
		end
	end
	local m = self.TravelMatrix and self:TravelMatrix(pts)
	if not m then return stops end
	-- unreachable pairs (no way known): a long way, but still in the list
	for i = 0, #pts do for j = 1, #pts do if m[i][j] == math.huge then m[i][j] = 3600 end end end
	local order, out = BestTour(m, #pts), {}
	for _, i in ipairs(order) do out[#out + 1] = keep[i] end
	return out, TourCost(m, order)
end

-- "Turn in all · 6 · about 9 min"
function P:TurnInTitle(n, secs)
	local t = "Turn in all · " .. n
	if secs and secs > 0 and secs < 3600 * 3 then t = t .. " · about " .. math.max(1, math.floor(secs / 60 + 0.5)) .. " min" end
	return t
end

function P:ReadyCount()
	local n = 0
	for qid, e in pairs(self.log or EMPTY) do
		if e.complete and not self:Hidden(qid) and not self:Marked("turnins", qid) then n = n + 1 end
	end
	return n
end

-- start (or stop) the turn-in run; whatever guide you're on waits and comes back after
function P:TurnInAll()
	if self.route and self.route.mode == "turnins" then self.cdb.turnins = nil; self:StopRoute() return end
	return self:StartRoute("turnins", { detour = true })
end

-- mode: next | pickup | objective | turnin | zone ;  opts: map (zone guide), quiet, single (one stop)
function P:StartRoute(mode, opts)
	opts = opts or {}
	local s = S()
	local inst, px, py = self:PlayerPos()
	if not inst then
		if not opts.quiet then self:Toast("Pathway can't see where you are right now") end
		return false
	end
	local map = mode == "zone" and (opts.map or self:PlayerZone()) or opts.map
	local filter = opts.quests
	local fastSet
	if mode == "fast" and not filter and not opts.single then
		filter, fastSet = self:FastFilter()
		opts.quests = nil
	elseif filter then
		local copy = {}
		for k, v in pairs(filter) do copy[k] = v end
		filter = copy
		if opts.guide and (opts.guide:find("^quest:") or opts.guide:find("^chain:") or opts.guide:find("^dungeon:")) then ASKED[filter] = true end
		-- (a storyline is only its chain: no extra pickups, even right next to you)
		if not (opts.guide and opts.guide:find("^story:")) then AddGiversHere(filter, inst, px, py) end
	end
	local stops
	if opts.single then
		if not PlaceStop(opts.single, inst, px, py, nil, true) then
			if not opts.quiet then self:Toast("Pathway doesn't know where that is") end
			return false
		end
		stops = { opts.single }
	elseif mode == "flights" then
		stops = self:FlightStops(inst, px, py)
	elseif mode == "turnins" then
		stops = self:Stops(self.MODES.turnins, nil, nil, true)
	else
		stops = self:Stops(self.MODES[mode] or ALL, map, filter)
		-- a guide for somewhere else (another continent): the trip planner takes you there
		if #stops == 0 and (mode == "guide" or mode == "zone" or mode == "fast") then stops = self:Stops(self.MODES[mode] or ALL, map, filter, true) end
		if mode ~= "fast" then stops = FocusStops(stops, inst, px, py, filter) end
		if fastSet then self:SweepStops(fastSet, stops) end
		-- Fastest XP: a set with nothing left the guide can do is finished; on to the next one
		if #stops == 0 and fastSet and self.cdb then
			self.cdb.fastSet = nil
			filter, fastSet = self:FastFilter()
			if filter then
				stops = self:Stops(self.MODES.fast, nil, filter)
				if #stops == 0 then stops = self:Stops(self.MODES.fast, nil, filter, true) end
				self:SweepStops(fastSet, stops)
			end
		end
	end
	if #stops == 0 then
		if not opts.quiet then
			self:Toast(mode == "zone" and ("Nothing left for you in " .. self:MapName(map))
				or mode == "guide" and "Nothing in this guide you can do right now"
				or mode == "flights" and "No undiscovered flight paths on this continent"
				or mode == "turnins" and "No quests ready to turn in"
				or "Nothing nearby right now")
		end
		-- a guide flowing on that has nothing left ends; anything else leaves your guide alone
		if P._cont then self:StopRoute(true) end
		return false
	end
	sort(stops, function(a, b) return score(a) < score(b) end)
	local set
	if mode == "zone" or mode == "guide" or mode == "flights" then
		set = {}
		for i = 1, min(#stops, 30) do set[i] = stops[i] end
	elseif opts.single then
		set = stops
	else
		local first = stops[1]
		set = { first }
		for i = 2, #stops do
			local x = stops[i]
			if #set >= s.maxStops then break end
			if sqrt((x.wx - first.wx) ^ 2 + (x.wy - first.wy) ^ 2) <= s.setRadius then set[#set + 1] = x end
		end
	end
	-- a one-off stop (a fishing spot, the nearest repair, your corpse) is a detour:
	-- the guide you were on waits and comes back when you get there
	local paused
	if (opts.single or opts.detour) and self.route then paused = (self.route.single or self.route.detour) and self.route.paused or self.route end
	if mode == "fast" then set = self:FastOrder(stops, px, py) end
	local tourSecs
	if mode == "turnins" then set, tourSecs = self:TurnInOrder(stops) end
	self.route = { mode = mode, map = map, stops = (mode == "fast" or mode == "turnins") and set or NearestNeighbour(set, px, py), total = #set, single = opts.single and true,
		quests = filter, guide = opts.guide, paused = paused, detour = opts.detour }
	self.route.title = opts.title or (mode == "zone" and (self:MapName(map) .. " guide"))
		or (fastSet and self:FastTitle(fastSet)) or TITLES[mode]
	if mode == "turnins" then
		self.route.title = self:TurnInTitle(#set, tourSecs)
		self.cdb.turnins = true                     -- picked up again after a reload
	end
	if not (opts.single or opts.detour) then
		self.cdb.turnins = nil                       -- a new guide of your own: no turn-in run to come back to
		self.cdb.route = { mode = mode, map = map, guide = opts.guide, title = opts.title }
		self:Track(self.route, self.cdb.route)
	end
	self:AddTownTurnIns(self.route)
	if s.sound and not opts.quiet then PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN or 875) end
	if self.MaybeAddFlightPath then self:MaybeAddFlightPath() end
	self:MaybeAddFlight()
	if self.MaybeAddHearthStep then self:MaybeAddHearthStep() end
	self:Send("ROUTE_CHANGED")
	return true
end

function P:StopRoute(silent)
	if not self.route then return end
	if self.route.mode == "turnins" and self.cdb then self.cdb.turnins = nil end
	if self.route.paused then                     -- stopping a detour goes back to the guide
		self.route = self.route.paused
		self:Send("ROUTE_CHANGED")
		if not silent then self:Toast("Back to " .. (self.route.title or "your route")) end
		return
	end
	local t = self.track
	if t then
		self:CloseTrack(t, silent)
		return
	end
	self.route = nil
	self.cdb.route = nil
	self:Send("ROUTE_CHANGED")
	if not silent then self:Toast("Navigation stopped") end
end

---------------------------------------------------------------------------
-- Tracks: the guides you're following side by side (the tabs on the guide
-- window). One is active; the others wait where you left them.
---------------------------------------------------------------------------
P.tracks = {}
local MAX_TRACKS = 5

local function TrackKey(spec)
	if spec.guide then return spec.guide end
	if spec.mode == "zone" then return "zone:" .. (spec.map or 0) end
	return spec.mode
end

local function SaveTracks()
	if not P.cdb then return end
	local list = {}
	for i, t in ipairs(P.tracks) do
		list[i] = t.spec
		if t == P.track then P.cdb.activeTrack = i end
	end
	P.cdb.tracks = list
end

function P:Track(route, spec)
	local key = TrackKey(spec)
	local t
	if P._cont and self.track then
		t = self.track
	else
		for _, x in ipairs(self.tracks) do if x.key == key then t = x break end end
	end
	if not t then
		t = {}
		self.tracks[#self.tracks + 1] = t
		if #self.tracks > MAX_TRACKS then
			for i, x in ipairs(self.tracks) do if x ~= t then tremove(self.tracks, i) break end end
		end
	end
	t.key, t.spec, t.route = key, spec, route
	self.track = t
	SaveTracks()
end

-- start (or pick up again) the route a track describes
local function Resume(t)
	local spec = t.spec
	P._cont = true
	P.track = t
	local ok
	if spec.guide and P.LoadGuide then ok = P:LoadGuide(spec.guide, true)
	else ok = P:StartRoute(spec.mode, { map = spec.map, quiet = true, title = spec.title }) end
	P._cont = false
	return ok
end

function P:SwitchTrack(t)
	if not t or (t == self.track and self.route) then return end
	self.track = t
	if t.route and #t.route.stops > 0 then
		self.route = t.route
		self.cdb.route = t.spec
		SaveTracks()
		self:RefreshRoute()
		self:Send("ROUTE_CHANGED")
	elseif not Resume(t) then
		self:CloseTrack(t, true)
		self:Toast((t.spec.title or "That guide") .. ": nothing to do there right now")
	end
end

function P:CloseTrack(t, silent)
	for i, x in ipairs(self.tracks) do if x == t then tremove(self.tracks, i) break end end
	if self.track == t then
		self.track = nil
		self.route = nil
		self.cdb.route = nil
		local nextT = self.tracks[#self.tracks]
		if nextT then
			SaveTracks()
			self:SwitchTrack(nextT)
			if not silent and self.track then self:Toast("Back to " .. (self.route and self.route.title or "your guide")) end
			return
		end
		if not silent then self:Toast("Navigation stopped") end
	end
	SaveTracks()
	self:Send("ROUTE_CHANGED")
end

-- a guide's next part (the next chain of the story) belongs in the same tab
function P:Continue(fn)
	P._cont = true
	local ok, r = pcall(fn)
	P._cont = false
	if not ok then geterrorhandler()(r) end
	return r
end

function P:Current() return self.route and self.route.stops[1] end
-- where the arrow and the paths point: your corpse while you're a ghost, else the guide's step
function P:Target() return self.corpse or (self.route and self.route.stops[1]) end

---------------------------------------------------------------------------
-- "Done": you say a step is finished (the quest isn't really there, you did
-- it another way, the data is wrong). It never comes back for this character;
-- the notification it leaves can undo it.
---------------------------------------------------------------------------
function P:Marked(kind, id)
	local m = self.cdb and self.cdb.marked
	return m and m[kind] and m[kind][id] or false
end

function P:MarkStepDone(s)
	s = s or self:Current()
	if not s then return end
	local label = self:StopLabel(s) or "Step"
	local m = self.cdb.marked or {}
	self.cdb.marked = m
	m.quests, m.turnins, m.steps = m.quests or {}, m.turnins or {}, m.steps or {}
	local undo = { steps = {}, quests = {}, turnins = {} }
	local function mark(kind, id) if not m[kind][id] then m[kind][id] = true; undo[kind][#undo[kind] + 1] = id end end
	if s.flight then
		-- "I already know this one": it's a flight path you have, so it's used from now on
		self.cdb.flights[s.flight] = true
		self:Send("FLIGHTS_CHANGED")
		mark("steps", s.key)
	elseif s.quest then
		mark("steps", s.key)
	elseif s.pick or s.turn then
		for _, qid in ipairs(s.pick or EMPTY) do mark("quests", qid) end
		for _, qid in ipairs(s.turn or EMPTY) do mark("turnins", qid) end
	elseif s.key then
		mark("steps", s.key)
	end
	if self.Notify then
		self:Notify({ key = "marked:" .. (s.key or label), kind = "info", text = "Marked done: " .. label,
			action = { "Undo", function()
				for kind, ids in pairs(undo) do for _, id in ipairs(ids) do m[kind][id] = nil end end
				self:RefreshRoute(); self:Send("QUESTS_CHANGED")
				return true
			end } })
	end
	local r = self.route
	if r and r.stops[1] == s then tremove(r.stops, 1) end
	self:RefreshRoute()
end

-- the quests a step is about: the one it works on, or the ones waiting at its NPC
function P:StepQuests(s)
	local ids = {}
	if not s then return ids end
	if s.quest then ids[1] = s.quest
	elseif s.key and not (s.flight or s.trip or s.travel or s.goal) then
		local pick, turn = self:EntityWork(s.key)
		for _, qid in ipairs(pick) do ids[#ids + 1] = qid end
		for _, qid in ipairs(turn) do ids[#ids + 1] = qid end
	end
	return ids
end

-- left out of every guide: marked completed (for good) or skipped (until your next level)
function P:Hidden(qid)
	local c = self.cdb
	return c and ((c.never and c.never[qid]) or (c.skipQ and c.skipQ[qid])) or false
end
function P:HiddenCount()
	local n, s = 0, 0
	for _ in pairs(self.cdb and self.cdb.never or EMPTY) do n = n + 1 end
	for _ in pairs(self.cdb and self.cdb.skipQ or EMPTY) do s = s + 1 end
	return n, s
end
function P:BringBack(qid)
	local c = self.cdb
	if not c then return end
	if qid then
		if c.never then c.never[qid] = nil end
		if c.skipQ then c.skipQ[qid] = nil end
	else
		c.never, c.skipQ = {}, {}
	end
	self:Send("QUESTS_CHANGED")
end

local function Names(ids)
	local q = P.Q[ids[1]]
	local name = q and q[K.NAME] or "This quest"
	if #ids > 1 then name = name .. " +" .. (#ids - 1) end
	return name
end

-- "Mark completed": this step's quests never come back on this character
function P:NeverStep(s)
	s = s or self:Current()
	local ids = self:StepQuests(s)
	if #ids == 0 then return self:MarkStepDone(s) end
	return self:NeverQuests(ids)
end
function P:NeverQuests(ids)
	local c = self.cdb
	c.never = c.never or {}
	for _, qid in ipairs(ids) do c.never[qid] = true end
	if self.Notify then
		self:Notify({ key = "never:" .. ids[1], kind = "info", text = "Marked completed: " .. Names(ids) .. ". It won't come back on this character.",
			action = { "Undo", function() for _, qid in ipairs(ids) do c.never[qid] = nil end; self:Send("QUESTS_CHANGED"); return true end } })
	end
	self:Send("QUESTS_CHANGED")
end

-- Skip: the step's quests stay out of every guide until your next level
-- (a trip or a flight path is only skipped for this guide)
function P:SkipStop()
	local r = self.route
	if not r or not r.stops[1] then return end
	local s = r.stops[1]
	local ids = self:StepQuests(s)
	tremove(r.stops, 1)
	r.skipped = r.skipped or {}
	r.skipped[s.key] = true
	if s.flight then P.fpSkipped = P.fpSkipped or {}; P.fpSkipped[s.key] = true end
	if #ids > 0 then
		local c = self.cdb
		c.skipQ = c.skipQ or {}
		for _, qid in ipairs(ids) do c.skipQ[qid] = true end
		self:Toast("Skipped: " .. Names(ids) .. ". Left out until your next level.")
		self:Send("QUESTS_CHANGED")
	else
		self:RefreshRoute()
	end
end
P:On("PLAYER_LEVEL_UP", function() if P.cdb and P.cdb.skipQ then wipe(P.cdb.skipQ); P:Send("QUESTS_CHANGED") end end)
-- "Done" marks for quests you've since turned in mean nothing any more: tidied away at login,
-- so the list never grows past what's still in play
P:On("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
	if not (isLogin or isReload) then return end
	C_Timer.After(10, function()
		local m = P.cdb and P.cdb.marked
		if not m then return end
		for _, kind in ipairs({ "quests", "turnins" }) do
			for qid in pairs(m[kind] or EMPTY) do if P.done[qid] then m[kind][qid] = nil end end
		end
	end)
end)

-- new work that appeared near the route (a quest you just accepted, one you
-- just finished, a follow-up that opened) joins it, like a guide would
local function MergeNearby(r)
	local inst, px, py = P:PlayerPos()
	if not inst then return end
	local have = {}
	for k in pairs(r.skipped or EMPTY) do have[k] = true end
	for _, s in ipairs(r.stops) do have[s.key] = true end
	local added = false
	local limit = max(S().maxStops, #r.stops) + 4
	if r.mode == "flights" then return end
	if r.quests and not r.single and r.mode ~= "fast" and not (r.guide and r.guide:find("^story:")) then AddGiversHere(r.quests, inst, px, py) end
	local candidates = P:Stops(P.MODES[r.mode] or ALL, r.map, r.quests)
	if r.mode ~= "fast" then candidates = FocusStops(candidates, inst, px, py, r.quests) end
	for _, s in ipairs(candidates) do
		if #r.stops >= limit then break end
		if not have[s.key] and (r.mode == "zone" or r.mode == "guide" or s.dist <= S().setRadius) then
			r.stops[#r.stops + 1] = s
			r.total = r.total + 1
			added = true
		end
	end
	if added then
		local lead = r.stops[1] and (r.stops[1].travel or r.stops[1].trip) and table.remove(r.stops, 1)
		r.stops = NearestNeighbour(r.stops, px, py)
		if lead then table.insert(r.stops, 1, lead) end
	end
end

-- drop finished stops, pick up new nearby work; continue or finish
function P:RefreshRoute()
	local r = self.route
	if not r then return end
	if not self:RouteShown() then return end              -- nothing shows it: it catches up when turned back on
	for i = #r.stops, 1, -1 do
		if self:StopDone(r.stops[i]) then tremove(r.stops, i) end
	end
	if r.mode == "fast" then
		-- fastest experience: worked out fresh from where you stand
		local inst, px, py = self:PlayerPos()
		if inst then
			local lead = r.stops[1] and (r.stops[1].travel or r.stops[1].trip) and r.stops[1]
			local all = {}
			local f, set = self:FastFilter()
			r.quests = f
			if set then r.title = self:FastTitle(set) end
			local got = self:Stops(self.MODES.fast, nil, f)
			if #got == 0 and f then got = self:Stops(self.MODES.fast, nil, f, true) end     -- the set's on the other continent
			self:SweepStops(set, got)
			if #got == 0 and set and self.cdb then
				-- nothing left the guide can do for this set: it's finished, on to the next one
				self.cdb.fastSet = nil
				f, set = self:FastFilter()
				r.quests = f
				if set then
					r.title = self:FastTitle(set)
					got = self:Stops(self.MODES.fast, nil, f)
					if #got == 0 then got = self:Stops(self.MODES.fast, nil, f, true) end
					self:SweepStops(set, got)
				end
			end
			for _, s in ipairs(got) do if not (r.skipped and r.skipped[s.key]) then all[#all + 1] = s end end
			r.stops = self:FastOrder(all, px, py)
			if lead then table.insert(r.stops, 1, lead) end
			r.total = math.max(r.total, #r.stops)
		end
	elseif r.mode == "turnins" then
		-- a quest that becomes ready on the way joins the run, and the order is worked out again
		local have = {}
		for _, st in ipairs(r.stops) do if st.key then have[st.key] = true end end
		local more, any = {}, false
		for _, st in ipairs(self:Stops(self.MODES.turnins, nil, nil, true)) do
			if not have[st.key] and not (r.skipped and r.skipped[st.key]) then more[#more + 1] = st; any = true end
		end
		if any then
			local lead = r.stops[1] and (r.stops[1].travel or r.stops[1].trip) and tremove(r.stops, 1)
			for _, st in ipairs(r.stops) do more[#more + 1] = st end
			local secs
			r.stops, secs = self:TurnInOrder(more)
			if lead then table.insert(r.stops, 1, lead) end
			r.total = r.total + 1
			r.title = self:TurnInTitle(#r.stops, secs)
		end
	elseif not r.single then MergeNearby(r) end
	self:AddTownTurnIns(r)
	if self.MaybeAddFlightPath then self:MaybeAddFlightPath() end
	self:MaybeAddFlight()
	if self.MaybeAddHearthStep then self:MaybeAddHearthStep() end
	if #r.stops == 0 and r.mode == "turnins" then self.cdb.turnins = nil end
	if #r.stops == 0 and r.paused then
		self.route = r.paused                     -- back to your guide
		self:Toast("Back to " .. (self.route.title or "your route"))
		self:RefreshRoute()
		return
	end
	if #r.stops == 0 and r.single then             -- a one-off place, and no guide waiting
		self.route = nil
		self:Toast("You're there")
		self:Send("ROUTE_CHANGED")
		return
	end
	if #r.stops == 0 then
		local mode, map = r.mode, r.map
		self.route = nil
		-- a guide flows on: a chain into the rest of the zone's story, the story chain by chain
		if r.guide and not r.single and self.NextGuide then
			local nextKey = self:NextGuide(r.guide)
			if nextKey and self:Continue(function() return self:LoadGuide(nextKey, true) end) then
				self:Toast("Next: " .. (self.route and self.route.title or "your guide"))
				return
			end
		end
		if S().autoContinue and not r.single then
			if self:Continue(function() return self:StartRoute(mode, { map = map, quiet = true, quests = r.quests, guide = r.guide, title = r.title }) end) then
				self:Toast(mode == "zone" and "Next steps in your guide" or "On to the next set")
				return
			end
		end
		self.cdb.route = nil
		if self.track and self.track.route == r then
			-- this tab is done: on to the next one you're following
			local t = self.track
			for i, x in ipairs(self.tracks) do if x == t then tremove(self.tracks, i) break end end
			self.track = nil
			SaveTracks()
			local nextT = self.tracks[#self.tracks]
			if nextT then
				self:Toast(((r.title or "Guide") .. ": done for now"))
				self:Send("GUIDE_DONE", r)
				self:SwitchTrack(nextT)
				return
			end
		end
		self:Toast(mode == "zone" and ("You've done everything here for now")
			or mode == "guide" and ((r.title or "Guide") .. ": done for now")
			or "All caught up nearby")
		self:Send("GUIDE_DONE", r)
		if S().sound then PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878) end
	end
	self:Send("ROUTE_CHANGED")
end

-- objective stops follow the nearest mob/object as you move
function P:Retarget()
	local s = self:Current()
	if not s or not s.quest or s.point or s.travel then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local before, beforePt = s.at, s.atPt
	PlaceStop(s, inst, px, py)
	if s.at ~= before or s.atPt ~= beforePt then self:Send("TARGET_CHANGED") end
end

---------------------------------------------------------------------------
-- Map markers for the world map
---------------------------------------------------------------------------
local markerCache = {}
function P:Markers(map, all)
	local ck = all and (map .. "a") or map
	local m = markerCache[ck]
	if m then return m end
	-- a cave, building or floor inside a zone: the zone's pins, where they fall on it
	local zone = self:SubMapZone(map)
	if zone then
		m = self:OnSubMap(map, zone, self:Markers(zone, all))
		markerCache[ck] = m
		return m
	end
	m = {}
	local s = all and { pinTurnins = true, pinPickups = true, pinObjectives = true } or S()
	local function addEntity(kind, id, mk, quests)
		local e = self:Entity(kind, id)
		local pts = e and e[2] and e[2][map]
		if not pts then return end
		for i = 1, #pts do
			local x, y = Unpack(pts[i])
			m[#m + 1] = { kind = mk, x = x, y = y, ent = { kind, id }, name = e[1], quests = quests }
		end
	end
	if s.pinTurnins then
		for qid, e in pairs(self.log) do
			local q = self.Q[qid]
			if q and e.complete then
				for _, id in ipairs(q[K.EN] or EMPTY) do addEntity("N", id, "turnin", { qid }) end
				for _, id in ipairs(q[K.EO] or EMPTY) do addEntity("O", id, "turnin", { qid }) end
			end
		end
	end
	if s.pinPickups then
		for _, qid in ipairs(self:AvailableList()) do
			local q = self.Q[qid]
			for _, id in ipairs(q[K.SN] or EMPTY) do addEntity("N", id, "pickup", { qid }) end
			for _, id in ipairs(q[K.SO] or EMPTY) do addEntity("O", id, "pickup", { qid }) end
		end
	end
	if s.pinObjectives then
		for qid, e in pairs(self.log) do
			if not e.complete then
				for _, t in ipairs(self:ObjectiveTargets(qid)) do
					if t.point then
						if t.point[1] == map then m[#m + 1] = { kind = "objective", x = t.point[2], y = t.point[3], quests = { qid }, text = t.text, point = t.point, index = t.index } end
					else
						local n = 0
						for _, ent in ipairs(t.ents) do
							local e2 = self:Entity(ent[1], ent[2])
							local pts = e2 and e2[2] and e2[2][map]
							if pts then
								for i = 1, #pts, (#pts > 12 and 2 or 1) do
									local x, y = Unpack(pts[i])
									m[#m + 1] = { kind = "objective", x = x, y = y, ent = ent, name = e2[1], quests = { qid }, text = t.text, index = t.index, ents = t.ents }
									n = n + 1
									if n >= 16 then break end
								end
							end
							if n >= 16 then break end
						end
					end
				end
			end
		end
	end
	-- merge pickups at the same NPC into one pin
	local seen, out = {}, {}
	for _, mk in ipairs(m) do
		local key = mk.kind ~= "objective" and (mk.kind .. mk.ent[1] .. mk.ent[2] .. floor(mk.x * 1000) .. floor(mk.y * 1000))
		if key and seen[key] then
			tinsert(seen[key].quests, mk.quests[1])
		else
			if key then seen[key] = mk end
			out[#out + 1] = mk
		end
	end
	markerCache[ck] = out
	return out
end

-- counts for the map bar, for one zone
function P:ZoneCounts(map)
	local pick, obj, turn = 0, 0, 0
	local seen = {}
	for _, mk in ipairs(self:Markers(map, true)) do
		for _, qid in ipairs(mk.quests) do
			local key = mk.kind .. qid
			if not seen[key] then
				seen[key] = true
				if mk.kind == "pickup" then pick = pick + 1 elseif mk.kind == "turnin" then turn = turn + 1 else obj = obj + 1 end
			end
		end
	end
	return pick, obj, turn
end

---------------------------------------------------------------------------
-- Keep everything fresh
---------------------------------------------------------------------------
function P:Invalidate()
	availCache = nil
	wipe(markerCache)
end

P:Listen("QUESTS_CHANGED", function()
	P:InferDone()          -- what's done may have changed (a hand-in, a login, a quest you marked)
	P:Invalidate()
	P:RefreshRoute()
	P:Send("MARKERS_CHANGED")
end)
-- objective counts only: what you can pick up is the same; the route and the
-- markers follow your progress
P:Listen("QUEST_PROGRESS", function()
	wipe(markerCache)
	P:RefreshRoute()
	P:Send("MARKERS_CHANGED")
end)
P:Listen("SETTINGS_CHANGED", function()
	P:Invalidate()
	P:Send("MARKERS_CHANGED")
end)

---------------------------------------------------------------------------
-- Arriving: one light watcher for the whole guide (whether or not the arrow
-- is shown). A place you were sent to (a mailbox, a flight master, the bank)
-- is done when you get there or use it, and the guide you were on comes back.
---------------------------------------------------------------------------
local USED = {
	MAIL_SHOW = "mail", TAXIMAP_OPENED = "flight", MERCHANT_SHOW = "vendor", BANKFRAME_OPENED = "bank",
	AUCTION_HOUSE_SHOW = "auction", TRAINER_SHOW = "trainer", PET_STABLE_SHOW = "stable", CONFIRM_XP_LOSS = "spirit",
}
local function UsedIt()
	local s = P:Current()
	if not (s and s.find) then return end
	local inst, px, py = P:PlayerPos()
	if inst and s.wx and P.Vector(px, py, s.wx, s.wy) > 60 then return end   -- something else, somewhere else
	s.used = true
	P:RefreshRoute()
end
for ev in pairs(USED) do P:On(ev, UsedIt) end

-- Is any part that shows your route switched on? With the arrow, the guide
-- window, the quest bar, the magic button and the map paths and pins all off,
-- nothing would show it, so the route's background work rests.
function P:RouteShown()
	local s = self.db and self.db.settings
	if not s then return false end
	-- the guide and the arrow both off (the path button on the minimap bar): everything
	-- that follows the route rests with them: the magic button, the paths, the route math
	if s.arrow == false and s.guideWindow == false then return false end
	return true
end
-- the route, when something is showing it
function P:LiveRoute() return self.route and self:RouteShown() and self.route or nil end
local wasShown = true
P:Listen("SETTINGS_CHANGED", function()
	local now = P:RouteShown()
	if now and not wasShown and P.route then P:RefreshRoute() end       -- back on: catch up at once
	wasShown = now
end)

local watchT, aimT, planT = 0, 0, 0
local forcedKey, forcedAt = nil, 0
local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function(_, dt)
	watchT, aimT, planT = watchT + dt, aimT + dt, planT + dt
	if watchT < 0.5 then return end
	P:FastClock(math.min(watchT, 5))
	watchT = 0
	local s = P.route and P.route.stops[1]
	if not s or not P:RouteShown() then return end
	local fight = InCombatLockdown()
	-- arrived somewhere: move the guide on. The same step forcing a refresh again within 10 s
	-- means the refresh couldn't finish it; asking again twice a second would only redraw it all.
	local now = GetTime()
	local function Force()
		if forcedKey == s.key and now - forcedAt < 10 then return end
		forcedKey, forcedAt = s.key, now
		P:RefreshRoute()
	end
	if s.goal and not s.trip and Arrived(s, s.reach or 15) then
		Force()
	elseif s.trip and P:TripDone(s) then
		-- a hearth or a ride that ends in the same zone (no loading screen to tell us)
		Force()
	elseif s.quest then
		-- standing at an object spot: once you've had a moment to look, it's checked
		if s.at and s.at[1] == "O" and s.atPt and Arrived(s, 12) then
			if s.dwellPt == s.atPt then
				s.dwell = (s.dwell or 0) + 1
				if s.dwell >= 4 then                   -- about 2 seconds there
					P:CheckSpot(s.map, s.atPt)
					s.dwell, s.dwellPt = 0, nil
					aimT = 2
				end
			else
				s.dwellPt, s.dwell = s.atPt, 0
			end
		end
		if aimT > 1.5 and not fight then           -- objectives follow the nearest mob or object (after a fight)
			aimT = 0
			P:Retarget()
		end
	end
	if planT > 3 and P.ReplanTrip and not fight then   -- the fastest way there, as you move (not mid-fight)
		planT = 0
		P:ReplanTrip()
	end
end)
P.Perf.Hook(watcher, "Quest routes", "OnUpdate")

-- pick the route back up after a reload
P:On("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
	if (isLogin or isReload) and P.cdb and (P.cdb.tracks or P.cdb.route) then
		local specs, active = P.cdb.tracks, P.cdb.activeTrack
		if not specs or #specs == 0 then specs, active = { P.cdb.route }, 1 end
		C_Timer.After(3, function()
			if P.route then return end
			wipe(P.tracks)
			for _, spec in ipairs(specs) do
				if type(spec) == "table" and spec.mode then P.tracks[#P.tracks + 1] = { key = TrackKey(spec), spec = spec } end
			end
			local t = P.tracks[active or #P.tracks] or P.tracks[#P.tracks]
			if t then P:SwitchTrack(t) end
		end)
	end
	-- a turn-in run you were on: back on it, with your guide waiting behind it
	if (isLogin or isReload) and P.cdb and P.cdb.turnins then
		C_Timer.After(4, function()
			if P.route and P.route.mode == "turnins" then return end
			if P:ReadyCount() == 0 then P.cdb.turnins = nil return end
			P:StartRoute("turnins", { detour = true, quiet = true })
		end)
	end
end)
end part() end
-- ==================== Travel.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Travel
     Flight paths. Pathway remembers every flight master you've talked to, and
     when your next stop is far away it checks whether flying beats running.
     If it does, a travel step is added in front: go to the flight master, fly
     to the one nearest your goal, and carry on from there. ]]

local ADDON, P = __addon, __ns
local Unpack = P.Unpack
local sqrt = math.sqrt

local function S() return P.db.settings end


---------------------------------------------------------------------------
-- Known flight masters
---------------------------------------------------------------------------
local function MyLetter() return P.me.faction == "Horde" and "H" or "A" end

local function FMWorld(id)
	local fm = P.FM[id]
	if not fm then return end
	local x, y = Unpack(fm[3])
	return P:WorldPos(fm[2], x, y)
end

local function NpcIdFromGUID(guid)
	if not guid then return end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind == "Creature" then return tonumber(id) end
end

-- learn flight masters: the one you're talking to, plus every node you can fly to.
-- At login too, where the game will say (so a fresh install knows your flights
-- before you ever open a flight map)
-- strict: only nodes the game plainly says you've discovered (the login list
-- can include flight points you've never been to)
local function Learn(getNodes, strict)
	if not (P.cdb and C_TaxiMap and Enum and Enum.FlightPathState) then return 0 end
	local known, n0 = P.cdb.flights, 0
	for _ in pairs(P.cdb.flights) do n0 = n0 + 1 end
	do
		for _, cont in ipairs({ 1414, 1415 }) do
			local ok, nodes = pcall(getNodes, cont)
			if ok and type(nodes) == "table" then
				for _, n in ipairs(nodes) do
					local discovered = n.state ~= Enum.FlightPathState.Unreachable and not n.isUndiscovered
					if strict then discovered = discovered and n.isUndiscovered == false end
					if discovered and n.position then
						local inst, wx, wy = P:WorldPos(cont, n.position.x, n.position.y)
						if inst then
							-- the flight master standing closest to this node
							local best, bd
							for id, fm in pairs(P.FM) do
								if fm[4]:find(MyLetter(), 1, true) then
									local i2, x2, y2 = FMWorld(id)
									if i2 == inst then
										local d = (x2 - wx) ^ 2 + (y2 - wy) ^ 2
										if not bd or d < bd then best, bd = id, d end
									end
								end
							end
							if best and bd < 250 * 250 then
								known[best] = true
								-- the node's own name, to look up how long flights took
								if n.name and P.db then P.db.fmNode = P.db.fmNode or {}; P.db.fmNode[best] = n.name end
							end
						end
					end
				end
			end
		end
	end
	local n1 = 0
	for _ in pairs(known) do n1 = n1 + 1 end
	if n1 ~= n0 then P:Send("FLIGHTS_CHANGED") end
	return n1
end

-- The flight map is the truth: what it offers you is known; a flight point
-- Pathway thought you knew but the map doesn't offer is forgotten (and any
-- route through it is worked out again).
local function FromFlightMap()
	if not P.cdb then return end
	local here = NpcIdFromGUID(UnitGUID("npc"))
	if here and P.FM[here] then P.cdb.flights[here] = true end
	local offered, spots = {}, {}
	local any = false
	-- the classic way: every node on the open map and whether you can fly there
	local taxiMap = GetTaxiMapID and GetTaxiMapID()
	if NumTaxiNodes and TaxiNodeGetType and TaxiNodeName then
		for i = 1, NumTaxiNodes() do
			local kind = TaxiNodeGetType(i)
			local name = TaxiNodeName(i)
			if name and (kind == "REACHABLE" or kind == "CURRENT") then
				offered[name] = true; any = true
				if taxiMap and TaxiNodePosition then
					local x, y = TaxiNodePosition(i)
					local i2, wx, wy = P:WorldPos(taxiMap, x, y)
					if i2 then spots[#spots + 1] = { i2, wx, wy } end
				end
			end
		end
	end
	local function Offered(id)
		local nm = P.db and P.db.fmNode and P.db.fmNode[id]
		if nm and offered[nm] then return true end
		local i, wx, wy = FMWorld(id)
		for _, sp in ipairs(spots) do
			if sp[1] == i and (sp[2] - wx) ^ 2 + (sp[3] - wy) ^ 2 < 250 * 250 then return true end
		end
		-- no way to tell (no name learned and no position): keep it
		return not nm and #spots == 0
	end
	if C_TaxiMap and C_TaxiMap.GetAllTaxiNodes then Learn(C_TaxiMap.GetAllTaxiNodes) end
	if not any then return end
	local before = {}
	for k in pairs(P.cdb.flights) do before[k] = true end
	-- forget what the map doesn't offer, on this continent (by the node names learned above)
	local inst = P:PlayerPos()
	local dropped = false
	for id in pairs(before) do
		if id ~= here and FMWorld(id) == inst and not Offered(id) then P.cdb.flights[id] = nil; dropped = true end
	end
	if dropped then
		P:Send("FLIGHTS_CHANGED")
		if P.route then
			-- a flight leg through a flight point you don't have goes away and is planned again
			for i = #P.route.stops, 1, -1 do
				local s = P.route.stops[i]
				if s.travel and s.flyTo and not P.cdb.flights[s.flyTo] then table.remove(P.route.stops, i) end
			end
			P:RefreshRoute()
		end
	end
end
P:On("TAXIMAP_OPENED", FromFlightMap)

P:On("PLAYER_ENTERING_WORLD", function()
	C_Timer.After(3, function()
		if not P.cdb then return end
		-- flight paths you said you know (Done on a flight master step) count as known
		for k in pairs(P.cdb.marked and P.cdb.marked.steps or {}) do
			local id = tonumber(tostring(k):match("^fm(%d+)$"))
			if id and P.FM[id] then P.cdb.flights[id] = true end
		end
		local n = 0
		if C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
			local before = {}
			for k, v in pairs(P.cdb.flights) do before[k] = v end
			n = Learn(C_TaxiMap.GetTaxiNodesForMap, true)
			-- if the game listed every flight master of your faction (known or not),
			-- it can't tell us which you know: forget what it said
			local mine = 0
			for _, fm in pairs(P.FM) do if fm[4]:find(MyLetter(), 1, true) then mine = mine + 1 end end
			if mine > 0 and n >= mine * 0.85 and (UnitLevel("player") or 1) < 50 then
				wipe(P.cdb.flights)
				for k, v in pairs(before) do P.cdb.flights[k] = v end
				n = 0
				for _ in pairs(before) do n = n + 1 end
			end
		end
		if n == 0 then for _ in pairs(P.cdb.flights) do n = n + 1 end end
		-- still none known past the first levels: one word on how Pathway learns them
		if P.route then P:RefreshRoute() end
		if n == 0 and (UnitLevel("player") or 1) >= 10 and not P.cdb.flightHint then
			P.cdb.flightHint = true
			P:Notify({ title = "Your flight paths", text = "Talk to any flight master once: Pathway learns every flight path you know, and takes them whenever they're faster." })
		end
	end)
end)

-- standing at a flight master, going somewhere far, and Pathway doesn't know
-- your flight paths yet: one look at the flight map fixes that
function P:FlightMasterTip(s)
	if not (s and s.dist and s.dist > 600) or s.travel or s.trip then return end
	if self:KnownFlights() > 1 then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	for id in pairs(self.FM) do
		local i, wx, wy = FMWorld(id)
		if i == inst and (wx - px) ^ 2 + (wy - py) ^ 2 < 250 * 250 then
			return "Talk to " .. (self.FM[id][1] or "the flight master") .. " once: Pathway learns your flight paths and flies you there"
		end
	end
end

function P:KnownFlights()
	local n = 0
	for _ in pairs(self.cdb.flights) do n = n + 1 end
	return n
end

function P:TravelDone(s)
	if UnitOnTaxi and UnitOnTaxi("player") then return false end
	local inst, px, py = self:PlayerPos()
	if not inst then return false end
	if sqrt((s.bx - px) ^ 2 + (s.by - py) ^ 2) < 400 then return true end
	local d = s.dest
	if d and d.wx and sqrt((d.wx - px) ^ 2 + (d.wy - py) ^ 2) < sqrt((d.wx - s.bx) ^ 2 + (d.wy - s.by) ^ 2) + 150 then return true end
	return false
end

-- (P:MaybeAddFlight, which picks the fastest way to your next stop, lives in Trip.lua)

-- while you're in the air, say where you're headed
P:On("PLAYER_CONTROL_LOST", function() P:Send("ROUTE_CHANGED") end)
P:On("PLAYER_CONTROL_GAINED", function() C_Timer.After(1, function() P:RefreshRoute() end) end)

---------------------------------------------------------------------------
-- Every flight master for your faction, discovered or not
---------------------------------------------------------------------------
local flightCache
P:Listen("FLIGHTS_CHANGED", function() flightCache = nil end)
function P:FlightList()
	if flightCache then return flightCache end
	local out = {}
	local me = MyLetter()
	for id, fm in pairs(self.FM) do
		if fm[4]:find(me, 1, true) then
			local x, y = Unpack(fm[3])
			local inst, wx, wy = self:WorldPos(fm[2], x, y)
			out[#out + 1] = { id = id, name = fm[1], map = fm[2], x = x, y = y, inst = inst, wx = wx, wy = wy,
				known = self.cdb.flights[id] == true }
		end
	end
	table.sort(out, function(a, b)
		local za, zb = self:MapName(a.map), self:MapName(b.map)
		if za ~= zb then return za < zb end
		return a.name < b.name
	end)
	if out[1] and out[1].inst then flightCache = out end
	return out
end

-- a route through the flight paths you haven't found yet, on this continent
function P:FlightStops(inst, px, py)
	local stops = {}
	for _, f in ipairs(self:FlightList()) do
		if not f.known and f.inst == inst then
			local s = { key = "fm" .. f.id, flight = f.id, ents = { { "N", f.id } }, name = f.name, point = { f.map, f.x, f.y } }
			if P.PlaceStop(s, inst, px, py) then stops[#stops + 1] = s end
		end
	end
	return stops
end

-- a learned flight path closes its stop and refreshes the pins
P:On("TAXIMAP_OPENED", function()
	C_Timer.After(0.2, function()
		if P.route then P:RefreshRoute() end
		P:Send("MARKERS_CHANGED")
		P:Send("FLIGHTS_CHANGED")
	end)
end)

---------------------------------------------------------------------------
-- A flight path you haven't found, right by where you're going (or where you
-- are): it joins the guide as a stop. Skip it once and it stays out.
---------------------------------------------------------------------------
local NEAR_ME, NEAR_ROUTE, DETOUR = 300, 220, 150
local told = {}
function P:MaybeAddFlightPath()
	local r = self.route
	if not (r and r.stops and S().flights ~= false and S().flightStops ~= false) then return end
	if r.mode == "flights" or r.single or UnitOnTaxi("player") then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local have = {}
	for _, s in ipairs(r.stops) do if s.flight then have[s.flight] = true end end
	for _, fp in ipairs(self:FlightList()) do
		if not fp.known and fp.inst == inst and not have[fp.id] then
			local key = "fm" .. fp.id
			if not ((r.skipped and r.skipped[key]) or (P.fpSkipped and P.fpSkipped[key])) then
				-- only on the guide's way: near one of its stops, or a short detour on the
				-- way to the next. Close to you but the other way doesn't count.
				local nearMe = (fp.wx - px) ^ 2 + (fp.wy - py) ^ 2 < NEAR_ME * NEAR_ME
				local onWay, i = self:OnTheWay(inst, fp.wx, fp.wy, NEAR_ROUTE, DETOUR)
				local after = onWay and i and i > 0 and i or nil
				nearMe = nearMe and onWay and not after
				if nearMe or after then
					local stop = { key = key, flight = fp.id, ents = { { "N", fp.id } }, name = fp.name, point = { fp.map, fp.x, fp.y } }
					if P.PlaceStop(stop, inst, px, py) then
						-- right away if it's next to you, else just after the stop it's next to
						local at = nearMe and 1 or (after + 1)
						if r.stops[1] and r.stops[1].travel and at == 1 then at = 2 end
						table.insert(r.stops, math.min(at, #r.stops + 1), stop)
						r.total = r.total + 1
						if not told[fp.id] then
							told[fp.id] = true
							self:Toast("Flight path nearby: " .. fp.name .. " added to your guide")
						end
						return true
					end
				end
			end
		end
	end
end

-- check now and then as you travel
C_Timer.NewTicker(4, function()
	if P.db and P.route and P:RouteShown() and P:MaybeAddFlightPath() then P:Send("ROUTE_CHANGED") end
end)

---------------------------------------------------------------------------
-- On the flight map: a bobbing arrow and a glow over the flight point your
-- guide wants you to fly to, with "Fly here" under it. Works on both flight
-- maps (the newer map with pins and the classic one with buttons). Only
-- while the map is open; nothing runs otherwise.
---------------------------------------------------------------------------
local mark
local function Mark()
	if mark then return mark end
	mark = CreateFrame("Frame", "PathwayFlyHere", UIParent)
	mark:SetSize(36, 36)
	mark:EnableMouse(false)
	mark.glow = mark:CreateTexture(nil, "BACKGROUND")
	mark.glow:SetTexture(P.MEDIA .. "Ring"); mark.glow:SetSize(40, 40); mark.glow:SetPoint("CENTER")
	mark.arrow = mark:CreateTexture(nil, "OVERLAY")
	mark.arrow:SetTexture(P.MEDIA .. "Arrow"); mark.arrow:SetSize(30, 30)
	mark.arrow:SetRotation(math.pi)                 -- pointing down at the flight point
	mark.arrow:SetPoint("BOTTOM", mark, "TOP", 0, 2)
	mark.text = mark:CreateFontString(nil, "OVERLAY")
	mark.text:SetFontObject(P.fonts and P.fonts.button or GameFontNormalSmall)
	mark.text:SetPoint("TOP", mark, "BOTTOM", 0, -2)
	mark.text:SetShadowOffset(1, -1)
	-- a gentle bob and a slow pulse on the glow
	local bob = mark.arrow:CreateAnimationGroup()
	bob:SetLooping("BOUNCE")
	local up = bob:CreateAnimation("Translation"); up:SetOffset(0, 6); up:SetDuration(0.45); up:SetSmoothing("IN_OUT")
	mark.bob = bob
	local pulse = mark.glow:CreateAnimationGroup()
	pulse:SetLooping("BOUNCE")
	local a = pulse:CreateAnimation("Alpha"); a:SetFromAlpha(1); a:SetToAlpha(0.35); a:SetDuration(0.7)
	mark.pulse = pulse
	mark:Hide()
	return mark
end

-- the flight point your guide is sending you to, if any
local function Wanted()
	local s = P.route and P.route.stops[1]
	if s and s.travel and s.flyTo and P.FM[s.flyTo] then return s end
end

-- is this flight map node that flight master? By the node's name when
-- Pathway knows it, else by where it is (within a short walk)
local function IsNode(s, name, mapID, x, y)
	local nm = P.db and P.db.fmNode and P.db.fmNode[s.flyTo]
	if nm and name and name == nm then return true end
	if mapID and x and y then
		local i, wx, wy = P:WorldPos(mapID, x, y)
		local i2, fx, fy = FMWorld(s.flyTo)
		if i and i == i2 and (wx - fx) ^ 2 + (wy - fy) ^ 2 < 250 * 250 then return true end
	end
	return false
end

local function Show(anchor, s)
	local m = Mark()
	m:SetParent(anchor:GetParent() or UIParent)
	m:SetFrameStrata(anchor:GetFrameStrata())
	m:SetFrameLevel((anchor:GetFrameLevel() or 1) + 20)
	m:ClearAllPoints()
	m:SetPoint("CENTER", anchor, "CENTER")
	local A = P.ACCENT or { 0.21, 0.82, 0.5 }
	m.arrow:SetVertexColor(A[1], A[2], A[3], 1)
	m.glow:SetVertexColor(A[1], A[2], A[3], 0.9)
	m.text:SetText("|cffffffffFly here|r")
	m:Show()
	m.bob:Play(); m.pulse:Play()
end

local function Hide()
	if mark then mark.bob:Stop(); mark.pulse:Stop(); mark:Hide() end
end

local function PointAtIt(tries)
	Hide()
	local s = Wanted()
	if not s then return end
	-- the newer flight map: one pin per flight point
	local fm = _G.FlightMapFrame
	if fm and fm:IsShown() and fm.EnumeratePinsByTemplate then
		local mapID = fm.GetMapID and fm:GetMapID()
		local found
		for pin in fm:EnumeratePinsByTemplate("FlightMap_FlightPointPinTemplate") do
			local d = pin.taxiNodeData
			if d and IsNode(s, d.name, mapID, d.position and d.position.x, d.position and d.position.y) then found = pin break end
		end
		if found then Show(found, s) return end
	end
	-- the classic flight map: one button per flight point
	local tf = _G.TaxiFrame
	if tf and tf:IsShown() and NumTaxiNodes then
		local mapID = GetTaxiMapID and GetTaxiMapID()
		for i = 1, NumTaxiNodes() do
			local b = _G["TaxiButton" .. i]
			if b and b:IsShown() then
				local x, y
				if TaxiNodePosition then x, y = TaxiNodePosition(i) end
				if IsNode(s, TaxiNodeName and TaxiNodeName(i), mapID, x, y) then Show(b, s) return end
			end
		end
	end
	-- the map fills in its pins a moment after it opens
	if (tries or 0) < 4 then C_Timer.After(0.25, function() PointAtIt((tries or 0) + 1) end) end
end
P.PointAtFlight = PointAtIt

P:On("TAXIMAP_OPENED", function() C_Timer.After(0.05, function() PointAtIt(0) end) end)
P:On("TAXIMAP_CLOSED", Hide)
P:Listen("ROUTE_CHANGED", function()
	local fm, tf = _G.FlightMapFrame, _G.TaxiFrame
	if (fm and fm:IsShown()) or (tf and tf:IsShown()) then PointAtIt(3) end
end)
end part() end
-- ==================== Walk.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — How far is it really, on foot?
     A straight line across a continent goes through mountains and sea. Here
     every zone knows the roads and passes into its neighbors, so the trip
     planner compares real walks with the tram, boats, zeppelins and flights:
     Stormwind to Dun Morogh is the tram, not a climb over Blackrock.
     Zones it doesn't know fall back to a straight line. ]]

local ADDON, P = __addon, __ns
local sqrt, huge, min = math.sqrt, math.huge, math.min

-- { zone, zone, a point on the border (map, x, y) }
local GATES = {
	-- Eastern Kingdoms
	{ 1453, 1429, 1429, 0.320, 0.495 },   -- Stormwind gate
	{ 1429, 1436, 1429, 0.245, 0.790 },   -- Elwynn - Westfall bridge
	{ 1429, 1431, 1429, 0.395, 0.930 },   -- Elwynn - Duskwood road
	{ 1429, 1433, 1429, 0.935, 0.715 },   -- Three Corners
	{ 1433, 1431, 1429, 0.935, 0.715 },   -- Three Corners: Redridge - Duskwood (the road south to Darkshire)
	{ 1429, 1431, 1429, 0.935, 0.715 },   -- Three Corners: Elwynn - Duskwood
	{ 1436, 1431, 1431, 0.070, 0.500 },   -- Westfall - Duskwood (Raven Hill road)
	{ 1431, 1430, 1431, 0.900, 0.420 },   -- Duskwood - Deadwind Pass
	{ 1431, 1434, 1434, 0.385, 0.035 },   -- Duskwood - Stranglethorn
	{ 1430, 1435, 1435, 0.050, 0.620 },   -- Deadwind - Swamp of Sorrows
	{ 1433, 1435, 1435, 0.260, 0.080 },   -- Redridge - Swamp of Sorrows
	{ 1433, 1428, 1428, 0.880, 0.800 },   -- Redridge - Burning Steppes
	{ 1435, 1419, 1419, 0.500, 0.100 },   -- Swamp of Sorrows - Blasted Lands
	{ 1428, 1427, 1428, 0.220, 0.350 },   -- Blackrock Mountain
	{ 1427, 1418, 1418, 0.020, 0.480 },   -- Searing Gorge - Badlands
	{ 1418, 1432, 1432, 0.460, 0.960 },   -- Badlands - Loch Modan
	{ 1432, 1426, 1426, 0.865, 0.510 },   -- South Gate tunnel
	{ 1426, 1455, 1426, 0.535, 0.345 },   -- Gates of Ironforge
	{ 1432, 1437, 1437, 0.505, 0.885 },   -- Dun Algaz
	{ 1437, 1417, 1417, 0.445, 0.915 },   -- Thandol Span
	{ 1417, 1424, 1424, 0.875, 0.470 },   -- Arathi - Hillsbrad
	{ 1424, 1425, 1425, 0.080, 0.600 },   -- Hillsbrad - Hinterlands
	{ 1424, 1416, 1424, 0.550, 0.200 },   -- Hillsbrad - Alterac
	{ 1424, 1421, 1424, 0.130, 0.470 },   -- Hillsbrad - Silverpine
	{ 1421, 1420, 1420, 0.540, 0.880 },   -- Silverpine - Tirisfal
	{ 1420, 1458, 1420, 0.620, 0.700 },   -- Undercity
	{ 1420, 1422, 1422, 0.280, 0.560 },   -- Tirisfal - Western Plaguelands
	{ 1416, 1422, 1422, 0.450, 0.880 },   -- Alterac - Western Plaguelands
	{ 1422, 1423, 1423, 0.080, 0.600 },   -- Western - Eastern Plaguelands
	-- Kalimdor
	{ 1411, 1454, 1411, 0.455, 0.115 },   -- Orgrimmar gate
	{ 1411, 1413, 1411, 0.355, 0.430 },   -- Durotar - Barrens bridge
	{ 1413, 1412, 1413, 0.360, 0.290 },   -- Barrens - Mulgore
	{ 1412, 1456, 1412, 0.390, 0.300 },   -- Thunder Bluff lifts
	{ 1413, 1440, 1413, 0.480, 0.060 },   -- Barrens - Ashenvale
	{ 1413, 1442, 1413, 0.330, 0.220 },   -- Barrens - Stonetalon
	{ 1413, 1445, 1413, 0.680, 0.720 },   -- Barrens - Dustwallow
	{ 1413, 1441, 1413, 0.450, 0.970 },   -- Barrens - Thousand Needles
	{ 1440, 1442, 1440, 0.070, 0.700 },   -- Ashenvale - Stonetalon
	{ 1440, 1439, 1439, 0.440, 0.940 },   -- Ashenvale - Darkshore
	{ 1440, 1448, 1448, 0.520, 0.950 },   -- Ashenvale - Felwood
	{ 1440, 1447, 1440, 0.950, 0.470 },   -- Ashenvale - Azshara
	{ 1448, 1452, 1448, 0.640, 0.080 },   -- Timbermaw Hold
	{ 1448, 1450, 1448, 0.630, 0.060 },   -- Felwood - Moonglade
	{ 1442, 1443, 1443, 0.550, 0.060 },   -- Stonetalon - Desolace
	{ 1443, 1444, 1443, 0.460, 0.970 },   -- Desolace - Feralas
	{ 1444, 1441, 1444, 0.880, 0.420 },   -- Feralas - Thousand Needles
	{ 1441, 1446, 1446, 0.510, 0.220 },   -- Thousand Needles - Tanaris
	{ 1446, 1449, 1446, 0.270, 0.530 },   -- Tanaris - Un'Goro
	{ 1449, 1451, 1449, 0.290, 0.220 },   -- Un'Goro - Silithus
	{ 1438, 1457, 1438, 0.370, 0.550 },   -- Darnassus
}

local KNOWN, built = {}, false
local gates, byZone, G = {}, {}, {}      -- gate list, gates per zone, gate-to-gate distances

local function Build()
	built = true
	for _, g in ipairs(GATES) do KNOWN[g[1]] = true; KNOWN[g[2]] = true end
	for _, g in ipairs(GATES) do
		local inst, wx, wy = P:WorldPos(g[3], g[4], g[5])
		if inst then
		local n = { a = g[1], b = g[2], inst = inst, x = wx, y = wy }
		gates[#gates + 1] = n
		for _, z in ipairs({ g[1], g[2] }) do
			byZone[z] = byZone[z] or {}
			table.insert(byZone[z], #gates)
		end
		end
	end
	if #gates == 0 then built = false return end     -- maps not ready yet: try again later
	-- all-pairs shortest walks between gates (Floyd–Warshall: ~50 gates, done once)
	local n = #gates
	for i = 1, n do
		G[i] = {}
		for j = 1, n do
			local a, b = gates[i], gates[j]
			if i == j then G[i][j] = 0
			elseif a.inst == b.inst and (a.a == b.a or a.a == b.b or a.b == b.a or a.b == b.b) then
				G[i][j] = sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
			else G[i][j] = huge end
		end
	end
	for k = 1, n do
		local Gk = G[k]
		for i = 1, n do
			local Gi = G[i]
			local ik = Gi[k]
			if ik < huge then
				for j = 1, n do
					local d = ik + Gk[j]
					if d < Gi[j] then Gi[j] = d end
				end
			end
		end
	end
end

-- yards on foot from (zone a, world x, y) to (zone b, world x, y) on one continent;
-- math.huge when there is no way on foot (an island, the other side of the sea)
function P:WalkYards(za, ax, ay, zb, bx, by)
	if not (ax and ay and bx and by) then return huge end
	local straight = sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
	if za == zb or not za or not zb then return straight end
	if not built then Build() end
	if not (built and KNOWN[za] and KNOWN[zb]) then return straight * 1.15 end
	local ga, gb = byZone[za], byZone[zb]
	if not (ga and gb) then return straight * 1.15 end
	local best = huge
	for _, i in ipairs(ga) do
		local gi = gates[i]
		local d1 = sqrt((gi.x - ax) ^ 2 + (gi.y - ay) ^ 2)
		if d1 < best then
			local Gi = G[i]
			for _, j in ipairs(gb) do
				local mid = Gi[j]
				if mid < huge then
					local gj = gates[j]
					local d = d1 + mid + sqrt((bx - gj.x) ^ 2 + (by - gj.y) ^ 2)
					if d < best then best = d end
				end
			end
		end
	end
	return best
end

P.WALK_KNOWN = KNOWN
end part() end
-- ==================== Trip.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Getting there fastest
     For your next stop, Pathway weighs every way of getting there and takes
     the quickest: running (or riding), the flight paths you know, boats,
     zeppelins and the tram, your hearthstone, and teleports you know (mage
     teleports, a druid's Moonglade, a shaman's Astral Recall). It works across
     continents, one leg at a time: each leg becomes a step in your guide, and
     the next leg is planned when you arrive. ]]

local ADDON, P = __addon, __ns
local sqrt, huge, floor, max, min = math.sqrt, math.huge, math.floor, math.max, math.min
local Unpack = P.Unpack

local function S() return P.db.settings end

local FLY, FLY_BEND, AT_MASTER = 24, 1.25, 10     -- taxi speed, how much taxi routes bend, a word with the flight master
local CAST, LOADING = 10, 15                      -- a hearth or teleport cast, a loading screen
-- Effort, not just the clock: a minute on a flight, boat or tram is a minute you
-- sit back, so it weighs about a third of a minute's running. A flight that's a
-- little slower than running but takes the running away wins. Never one that's
-- far slower: see SLOWER.
local EASE = 0.35
local SLOWER, SLOWER_ADD = 1.6, 120               -- at most this much longer on the clock than running
local function Easy() return S().easyTravel ~= false end
P.TRAVEL_EASE = EASE

-- Boats, zeppelins and the tram: both ends, the ride, and who can use them.
-- (map, x, y) of where you board; ride includes the usual wait.
local TRANSPORT = {
	{ name = "Boat to Theramore", back = "Boat to Menethil Harbor", kind = "boat",
		a = { 1437, 0.050, 0.635 }, b = { 1445, 0.716, 0.564 }, ride = 180, who = "AH" },
	{ name = "Boat to Auberdine", back = "Boat to Menethil Harbor", kind = "boat",
		a = { 1437, 0.046, 0.571 }, b = { 1439, 0.324, 0.438 }, ride = 180, who = "AH" },
	{ name = "Boat to Rut'theran Village", back = "Boat to Auberdine", kind = "boat",
		a = { 1439, 0.332, 0.402 }, b = { 1438, 0.549, 0.940 }, ride = 120, who = "AH" },
	{ name = "Boat to Ratchet", back = "Boat to Booty Bay", kind = "boat",
		a = { 1434, 0.259, 0.731 }, b = { 1413, 0.637, 0.386 }, ride = 180, who = "AH" },
	{ name = "Zeppelin to Undercity", back = "Zeppelin to Orgrimmar", kind = "zeppelin",
		a = { 1411, 0.508, 0.137 }, b = { 1420, 0.607, 0.588 }, ride = 180, who = "AH" },
	{ name = "Zeppelin to Grom'gol", back = "Zeppelin to Orgrimmar", kind = "zeppelin",
		a = { 1411, 0.506, 0.125 }, b = { 1434, 0.316, 0.291 }, ride = 180, who = "AH" },
	{ name = "Zeppelin to Grom'gol", back = "Zeppelin to Undercity", kind = "zeppelin",
		a = { 1420, 0.619, 0.591 }, b = { 1434, 0.314, 0.301 }, ride = 150, who = "AH" },
	-- Forever's Stormwind Harbor: the southern-most dock, boats to Auberdine (world yards: instance, x, y)
	{ name = "Boat to Auberdine", back = "Boat to Stormwind Harbor", kind = "boat",
		a = { 1453, w = { 0, 1330.1, -8645.4 } }, b = { 1439, w = { 1, 929.1, 6543.6 } }, ride = 200, who = "A" },
	{ name = "Deeprun Tram to Ironforge", back = "Deeprun Tram to Stormwind", kind = "tram",
		a = { 1453, 0.692, 0.314 }, b = { 1455, 0.765, 0.514 }, ride = 90, who = "AH" },
	-- Feralas: the ferry between the Forgotten Coast and Feathermoon Stronghold
	{ name = "Ferry to Feathermoon Stronghold", back = "Ferry to the Forgotten Coast", kind = "boat",
		a = { 1444, 0.433, 0.428 }, b = { 1444, 0.311, 0.393 }, ride = 75, who = "AH" },
}
P.TRANSPORT = TRANSPORT

-- teleports: spell, where it lands
local TELEPORT = {
	{ spell = 3561, to = { 1453, 0.39, 0.80 } },   -- Teleport: Stormwind
	{ spell = 3562, to = { 1455, 0.27, 0.07 } },   -- Teleport: Ironforge
	{ spell = 3565, to = { 1457, 0.40, 0.82 } },   -- Teleport: Darnassus
	{ spell = 3567, to = { 1454, 0.39, 0.86 } },   -- Teleport: Orgrimmar
	{ spell = 3563, to = { 1458, 0.84, 0.17 } },   -- Teleport: Undercity
	{ spell = 3566, to = { 1456, 0.22, 0.17 } },   -- Teleport: Thunder Bluff
	{ spell = 18960, to = { 1450, 0.44, 0.45 } },  -- Teleport: Moonglade
}
local HEARTH, ASTRAL = 6948, 556
-- engineering: items that drop you somewhere (they're on a long cooldown, so
-- only counted when ready)
local GADGETS = {
	{ item = 18986, to = { 1446, 0.516, 0.288 }, label = "Ultrasafe Transporter: Gadgetzan" },
	{ item = 18984, to = { 1452, 0.612, 0.384 }, label = "Dimensional Ripper: Everlook" },
}

local function W(p)
	if p.w then return p.w[1], p.w[2], p.w[3] end
	return P:WorldPos(p[1], p[2], p[3])
end
-- where to stand for a ride, as a map point
local function MapPoint(p)
	if p.w then
		local x, y = P:MapPos(p[1], p.w[2], p.w[3])
		return { p[1], x or 0.5, y or 0.5 }
	end
	return { p[1], p[2], p[3] }
end
local function Z(map) return P:ZoneOf(map) end

local function SpellKnown(id)
	if IsSpellKnown then return IsSpellKnown(id) end
	return IsPlayerSpell and IsPlayerSpell(id)
end
local function Ready(start, dur) return not dur or dur == 0 or (start + dur - GetTime()) < 20 end
local function SpellReady(id)
	if C_Spell and C_Spell.GetSpellCooldown then
		local cd = C_Spell.GetSpellCooldown(id)
		return not cd or Ready(cd.startTime, cd.duration)
	end
	return Ready(GetSpellCooldown(id))
end
local function ItemReady(id)
	if (P.Item.GetItemCount or GetItemCount)(id) == 0 then return false end
	local get = C_Container and C_Container.GetItemCooldown or GetItemCooldown
	return Ready(get(id))
end
local function Speed()
	local lvl = UnitLevel("player") or 1
	local base = lvl >= 40 and 10 or 7    -- riding from 40, on foot before
	-- already faster (a mount, a speed buff, travel form): use that
	local ok, sp = pcall(GetUnitSpeed or function() return 0 end, "player")
	if ok and type(sp) == "number" and not (issecretvalue and issecretvalue(sp)) and sp > base and sp < 40 then return sp end
	return base
end
P.TravelSpeed = Speed

-- a flight you've taken before: how long it really took (GoodMap times every flight)
local function Flown(a, b)
	local names = P.db and P.db.fmNode
	local db = _G.PathwayMapDB
	if not (names and db and db.flights and names[a] and names[b]) then return end
	return db.flights[names[a] .. ">" .. names[b]]
end
local function Name(id)
	local get = C_Spell and C_Spell.GetSpellName or function(x) return (GetSpellInfo(x)) end
	return get(id) or "Teleport"
end

---------------------------------------------------------------------------
-- The graph: you, your goal, flight masters you know, both ends of every
-- transport. Walking joins anything on the same continent.
---------------------------------------------------------------------------
local function Plan(goal)
	local inst, px, py = P:PlayerPos()
	if not inst or not goal.inst then return end
	local nodes = {}
	local function add(n) nodes[#nodes + 1] = n; return n end
	local here = P:PlayerZone()
	local start = add({ inst = inst, x = px, y = py, start = true, zone = here })
	local target = add({ inst = goal.inst, x = goal.wx, y = goal.wy, goal = true, zone = Z(goal.map) })
	local fms = {}
	if S().flights then
		for id in pairs(P.cdb.flights) do
			local fm = P.FM[id]
			if fm then
				local x, y = Unpack(fm[3])
				local i, wx, wy = P:WorldPos(fm[2], x, y)
				if i then fms[#fms + 1] = add({ inst = i, x = wx, y = wy, fm = id, zone = Z(fm[2]) }) end
			end
		end
	end
	local rides = {}
	local letter = (P.me and P.me.faction == "Horde") and "H" or "A"
	for _, t in ipairs(TRANSPORT) do
		local ia, ax, ay = W(t.a)
		local ib, bx, by = W(t.b)
		if ia and ib and (not t.who or t.who:find(letter, 1, true)) then
			local A = add({ inst = ia, x = ax, y = ay, dock = t, side = "a", zone = Z(t.a[1]) })
			local B = add({ inst = ib, x = bx, y = by, dock = t, side = "b", zone = Z(t.b[1]) })
			rides[#rides + 1] = { A, B, t }
		end
	end
	local jumps = {}
	local h = P:HearthKnown()
	if S().hearthHints ~= false and h and ItemReady(HEARTH) then
		local i, hx, hy = P:WorldPos(h.map, h.x, h.y)
		if i then jumps[#jumps + 1] = { node = add({ inst = i, x = hx, y = hy, zone = Z(h.map) }), cost = CAST + (i ~= inst and LOADING or 0),
			use = { item = HEARTH }, label = "Hearth to " .. (h.name or "your inn") } end
		if SpellKnown(ASTRAL) and SpellReady(ASTRAL) and i then
			jumps[#jumps + 1] = { node = jumps[#jumps].node, cost = CAST + (i ~= inst and LOADING or 0),
				use = { spell = ASTRAL }, label = "Astral Recall to " .. (h.name or "your inn") }
		end
	end
	for _, g in ipairs(GADGETS) do
		if ItemReady(g.item) then
			local i, x, y = W(g.to)
			if i then jumps[#jumps + 1] = { node = add({ inst = i, x = x, y = y, zone = Z(g.to[1]) }), cost = CAST + LOADING,
				use = { item = g.item }, label = g.label } end
		end
	end
	for _, t in ipairs(TELEPORT) do
		if SpellKnown(t.spell) and SpellReady(t.spell) then
			local i, x, y = W(t.to)
			if i then jumps[#jumps + 1] = { node = add({ inst = i, x = x, y = y, zone = Z(t.to[1]) }), cost = CAST + LOADING,
				use = { spell = t.spell }, label = Name(t.spell) } end
		end
	end

	-- Dijkstra (a few dozen nodes: plain arrays are plenty)
	local speed = Speed()
	local ease = Easy() and EASE or 1
	local dist, clock, prev, how, done = {}, {}, {}, {}, {}
	for i = 1, #nodes do dist[i] = huge end
	dist[1], clock[1] = 0, 0
	local index = {}
	for i, n in ipairs(nodes) do index[n] = i end
	-- secs on the clock; sitting: time you sit back (counts at ease for the effort)
	local function relax(u, vNode, secs, step, sitting)
		local v = index[vNode]
		local cost = sitting and (secs - sitting + sitting * ease) or secs
		if dist[u] + cost < dist[v] then dist[v], clock[v], prev[v], how[v] = dist[u] + cost, clock[u] + secs, u, step end
	end
	for _ = 1, #nodes do
		local u, best = nil, huge
		for i = 1, #nodes do if not done[i] and dist[i] < best then u, best = i, dist[i] end end
		if not u then break end
		done[u] = true
		local n = nodes[u]
		if n.goal then break end
		-- walk / ride to anything you can reach on foot (roads and passes, not through mountains)
		for _, m in ipairs(nodes) do
			if m ~= n and m.inst == n.inst and not m.start then
				local yd = P:WalkYards(n.zone, n.x, n.y, m.zone, m.x, m.y)
				if yd < huge then relax(u, m, yd / speed, { walk = true }) end
			end
		end
		-- fly between known masters
		if n.fm then
			for _, m in ipairs(fms) do
				if m ~= n and m.inst == n.inst then
					local secs = Flown(n.fm, m.fm) or sqrt((m.x - n.x) ^ 2 + (m.y - n.y) ^ 2) * FLY_BEND / FLY
					relax(u, m, secs + AT_MASTER, { fly = m.fm, from = n.fm, secs = secs }, secs)
				end
			end
		end
		-- ride a boat, zeppelin or tram
		for _, r in ipairs(rides) do
			if r[1] == n then relax(u, r[2], r[3].ride, { ride = r[3], from = r[1], to = r[2], label = r[3].name }, r[3].ride) end
			if r[2] == n then relax(u, r[1], r[3].ride, { ride = r[3], from = r[2], to = r[1], label = r[3].back }, r[3].ride) end
		end
		-- hearth and teleports, from where you stand
		if n.start then for _, j in ipairs(jumps) do relax(u, j.node, j.cost, { jump = j }) end end
	end
	if dist[2] == huge then return end
	-- walk back from the goal to the first leg that isn't just walking
	local chain, v = {}, 2
	while prev[v] do table.insert(chain, 1, { node = nodes[v], step = how[v], fromNode = nodes[prev[v]], secs = clock[v] - clock[prev[v]] }); v = prev[v] end
	local walkOnly = (inst == goal.inst) and P:WalkYards(here, px, py, target.zone, goal.wx, goal.wy) / speed or huge
	-- the clock time, running the whole way, and the effort the chosen way takes
	return chain, clock[2], walkOnly, dist[2]
end

---------------------------------------------------------------------------
-- The next leg as a guide step
---------------------------------------------------------------------------
local function Leg(chain, total, walkOnly, goal)
	local saves = walkOnly - total
	-- slower on the clock but you sit back for it: say how much of it you sit
	local sit = 0
	for _, c in ipairs(chain) do if c.step.fly or c.step.ride then sit = sit + c.secs end end
	local easier = saves <= 30 and walkOnly < huge and sit > 60 and sit or nil
	for i, c in ipairs(chain) do
		local st = c.step
		if st.jump then
			local _, px, py = P:PlayerPos()
			local map = P:PlayerZone()
			local mx, my = P:MapPos(map, px, py)
			return { key = "trip:jump:" .. (st.jump.use.item or st.jump.use.spell), trip = "jump", goal = st.jump.label,
				name = goal.name, point = { map, mx or 0.5, my or 0.5 }, reach = 1e9,
				useItem = st.jump.use.item, useSpell = st.jump.use.spell,
				arrive = { inst = c.node.inst, x = c.node.x, y = c.node.y }, saves = saves }
		elseif st.ride then
			local t = st.ride
			local from = (st.from.side == "a") and t.a or t.b
			return { key = "trip:ride:" .. st.label, trip = "ride", goal = "Take the " .. st.label:gsub("^(%a+) to", function(k) return k:lower() .. " to" end),
				name = t.kind == "tram" and "Deeprun Tram" or (t.kind == "zeppelin" and "Zeppelin tower" or "Dock"),
				point = MapPoint(from), reach = 30,
				arrive = { inst = st.to.inst, x = st.to.x, y = st.to.y }, saves = saves, easier = easier, ride = true, rideKind = t.kind }
		elseif st.fly then
			local a, b = P.FM[st.from], P.FM[st.fly]
			local ax, ay = Unpack(a[3])
			return { key = "fly" .. st.from .. ":" .. st.fly, travel = true, ents = { { "N", st.from } }, name = a[1],
				point = { a[2], ax, ay }, flyTo = st.fly, flyName = b[1], flyMap = b[2],
				bx = c.node.x, by = c.node.y, dest = goal, saves = saves, easier = easier }
		end
	end
end

function P:PlanTrip(dest)
	if not dest or dest.travel or dest.trip or not dest.wx then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local t = self:MapXform(dest.map)
	dest.inst = dest.inst or (t and t[1])
	if not dest.inst then return end
	local sameCont = dest.inst == inst
	if sameCont and P:WalkYards(self:PlayerZone(), px, py, self:ZoneOf(dest.map), dest.wx, dest.wy) < 700 then return end   -- close: just go
	local chain, total, walkOnly, effort = Plan(dest)
	if not chain then return end
	-- on the same continent, take it when it's clearly less work than running (a few
	-- percent, so a near tie doesn't flip back and forth as you move), and never
	-- when it's far slower on the clock
	if sameCont then
		if effort > walkOnly * 0.95 then return end
		if total > walkOnly * SLOWER + SLOWER_ADD then return end
	end
	return Leg(chain, total, walkOnly, dest)
end

-- Travel times between many places at once, for putting stops in the best
-- order: secs[i][j] from point i to point j, where point 0 is where you stand
-- (the only place your hearthstone and teleports count from: they're used once).
-- Same graph as the trip planner: walking, your flight paths, boats,
-- zeppelins and the tram. points: { { inst =, x =, y =, zone = }, ... }
function P:TravelMatrix(points)
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local nodes = {}
	local function add(n) nodes[#nodes + 1] = n; return n end
	local start = add({ inst = inst, x = px, y = py, zone = self:PlayerZone(), start = true, pt = 0 })
	for i, pt in ipairs(points) do add({ inst = pt.inst, x = pt.x, y = pt.y, zone = pt.zone, pt = i }) end
	local fms = {}
	if S().flights then
		for id in pairs(P.cdb.flights) do
			local fm = P.FM[id]
			if fm then
				local x, y = Unpack(fm[3])
				local i, wx, wy = P:WorldPos(fm[2], x, y)
				if i then fms[#fms + 1] = add({ inst = i, x = wx, y = wy, fm = id, zone = Z(fm[2]) }) end
			end
		end
	end
	local rides = {}
	local letter = (P.me and P.me.faction == "Horde") and "H" or "A"
	for _, t in ipairs(TRANSPORT) do
		local ia, ax, ay = W(t.a)
		local ib, bx, by = W(t.b)
		if ia and ib and (not t.who or t.who:find(letter, 1, true)) then
			rides[#rides + 1] = { add({ inst = ia, x = ax, y = ay, zone = Z(t.a[1]) }), add({ inst = ib, x = bx, y = by, zone = Z(t.b[1]) }), t.ride }
		end
	end
	local jumps = {}
	local h = P:HearthKnown()
	if S().hearthHints ~= false and h and ItemReady(HEARTH) then
		local i, hx, hy = P:WorldPos(h.map, h.x, h.y)
		if i then jumps[#jumps + 1] = { add({ inst = i, x = hx, y = hy, zone = Z(h.map) }), CAST + (i ~= inst and LOADING or 0) } end
	end
	for _, t in ipairs(TELEPORT) do
		if SpellKnown(t.spell) and SpellReady(t.spell) then
			local i, x, y = W(t.to)
			if i then jumps[#jumps + 1] = { add({ inst = i, x = x, y = y, zone = Z(t.to[1]) }), CAST + LOADING } end
		end
	end
	local n, speed = #nodes, Speed()
	local ease = Easy() and EASE or 1
	local index = {}
	for i, nd in ipairs(nodes) do index[nd] = i end
	-- every edge once: walking on one continent, flights, rides
	local edges = {}
	for i = 1, n do edges[i] = {} end
	for i = 1, n do
		local a = nodes[i]
		for j = 1, n do
			local b = nodes[j]
			if i ~= j and a.inst == b.inst and not b.start then
				local yd = P:WalkYards(a.zone, a.x, a.y, b.zone, b.x, b.y)
				if yd < huge then local e = edges[i]; e[#e + 1] = j; e[#e + 1] = yd / speed end
			end
		end
	end
	for _, a in ipairs(fms) do
		for _, b in ipairs(fms) do
			if a ~= b and a.inst == b.inst then
				local secs = Flown(a.fm, b.fm) or sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2) * FLY_BEND / FLY
				local e = edges[index[a]]; e[#e + 1] = index[b]; e[#e + 1] = secs * ease + AT_MASTER
			end
		end
	end
	for _, r in ipairs(rides) do
		local ea, eb = edges[index[r[1]]], edges[index[r[2]]]
		ea[#ea + 1] = index[r[2]]; ea[#ea + 1] = r[3] * ease
		eb[#eb + 1] = index[r[1]]; eb[#eb + 1] = r[3] * ease
	end
	local secs = {}
	for i = 0, #points do
		local src = i + 1
		local dist, done = {}, {}
		for k = 1, n do dist[k] = huge end
		dist[src] = 0
		if src == 1 then for _, j in ipairs(jumps) do local k = index[j[1]] if j[2] < dist[k] then dist[k] = j[2] end end end
		for _ = 1, n do
			local u, best = nil, huge
			for k = 1, n do if not done[k] and dist[k] < best then u, best = k, dist[k] end end
			if not u then break end
			done[u] = true
			local e = edges[u]
			for k = 1, #e, 2 do
				local v, d = e[k], best + e[k + 1]
				if d < dist[v] then dist[v] = d end
			end
		end
		local row = {}
		for j = 1, #points do row[j] = dist[j + 1] end
		secs[i] = row
	end
	return secs
end

-- the whole way to somewhere, for showing it: every leg in order with its time
-- (legs run together when they're the same kind: one run, not three)
function P:PlanWay(dest)
	if not (dest and dest.wx) then return end
	local t = self:MapXform(dest.map)
	dest.inst = dest.inst or (t and t[1])
	if not dest.inst then return end
	local chain, total, walkOnly, effort = Plan(dest)
	if not chain then return end
	local legs = {}
	local function NodeName(n)
		if n.goal then return dest.name or self:MapName(dest.map) end
		if n.fm and P.FM[n.fm] then return P.FM[n.fm][1] .. " (" .. self:MapName(P.FM[n.fm][2]) .. ")" end
		if n.dock then
			local t = n.dock
			local kind = t.kind == "tram" and "the Deeprun Tram" or (t.kind == "zeppelin" and "the zeppelin tower" or "the dock")
			return kind .. " in " .. self:MapName(n.side == "a" and t.a[1] or t.b[1])
		end
		return self:MapName(n.zone) or "there"
	end
	for _, c in ipairs(chain) do
		local st, last = c.step, legs[#legs]
		if st.walk then
			if last and last.kind == "walk" then last.secs = last.secs + c.secs; last.text = "Run to " .. NodeName(c.node)
			else legs[#legs + 1] = { kind = "walk", secs = c.secs, text = "Run to " .. NodeName(c.node) } end
		elseif st.fly then
			local b = P.FM[st.fly]
			if last and last.kind == "fly" then last.secs = last.secs + c.secs; last.text = "Fly to " .. (b and b[1] or "the next flight master")
			else legs[#legs + 1] = { kind = "fly", secs = c.secs, text = "Fly to " .. (b and b[1] or "the next flight master")
				.. (b and (" (" .. self:MapName(b[2]) .. ")") or "") } end
		elseif st.ride then
			legs[#legs + 1] = { kind = "ride", secs = c.secs, text = "Take the " .. st.label:gsub("^(%a+) to", function(k) return k:lower() .. " to" end) }
		elseif st.jump then
			legs[#legs + 1] = { kind = "jump", secs = c.secs, text = st.jump.label, item = st.jump.use.item, spell = st.jump.use.spell }
		end
	end
	-- a few steps at the end aren't a leg of their own
	for i = #legs, 1, -1 do
		if #legs > 1 and legs[i].kind == "walk" and legs[i].secs < 15 then table.remove(legs, i) end
	end
	return legs, total, walkOnly, effort
end

function P:TripDone(s)
	if UnitOnTaxi and UnitOnTaxi("player") then return false end
	local inst, px, py = self:PlayerPos()
	if not inst then return false end
	-- a hearth: you're in your inn, wherever Pathway thought it was
	if s.useItem == HEARTH and self.AtBind and self:AtBind() then return true end
	local a = s.arrive
	return a and inst == a.inst and sqrt((a.x - px) ^ 2 + (a.y - py) ^ 2) < 350
end

-- the first stop may have changed: is there a faster way there?
function P:MaybeAddFlight()
	local r = self.route
	local first = r and r.stops[1]
	if not first or first.travel or first.trip then return end
	-- a trip has a handful of different legs at most (the same leg planned
	-- again after a refresh doesn't count twice)
	r.legs = r.legs or {}
	local seen = r.legs[first.key]
	if type(seen) ~= "table" then seen = { n = 0 }; r.legs[first.key] = seen end
	local leg = self:PlanTrip(first)
	if not leg or (r.skipped and r.skipped[leg.key]) then return end
	if not seen[leg.key] then
		if seen.n >= 6 then return end
		seen[leg.key] = true
		seen.n = seen.n + 1
	end
	local inst, px, py = self:PlayerPos()
	if not P.PlaceStop(leg, inst, px, py, nil, true) then return end
	leg.planInst, leg.planX, leg.planY = inst, px, py
	table.insert(r.stops, 1, leg)
	r.total = r.total + 1
	if leg.easier then
		self:Toast(("%s: less running, about %d min sitting back"):format(leg.goal or ("Fly to " .. (leg.flyName or "")), max(1, floor(leg.easier / 60 + 0.5))))
	elseif leg.saves and leg.saves < 1e6 and leg.saves > 60 then
		local saves = tonumber(leg.saves)
		local mins = (saves and saves < 1e6) and max(1, floor(saves / 60 + 0.5)) or nil
		self:Toast(mins and ("%s: saves about %d min"):format(leg.goal or ("Fly to " .. (leg.flyName or "")), mins) or (leg.goal or ("Fly to " .. (leg.flyName or ""))))
	elseif leg.saves and leg.saves >= 1e6 then
		self:Toast("On the way: " .. (leg.goal or ("fly to " .. (leg.flyName or ""))))
	end
end

-- As you move, the fastest way can change: a flight master you're now close
-- to, a flight that's no longer worth it once you've run most of the way.
-- Checked every few seconds, but only worked out again once you've moved a
-- good stretch (or the next stop changed), so standing still costs nothing.
local lastKey, lastInst, lastX, lastY
function P:ReplanTrip()
	local r = self.route
	local first = r and r.stops[1]
	if not first or (UnitOnTaxi and UnitOnTaxi("player")) then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	if first.travel then
		-- a flight not taken yet: still the best way, from here?
		local target = r.stops[2]
		if not (target and first.planX) or first.planInst ~= inst then return end
		if (px - first.planX) ^ 2 + (py - first.planY) ^ 2 < 150 * 150 then return end
		local leg = self:PlanTrip(target)
		if leg and leg.key == first.key then
			first.planX, first.planY = px, py
			return
		end
		table.remove(r.stops, 1)
		if leg and not (r.skipped and r.skipped[leg.key]) and P.PlaceStop(leg, inst, px, py, nil, true) then
			leg.planInst, leg.planX, leg.planY = inst, px, py
			table.insert(r.stops, 1, leg)
		end
		self:Send("ROUTE_CHANGED")
		return
	end
	if first.trip then return end
	if lastKey == first.key and lastInst == inst and lastX and (px - lastX) ^ 2 + (py - lastY) ^ 2 < 60 * 60 then return end
	lastKey, lastInst, lastX, lastY = first.key, inst, px, py
	local n = #r.stops
	self:MaybeAddFlight()
	if #r.stops ~= n then self:Send("ROUTE_CHANGED") end
end

-- after a loading screen, a boat or a teleport, plan the next leg
P:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(2, function() if P.route then P:RefreshRoute() end end) end)
P:On("ZONE_CHANGED_NEW_AREA", function() if P.route and P.route.stops[1] and P.route.stops[1].trip then P:RefreshRoute() end end)
end part() end
-- ==================== Arrow.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Arrow
     The navigation arrow: points at the current stop, shows what to do there
     and how far it is, turns into a ring when you've arrived, and moves on by
     itself as the quest log changes. Right-click for a small menu. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local abs, pi, floor, min = math.abs, math.pi, math.floor, math.min
local GetPlayerFacing = GetPlayerFacing

local f, menu
local GOLD = { 1, 0.82, 0.36 }

local function S() return P.db.settings end

local function SavePos()
	local p, _, rp, x, y = f:GetPoint()
	P.db.pos.arrow = { p, rp, x, y }
end

---------------------------------------------------------------------------
-- Right-click menu
---------------------------------------------------------------------------
local function BuildMenu()
	menu = CreateFrame("Frame", "PathwayArrowMenu", UIParent, "BackdropTemplate")
	P.Flat(menu, P.colors.BG, P.colors.EDGE)
	menu:SetFrameStrata("DIALOG")
	menu:SetClampedToScreen(true)
	menu:EnableMouse(true)
	menu:Hide()
	tinsert(UISpecialFrames, "PathwayArrowMenu")
	local items = {
		{ "Skip this stop", function() P:SkipStop() end },
		{ "Next nearby set", function() P:StartRoute("next") end },
		{ "Stop navigating", function() P:StopRoute() end },
		{ "Lock arrow", function() S().arrowLocked = not S().arrowLocked end, function() return S().arrowLocked end },
		{ "Settings", function() P:OpenSettings() end },
	}
	menu.rows = {}
	for i, it in ipairs(items) do
		local b = CreateFrame("Button", nil, menu)
		b:SetSize(150, 20)
		b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 20)
		b.text = b:CreateFontString(nil, "OVERLAY"); b.text:SetFontObject(P.fonts.button); b.text:SetPoint("LEFT", 8, 0)
		b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.06)
		b:SetScript("OnClick", function() menu:Hide(); it[2]() end)
		b.label, b.check = it[1], it[3]
		menu.rows[i] = b
	end
	menu:SetSize(158, #items * 20 + 8)
	menu:SetScript("OnShow", function(self)
		for _, b in ipairs(self.rows) do
			b.text:SetText(b.check and (b.label .. (b.check() and "  |c" .. P.ACCENT_HEX .. "on|r" or "  " .. P.DIM .. "off|r")) or b.label)
		end
	end)
end

local function ToggleMenu()
	if not menu then BuildMenu() end
	if menu:IsShown() then menu:Hide(); return end
	menu:ClearAllPoints()
	menu:SetPoint("TOP", f, "BOTTOM", 0, -6)
	menu:Show()
end

---------------------------------------------------------------------------
-- The arrow frame
---------------------------------------------------------------------------
local function Build()
	f = CreateFrame("Button", "PathwayArrow", UIParent)
	if P.ApplySizes then P:ApplySizes() end
	f:SetSize(60, 60)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:RegisterForClicks("RightButtonUp")
	f:SetScript("OnDragStart", function(self) if not S().arrowLocked and P:CanDrag() then self:StartMoving() end end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos() end)
	f:SetScript("OnClick", function(_, button) if button == "RightButton" then ToggleMenu() end end)
	f:Hide()

	f.arrow = f:CreateTexture(nil, "ARTWORK")
	f.arrow:SetTexture(P.MEDIA .. "Arrow")
	f.arrow:SetSize(52, 52)
	f.arrow:SetPoint("CENTER")

	f.ring = f:CreateTexture(nil, "ARTWORK")
	f.ring:SetTexture(P.MEDIA .. "Ring")
	f.ring:SetSize(34, 34)
	f.ring:SetPoint("CENTER")
	f.ring:Hide()
	local ag = f.ring:CreateAnimationGroup()
	ag:SetLooping("BOUNCE")
	local a = ag:CreateAnimation("Alpha"); a:SetFromAlpha(0.45); a:SetToAlpha(1); a:SetDuration(0.7); a:SetSmoothing("IN_OUT")
	f.ring.pulse = ag

	f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFontObject(P.fonts.small)
	f.title:SetPoint("TOP", f, "BOTTOM", 0, -2)
	f.title:SetWidth(260); f.title:SetWordWrap(false)

	f.sub = f:CreateFontString(nil, "OVERLAY")
	f.sub:SetFontObject(P.fonts.small)
	f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -2)
	f.sub:SetWidth(260); f.sub:SetWordWrap(false)
	-- where exactly: "inside Lion's Pride Inn · by the inn"
	f.where = f:CreateFontString(nil, "OVERLAY")
	f.where:SetFontObject(P.fonts.small)
	f.where:SetPoint("TOP", f.sub, "BOTTOM", 0, -1)
	f.where:SetWidth(300); f.where:SetWordWrap(false)

	f.step = f:CreateFontString(nil, "OVERLAY")
	f.step:SetFontObject(P.fonts.head)
	f.step:SetPoint("BOTTOM", f, "TOP", 0, 0)

	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(P.TITLE)
		local r = P.route
		if r then GameTooltip:AddLine(r.title, 1, 1, 1) end
		GameTooltip:AddLine(P.DIM .. "Drag to move  ·  Right-click for options|r")
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", GameTooltip_Hide)

	P:PlaceAt(f, "arrow")

	local elapsed, retarget = 0, 0
	f:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed < 0.033 then return end
		elapsed = 0
		P:UpdateArrow()
	end)
	P.Perf.Hook(f, "Arrow", "OnUpdate")
end

local function Tint(t)
	-- gold when you're facing away, the accent color when you're on course
	local r = GOLD[1] + (A[1] - GOLD[1]) * t
	local g = GOLD[2] + (A[2] - GOLD[2]) * t
	local b = GOLD[3] + (A[3] - GOLD[3]) * t
	f.arrow:SetVertexColor(r, g, b)
end

local function Yards(d)
	if d >= 1000 then return ("%.1fk yd"):format(d / 1000) end
	return ("%d yd"):format(floor(d + 0.5))
end

-- how long to get there, from how fast you've been closing in (not your top speed:
-- roads bend and mobs get in the way)
local lastD, lastT, rate = nil, nil, nil
local roadAt, roadExtra
local function ETA(d)
	local now = GetTime()
	if lastD and lastT and now > lastT then
		local v = (lastD - d) / (now - lastT)
		if v > 0 and v < 60 then rate = rate and (rate * 0.92 + v * 0.08) or v end
	end
	lastD, lastT = d, now
	-- the way you'll really walk (around walls, through the gates), at the speed you really go
	-- (worked out twice a second; in between the extra length carries over)
	if now - (roadAt or 0) > 0.5 then
		roadAt, roadExtra = now, 0
		local s = P:Target()
		local inst, px, py = P:PlayerPos()
		if s and s.wx and inst and s.inst == inst and P.WalkYards then
			local ok, yd = pcall(P.WalkYards, P, P:PlayerZone(), px, py, P:ZoneOf(s.map), s.wx, s.wy)
			if ok and yd and yd < math.huge and yd > d then roadExtra = yd - d end
		end
	end
	local road = d + (roadExtra or 0)
	local v = P.TravelSpeed and P.TravelSpeed() or 7
	if d < 40 then return "" end
	local secs = road / v
	if secs > 3600 then return "" end
	return P.DIM .. ("  ·  %d:%02d"):format(floor(secs / 60), floor(secs % 60)) .. "|r"
end
P:Listen("ROUTE_CHANGED", function() lastD = nil end)
P:Listen("TARGET_CHANGED", function() lastD = nil end)

-- the step's words are worked out again whenever anything about it changes
for _, msg in ipairs({ "ROUTE_CHANGED", "QUESTS_CHANGED", "QUEST_PROGRESS", "TARGET_CHANGED", "SETTINGS_CHANGED" }) do
	P:Listen(msg, function() local a = _G.PathwayArrow; if a then a.labFor = nil end end)
end

-- set a line only when it says something new
local function Set(fs, text)
	if fs.pwText ~= text then fs.pwText = text; fs:SetText(text) end
end

function P:UpdateArrow()
	local s = self:Target()
	if P.placing and (not s or not self:PlayerPos()) then
		-- being placed with nothing to point at: a stand-in so you can see it
		f:Show(); f.arrow:Show(); f.arrow:SetRotation(0); f.ring:Hide()
		Set(f.title, "Your next step"); Set(f.step, P.DIM .. "Arrow|r")
		Set(f.sub, P.DIM .. "how far, and how long|r"); Set(f.where, "")
		return
	end
	if not s or (P:InSetup() and not P.placing) then f:Hide(); return end
	local inst, px, py = self:PlayerPos()
	-- the words only change with the step (or every half second): the arrow
	-- itself turns every frame
	local now = GetTime()
	if s ~= f.labFor or now - (f.labAt or 0) > 0.5 then
		f.labFor, f.labAt = s, now
		f.labTitle, f.labWho = self:StopLabel(s)
	end
	local title, who = f.labTitle, f.labWho
	Set(f.title, title)
	local r = self.route
	if s.corpse or not r then
		Set(f.step, "|cffff6b6bYou died|r" .. (r and (P.DIM .. "  ·  then back to " .. r.title .. "|r") or ""))
	else
		local done = r.total - #r.stops + 1
		Set(f.step, P.DIM .. r.title .. (r.total > 1 and ("  ·  " .. min(done, r.total) .. " / " .. r.total) or "") .. "|r")
	end

	if s.travel and UnitOnTaxi and UnitOnTaxi("player") then
		f.arrow:Hide(); f.ring:Show(); f.ring:SetVertexColor(A[1], A[2], A[3])
		if not f.ring.pulse:IsPlaying() then f.ring.pulse:Play() end
		Set(f.title, "Flying to " .. (s.flyName or ""))
		Set(f.sub, P.DIM .. "Pathway carries on when you land|r")
		return
	end
	local t = self:MapXform(s.map)
	if not inst or not t or t[1] ~= inst then
		f.arrow:Hide(); f.ring:Show(); f.ring:SetVertexColor(0.5, 0.52, 0.56)
		if f.ring.pulse:IsPlaying() then f.ring.pulse:Stop() end
		Set(f.sub, P.DIM .. (who ~= "" and (who .. "  ·  ") or "") .. self:MapName(s.map) .. "|r")
		return
	end
	local dist, angle = P.Vector(px, py, s.wx, s.wy)
	-- it's indoors and you're not: the arrow takes you to the way in first
	local door
	if dist < 120 and IsIndoors and not IsIndoors() and self.DoorFor then
		local now = GetTime()
		if s ~= f.doorFor or now - (f.doorAt or 0) > 1 then
			f.doorFor, f.doorAt = s, now
			local dm, dx, dy = self:DoorFor(s)
			f.door = nil
			if dm then
				local di, wx, wy = self:WorldPos(dm, dx, dy)
				if di == inst then f.door = { wx, wy } end
			end
		end
		door = f.door
		if door then
			local dd, da = P.Vector(px, py, door[1], door[2])
			if dd > 4 then
				f.arrow:Show(); f.ring:Hide()
				local rel = da - (GetPlayerFacing() or 0)
				f.arrow:SetRotation(rel)
				Tint(1 - min(abs(((rel + pi) % (2 * pi)) - pi) / (pi / 2), 1))
				Set(f.sub, "|cffffffffThe way in|r  " .. P.DIM .. Yards(dd) .. "|r")
				Set(f.where, "|cffd8dde3" .. (who ~= "" and (who .. " is ") or "It's ") .. "inside: go in here|r")
				return
			end
		end
	end
	local arrive = s.corpse and 30 or s.quest and 25 or S().arriveDistance
	if dist <= arrive then
		f.arrow:Hide()
		f.ring:Show(); f.ring:SetVertexColor(A[1], A[2], A[3])
		if not f.ring.pulse:IsPlaying() then f.ring.pulse:Play() end
		local here = s.corpse and "You're close enough: Resurrect"
			or s.trip and (s.goal or "")
			or s.quest and "You're in the area"
			or s.travel and ("Talk to " .. (who or "") .. ", fly to " .. (s.flyName or ""))
			or ("Talk to " .. (who or ""))
		Set(f.sub, "|c" .. P.ACCENT_HEX .. here .. "|r")
		if not s.arrived then
			s.arrived = true
			if S().sound and not s.quest then PlaySound(SOUNDKIT.MAP_PING or 3175) end
		end
		return
	end
	s.arrived = nil
	if f.ring:IsShown() then f.ring:Hide(); f.ring.pulse:Stop() end
	f.arrow:Show()
	local facing = GetPlayerFacing() or 0
	local rel = angle - facing
	f.arrow:SetRotation(rel)
	local off = abs(((rel + pi) % (2 * pi)) - pi)    -- 0 = straight ahead
	Tint(1 - min(off / (pi / 2), 1))
	Set(f.sub, (who ~= "" and (who .. "  ·  ") or "") .. "|cffffffff" .. Yards(dist) .. "|r" .. ETA(dist))
	-- where it is ("inside the abbey") changes rarely: worked out twice a second, not every frame
	local now = GetTime()
	if s ~= f.whereFor or now - (f.whereAt or 0) > 0.5 then
		f.whereFor, f.whereAt = s, now
		local where = self.Whereabouts and self:Whereabouts(s)
		-- close by, the step's own tip says more than the place name
		local tip = dist < 200 and self.StepHint and self:StepHint(s)
		if tip and #tip <= 60 then where = tip end
		if self.FlightMasterTip and self:FlightMasterTip(s) then where = "|cffffd27aTalk to the flight master here: Pathway learns your flights|r" end
		Set(f.where, where and ("|cffd8dde3" .. where .. "|r") or "")
	end
end

function P:RefreshArrow()
	if not f then return end
	P:ApplySizes()
	if S().arrow and (self:Target() or P.placing) then f:Show() else f:Hide() end
end

P:Listen("READY", function()
	Build()
	P:OnPaint(function() if f:IsShown() then P:UpdateArrow() end end)
end)
P:Listen("ROUTE_CHANGED", function() P:RefreshArrow() end)
P:Listen("SETTINGS_CHANGED", function() P:RefreshArrow() end)
end part() end
-- ==================== QuestLayer.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Quest layer
     Where every objective of your active quests is, for the minimap: each
     quest in its own color (the one the guide is on in your accent color),
     every spawn spot as a glowing pip, the spot the arrow wants pulsing,
     and spots you've already checked as hollow rings. Both minimaps (the
     game's and GoodMap) draw from the same list.

     The list for a map is built once and kept until your quests, their
     progress, the guide's step or the checked spots change. Each frame only
     the spots in view are placed. ]]

local ADDON, P = __addon, __ns
local K = P.K
local EMPTY = {}
local sqrt, atan2, floor = math.sqrt, math.atan2 or math.atan, math.floor

local function S() return P.db.settings end

-- Colors that read on any minimap art, far from each other and from green.
P.QUEST_COLORS = {
	{ 1.00, 0.70, 0.24 },   -- amber
	{ 0.36, 0.76, 1.00 },   -- sky
	{ 0.78, 0.52, 1.00 },   -- violet
	{ 1.00, 0.46, 0.62 },   -- rose
	{ 0.36, 0.92, 0.86 },   -- teal
	{ 1.00, 0.92, 0.40 },   -- lemon
	{ 1.00, 0.56, 0.36 },   -- coral
	{ 0.62, 0.70, 1.00 },   -- periwinkle
}

local colorOf = {}
local function AssignColors()
	wipe(colorOf)
	local ids = {}
	for qid, e in pairs(P.log or EMPTY) do if not e.complete then ids[#ids + 1] = qid end end
	table.sort(ids)
	-- never a color that looks like the guide's own (your accent color)
	local A, pal = P.ACCENT, {}
	for _, c in ipairs(P.QUEST_COLORS) do
		local d = math.abs(c[1] - A[1]) + math.abs(c[2] - A[2]) + math.abs(c[3] - A[3])
		if d > 0.45 then pal[#pal + 1] = c end
	end
	if #pal == 0 then pal = P.QUEST_COLORS end
	for i, qid in ipairs(ids) do colorOf[qid] = pal[(i - 1) % #pal + 1] end
end

-- the guide's quest is green; every other quest keeps its own color
function P:QuestColor(qid)
	local cur = self.route and self.route.stops and self.route.stops[1]
	if cur and cur.quest == qid then return P.ACCENT, true end
	return colorOf[qid] or P.QUEST_COLORS[1], false
end

---------------------------------------------------------------------------
-- The spots on a map: { x, y, wx, wy, qid, map, pt }
---------------------------------------------------------------------------
local cache = {}
local MAX_PER_OBJECTIVE = 60
local function Invalidate() wipe(cache); AssignColors(); P.layerVer = (P.layerVer or 0) + 1 end
P.InvalidateQuestLayer = Invalidate

function P:QuestSpotsOn(map)
	local c = cache[map]
	if c then return c end
	-- a cave, building or floor inside a zone: the zone's spots that fall on it
	local zone = self:SubMapZone(map)
	if zone then
		c = self:OnSubMap(map, zone, self:QuestSpotsOn(zone))
		cache[map] = c
		return c
	end
	c = {}
	local t = self:MapXform(map)
	if t then
		for qid, e in pairs(self.log or EMPTY) do
			if not e.complete then
				for _, tg in ipairs(self:ObjectiveTargets(qid)) do
					if tg.point then
						local pm, x, y = tg.point[1], tg.point[2], tg.point[3]
						local i, wx, wy = self:WorldPos(pm, x, y)
						if i and i == t[1] then
							local mx, my = self:MapPos(map, wx, wy)
							if mx then c[#c + 1] = { x = mx, y = my, wx = wx, wy = wy, qid = qid, area = tg.area } end
						end
					else
						local n = 0
						for _, ent in ipairs(tg.ents or EMPTY) do
							local en = self:Entity(ent[1], ent[2])
							local pts = en and en[2] and en[2][map]
							if pts then
								for k = 1, #pts do
									local x, y = P.Unpack(pts[k])
									c[#c + 1] = { x = x, y = y, wx = t[2] - t[4] * x, wy = t[3] - t[5] * y, qid = qid,
										map = map, pt = ent[1] == "O" and pts[k] or nil }
									n = n + 1
									if n >= MAX_PER_OBJECTIVE then break end
								end
							end
							if n >= MAX_PER_OBJECTIVE then break end
						end
					end
				end
			end
		end
	end
	cache[map] = c
	return c
end

-- the spots to draw around a world point, within `yards`, plus, for each quest
-- with nothing in view, the way to its nearest spot (for a chevron on the rim)
local inView, outside, nearestOut = {}, {}, {}
function P:QuestLayerAround(map, px, py, yards)
	wipe(inView); wipe(outside); wipe(nearestOut)
	local spots = self:QuestSpotsOn(map)
	local r2 = yards * yards
	local cur = self.route and self.route.stops and self.route.stops[1]
	local nextQ, nextPt, nextX, nextY = cur and cur.quest, cur and cur.atPt, cur and cur.wx, cur and cur.wy
	local seen = {}
	for i = 1, #spots do
		local s = spots[i]
		local dx, dy = s.wx - px, s.wy - py
		local d2 = dx * dx + dy * dy
		if d2 <= r2 then
			inView[#inView + 1] = s
			s.checked = s.pt and self:SpotChecked(s.map, s.pt) or false
			s.isNext = s.qid == nextQ and ((s.pt and s.pt == nextPt) or (not s.pt and nextX
				and (s.wx - nextX) ^ 2 + (s.wy - nextY) ^ 2 < 4))
			seen[s.qid] = true
		else
			local best = nearestOut[s.qid]
			if not best or d2 < best[1] then nearestOut[s.qid] = { d2, s } end
		end
	end
	for qid, b in pairs(nearestOut) do
		if not seen[qid] and b[1] < math.max(yards * 6, 2500) ^ 2 then outside[#outside + 1] = b[2] end
	end
	return inView, outside
end

-- the angle (counter-clockwise from up) to point a texture from (0,0) at (x, y) screen pixels (y up)
function P.PointAngle(x, y) return atan2(-x, y) end

P:Listen("QUESTS_CHANGED", Invalidate)
P:Listen("QUEST_PROGRESS", Invalidate)
P:Listen("ROUTE_CHANGED", function() P.layerVer = (P.layerVer or 0) + 1 end)
P:Listen("TARGET_CHANGED", function() P.layerVer = (P.layerVer or 0) + 1 end)
P:Listen("SPOTS_CHANGED", function() P.layerVer = (P.layerVer or 0) + 1 end)
P:Listen("READY", Invalidate)
P:Listen("MAP_LOOK_CHANGED", Invalidate)          -- a new accent color
P:Listen("SETTINGS_CHANGED", function() AssignColors(); P.layerVer = (P.layerVer or 0) + 1 end)
end part() end
-- ==================== Minimap.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Minimap path and quest layer
     A dotted trail on the minimap from you through the next few stops of your
     route: bright to the next stop, softer for the ones after. A ring marks
     each stop that's in view. Under it, the quest layer: every objective spot
     of your quests in that quest's color (QuestLayer.lua). Works with a rotating minimap, every zoom level,
     indoors and out, round or square. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local sin, cos, sqrt, floor, abs, max, min = math.sin, math.cos, math.sqrt, math.floor, math.abs, math.max, math.min

local function S() return P.db.settings end

-- minimap diameter in yards for each zoom level
local OUTDOOR = { [0] = 466.67, [1] = 400, [2] = 333.33, [3] = 266.67, [4] = 200, [5] = 133.33 }
local INDOOR = { [0] = 300, [1] = 240, [2] = 180, [3] = 120, [4] = 80, [5] = 50 }

local layer, dots, rings = nil, {}, {}
local used, ringsUsed = 0, 0
local indoors = false
local SPACING, MAX_STOPS = 9, 4

---------------------------------------------------------------------------
-- Indoors? (the minimap keeps a separate zoom for each; compare them)
---------------------------------------------------------------------------
local function CheckIndoors()
	if not Minimap or not Minimap.GetZoom then return end
	local zoom = Minimap:GetZoom()
	local outside, inside = tonumber(GetCVar("minimapZoom")), tonumber(GetCVar("minimapInsideZoom"))
	if outside == inside then
		-- both are the same: nudge the zoom to see which one moves
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
		indoors = tonumber(GetCVar("minimapInsideZoom")) == Minimap:GetZoom()
		Minimap:SetZoom(zoom)
	else
		indoors = inside == zoom
	end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
local function Dot()
	used = used + 1
	local d = dots[used]
	if not d then
		d = layer:CreateTexture(nil, "OVERLAY", nil, 6)
		d:SetTexture(P.MEDIA .. "Dot")
		dots[used] = d
	end
	return d
end

local function Ring()
	ringsUsed = ringsUsed + 1
	local r = rings[ringsUsed]
	if not r then
		r = layer:CreateTexture(nil, "OVERLAY", nil, 7)
		r:SetTexture(P.MEDIA .. "Ring")
		rings[ringsUsed] = r
	end
	return r
end

-- Dots and rings are kept and moved, not hidden and shown again each time:
-- a size, color or show call only happens when it changes, and only the
-- ones left over at the end are hidden.
local dotsOn, ringsOn = 0, 0
local function Put(t, size, r, g, b, a, x, y)
	if t.pwSize ~= size then t.pwSize = size; t:SetSize(size, size) end
	if t.pwA ~= a or t.pwR ~= r or t.pwG ~= g or t.pwB ~= b then t.pwA, t.pwR, t.pwG, t.pwB = a, r, g, b; t:SetVertexColor(r, g, b, a) end
	t:SetPoint("CENTER", layer, "CENTER", x, y)
	if not t.pwOn then t.pwOn = true; t:Show() end
end
local function Finish()
	for i = used + 1, dotsOn do local d = dots[i]; if d.pwOn then d.pwOn = false; d:Hide() end end
	for i = ringsUsed + 1, ringsOn do local r = rings[i]; if r.pwOn then r.pwOn = false; r:Hide() end end
	dotsOn, ringsOn = used, ringsUsed
end

local square
local function Inside(x, y, radius)
	if square then return abs(x) <= radius and abs(y) <= radius end
	return x * x + y * y <= radius * radius
end

-- segment in minimap pixels from (x1,y1) to (x2,y2)
local function Segment(x1, y1, x2, y2, radius, alpha, size, phase)
	local dx, dy = x2 - x1, y2 - y1
	local len = sqrt(dx * dx + dy * dy)
	if len < 1 then return phase end
	local ux, uy = dx / len, dy / len
	local t = phase
	while t < len do
		local x, y = x1 + ux * t, y1 + uy * t
		if Inside(x, y, radius) then Put(Dot(), size, A[1], A[2], A[3], alpha, x, y) end
		t = t + SPACING
	end
	return t - len
end

---------------------------------------------------------------------------
-- The quest layer: every objective spot of your quests, each quest in its
-- own color. Glowing pips, the next spot pulsing, checked spots hollow, and a
-- chevron on the rim for a quest whose spots are all off the minimap.
---------------------------------------------------------------------------
local pools = {}
local function Pool(name, tex, sub)
	local p = { list = {}, used = 0, on = 0, tex = tex, sub = sub }
	pools[name] = p
	return p
end
local pGlow, pCore, pRing, pPulse, pChev
local function Take(p)
	p.used = p.used + 1
	local t = p.list[p.used]
	if not t then
		t = layer:CreateTexture(nil, "OVERLAY", nil, p.sub)
		t:SetTexture(P.MEDIA .. p.tex)
		p.list[p.used] = t
	end
	return t
end
local function PoolsStart() for _, p in pairs(pools) do p.used = 0 end end
local function PoolsFinish()
	for _, p in pairs(pools) do
		for i = p.used + 1, p.on do local t = p.list[i]; if t.pwOn then t.pwOn = false; t:Hide() end end
		p.on = p.used
	end
end

-- Redrawn only when you move, turn or zoom, or a quest changes; in between
-- only the pulse on the next spot is animated.
local layerSig, pulseTex, pulseC
local function LayerClear() layerSig = nil; PoolsStart(); PoolsFinish(); pulseTex = nil end
local function DrawQuestLayer(self, inst, px, py, ToPixels, scale, radius, facing)
	if S().questLayer == false then if layerSig then LayerClear() end return end
	local map = self:PlayerZone()
	local t = map and self:MapXform(map)
	if not t or t[1] ~= inst then if layerSig then LayerClear() end return end
	local pulse = (math.sin(GetTime() * 4) + 1) / 2
	-- a new picture only when a spot would move a whole pixel
	local sig = map .. ":" .. floor(px * scale) .. ":" .. floor(py * scale) .. ":" .. floor((facing or 0) * radius) .. ":" .. floor(scale * 1000) .. ":" .. (self.layerVer or 0)
	if sig == layerSig then
		if pulseTex then
			local sz = 15 + 9 * pulse
			pulseTex:SetSize(sz, sz); pulseTex.pwSize = sz
			pulseTex:SetAlpha(1 - 0.7 * pulse)
		end
		return
	end
	layerSig = sig
	PoolsStart()
	pulseTex = nil
	local inView, outside = self:QuestLayerAround(map, px, py, radius / scale)
	for i = 1, #inView do
		local s = inView[i]
		local x, y = ToPixels(s.wx, s.wy)
		if Inside(x, y, radius) then
			local c, mine = self:QuestColor(s.qid)
			if s.checked then
				Put(Take(pRing), 9, c[1], c[2], c[3], 0.85, x, y)
			else
				-- the guide's quest glows under its spots, so it stands out from the rest
				if mine then Put(Take(pGlow), 24, c[1], c[2], c[3], 0.45, x, y) end
				Put(Take(pCore), mine and 12 or 10, c[1], c[2], c[3], 1, x, y)
				if s.isNext then
					pulseTex = Take(pPulse)
					Put(pulseTex, 15 + 9 * pulse, c[1], c[2], c[3], 1, x, y)
					pulseTex:SetAlpha(1 - 0.7 * pulse)
				end
			end
		end
	end
	-- quests with nothing on the minimap: which way their closest spot is
	for i = 1, #outside do
		local s = outside[i]
		local x, y = ToPixels(s.wx, s.wy)
		local d = sqrt(x * x + y * y)
		if d > 1 then
			local k = (square and (radius - 9) / max(abs(x), abs(y)) or (radius - 9) / d)
			local c, mine = self:QuestColor(s.qid)
			local ch = Take(pChev)
			Put(ch, mine and 17 or 14, c[1], c[2], c[3], 1, x * k, y * k)
			local a = P.PointAngle(x, y)
			if ch.pwRot ~= a then ch.pwRot = a; ch:SetRotation(a) end
		end
	end
	PoolsFinish()
end

-- for the tests: how many of each are showing
function P.QuestLayerStats() return pGlow and pGlow.on or 0, pRing and pRing.on or 0, pPulse and pPulse.on or 0, pChev and pChev.on or 0 end

local flow = 0
local DrawPath
function P:DrawMinimapPath()
	used, ringsUsed = 0, 0
	DrawPath(self)
	Finish()
end
DrawPath = function(self)
	-- on Pathway's own minimap (GoodMap) the route is drawn on the map itself
	if (self.MinimapLayersOff and self:MinimapLayersOff()) or not (Minimap and Minimap:IsShown()) then
		if layerSig then LayerClear() end
		return
	end
	local pathOn = S().minimapPath and (self.corpse or self:LiveRoute())
	if not pathOn and S().questLayer == false then if layerSig then LayerClear() end return end
	local inst, px, py = self:PlayerPos()
	if not inst then if layerSig then LayerClear() end return end
	local zoom = Minimap:GetZoom()
	local yards = (indoors and INDOOR or OUTDOOR)[zoom] or 466
	local w = Minimap:GetWidth()
	local scale = w / yards                       -- pixels per yard
	local radius = w / 2 - 3
	square = GetMinimapShape and GetMinimapShape() == "SQUARE"
	local rotate = GetCVar("rotateMinimap") == "1"
	local f = rotate and -(GetPlayerFacing() or 0) or 0
	local cf, sf = cos(f), sin(f)

	local function ToPixels(wx, wy)
		local east, north = -(wx - px) * scale, (wy - py) * scale
		if rotate then return east * cf - north * sf, east * sf + north * cf end
		return east, north
	end

	DrawQuestLayer(self, inst, px, py, ToPixels, scale, radius, rotate and f or 0)
	if not pathOn then return end

	local x1, y1 = 0, 0
	local phase = flow
	for i, s in ipairs(self.corpse and { self.corpse } or self.route.stops) do
		if i > MAX_STOPS then break end
		local t = self:MapXform(s.map)
		if not t or t[1] ~= inst or not s.wx then break end
		local x2, y2 = ToPixels(s.wx, s.wy)
		local alpha = i == 1 and 0.95 or 0.4
		phase = Segment(x1, y1, x2, y2, radius, alpha, i == 1 and 5 or 4, i == 1 and phase or 0)
		if Inside(x2, y2, radius) then Put(Ring(), i == 1 and 14 or 10, A[1], A[2], A[3], i == 1 and 1 or 0.55, x2, y2) end
		x1, y1 = x2, y2
	end
end

---------------------------------------------------------------------------
-- Flight paths you haven't discovered: an icon on the minimap, kept on the
-- rim when it's farther away so you can see which way it is
---------------------------------------------------------------------------
local fIcons, fUsed = {}, 0
local function FlightIcon()
	fUsed = fUsed + 1
	local t = fIcons[fUsed]
	if not t then
		t = layer:CreateTexture(nil, "OVERLAY", nil, 5)
		fIcons[fUsed] = t
	end
	return t
end

function P:DrawMinimapFlights()
	for i = 1, fUsed do fIcons[i]:Hide() end
	fUsed = 0
	local mode = S().flightPins or "undiscovered"
	if mode == "off" or not (Minimap and Minimap:IsShown()) then return end
	if self.MinimapLayersOff and self:MinimapLayersOff() then return end
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local zoom = Minimap:GetZoom()
	local yards = (indoors and INDOOR or OUTDOOR)[zoom] or 466
	local w = Minimap:GetWidth()
	local scale = w / yards
	local radius = w / 2 - 6
	square = GetMinimapShape and GetMinimapShape() == "SQUARE"
	local rotate = GetCVar("rotateMinimap") == "1"
	local f = rotate and -(GetPlayerFacing() or 0) or 0
	local cf, sf = cos(f), sin(f)
	for _, fp in ipairs(self:FlightList()) do
		if fp.inst == inst and (not fp.known or mode == "all") then
			local east, north = -(fp.wx - px) * scale, (fp.wy - py) * scale
			local x, y = east, north
			if rotate then x, y = east * cf - north * sf, east * sf + north * cf end
			local inside = Inside(x, y, radius)
			if inside or not fp.known then
				if not inside then
					local d = sqrt(x * x + y * y)
					local k = square and radius / max(abs(x), abs(y)) or radius / d
					x, y = x * k, y * k
				end
				local t = FlightIcon()
				if fp.known then
					t:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Green"); t:SetVertexColor(1, 1, 1, 1); t:SetSize(10, 10)
				else
					t:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-White"); t:SetVertexColor(1, 0.82, 0.3, inside and 1 or 0.6)
					t:SetSize(inside and 14 or 10, inside and 14 or 10)
				end
				t:ClearAllPoints()
				t:SetPoint("CENTER", layer, "CENTER", x, y)
				t:Show()
			end
		end
	end
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
P:Listen("READY", function()
	if not Minimap then return end
	layer = CreateFrame("Frame", "PathwayMinimapLayer", Minimap)
	layer:SetAllPoints(Minimap)
	layer:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	pGlow, pCore, pRing = Pool("glow", "Glow", 1), Pool("core", "Pip", 3), Pool("ring", "PipHollow", 2)
	pPulse, pChev = Pool("pulse", "Halo", 4), Pool("chev", "Pointer", 4)
	CheckIndoors()
	-- ten times a second (the drifting dots look the same as at twenty, for
	-- half the work); flight icons only move when you, the facing or the zoom do
	local t = 0
	local idle = false
	local lx, ly, lf, lz
	layer:SetScript("OnUpdate", function(_, dt)
		t = t + dt
		if t < 0.1 then return end
		-- Pathway's own minimap draws all this itself: clear ours once, then rest
		if (P.MinimapLayersOff and P:MinimapLayersOff()) or not (((P.corpse or P:LiveRoute()) and S().minimapPath) or (S().questLayer ~= false and next(P.log or {}))) then
			if not idle then idle = true; lx = nil; P:DrawMinimapPath(); P:DrawMinimapFlights() end
			t = 0
			return
		end
		idle = false
		-- the dots drift gently toward the next stop
		flow = (flow + t * 12) % SPACING
		t = 0
		P:DrawMinimapPath()
		local _, px, py = P:PlayerPos()
		local fac = GetPlayerFacing and GetPlayerFacing() or 0
		local z = Minimap:GetZoom()
		if px ~= lx or py ~= ly or fac ~= lf or z ~= lz then
			lx, ly, lf, lz = px, py, fac, z
			P:DrawMinimapFlights()
		end
	end)
	P.Perf.Hook(layer, "Quest routes", "OnUpdate")
end)

P:On("MINIMAP_UPDATE_ZOOM", CheckIndoors)
P:On("ZONE_CHANGED_INDOORS", function() C_Timer.After(0.1, CheckIndoors) end)
P:On("ZONE_CHANGED", function() C_Timer.After(0.1, CheckIndoors) end)
P:Listen("ROUTE_CHANGED", function() if layer then P:DrawMinimapPath() end end)
end part() end
-- ==================== Map.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — World map
     A slim bar along the bottom of the map:
       Next set · Pick up · Objectives · Turn in · <Zone> guide · Stop · settings
     and pins on the map itself: quests you can pick up (!), quests ready to
     turn in (?), where your objectives are (dots) and your route (numbered).
     Click any pin to go straight there. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local EMPTY = {}
local ipairs, pairs, wipe, floor, min, max = ipairs, pairs, wipe, math.floor, math.min, math.max
local K = P.K

local bar, pins, pool, canvasScale = nil, {}, {}, nil
local ICON_PICK = "Interface\\GossipFrame\\AvailableQuestIcon"
local ICON_TURN = "Interface\\GossipFrame\\ActiveQuestIcon"
local FIRE_ICON = "Interface\\Icons\\Spell_Fire_Fire"

local function S() return P.db.settings end

local function ViewedZone()
	local map = WorldMapFrame and WorldMapFrame:GetMapID()
	if map then
		local info = C_Map.GetMapInfo(map)
		if info and Enum.UIMapType and info.mapType >= Enum.UIMapType.Zone then return P:ZoneOf(map) end
	end
	return P:PlayerZone()
end

---------------------------------------------------------------------------
-- Pins
---------------------------------------------------------------------------
local function QuestLine(qid)
	local q = P.Q[qid]
	if not q then return "" end
	local lvl = q[K.LVL] or 0
	local c = GetQuestDifficultyColor and GetQuestDifficultyColor(lvl) or { r = 1, g = 0.82, b = 0 }
	return ("|cff%02x%02x%02x[%d]|r %s"):format(floor(c.r * 255), floor(c.g * 255), floor(c.b * 255), lvl, q[K.NAME])
end

local function PinTooltip(pin)
	local mk = pin.mk
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	if mk.flight then
		local fp = mk.flight
		GameTooltip:SetText(fp.name, 1, 1, 1)
		if fp.known then
			GameTooltip:AddLine("|cff7cf29cFlight path you know|r")
		else
			GameTooltip:AddLine(P.GOLD .. "Flight path you haven't discovered|r")
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("|c" .. P.ACCENT_HEX .. "Click to go there|r")
		end
		GameTooltip:Show()
		return
	end
	if mk.fire then
		local f = mk.fire
		local left = math.max(0, f.ends - GetTime())
		GameTooltip:SetText((f.tier and (f.tier .. " campfire") or "Campfire"), 1, 0.72, 0.3)
		if f.features and f.features ~= "" then GameTooltip:AddLine(f.features, 0.9, 0.9, 0.9, true) end
		GameTooltip:AddLine(("Burns about %d more min"):format(math.max(1, floor(left / 60 + 0.5))), 1, 1, 1)
		-- where it came from (Happy Camper's camps carry its credit, as it asks)
		local FROM = { mine = "Found by you", campfire = "From a CampFirePin player", smore = "From an S'more Skills host",
			kerzo = "From your group (Kerzo Camping Sync)", happycamper = "Camp data: Happy Camper" }
		local from = f.src == "pathway" and f.who and ("Shared by " .. f.who) or FROM[f.src] or (f.who and ("Shared by " .. f.who)) or "Found by you"
		if f.who and (f.src == "campfire" or f.src == "smore" or f.src == "kerzo") then from = from .. ": " .. f.who end
		GameTooltip:AddLine(P.DIM .. from .. (f.placed and "" or ".  Burn time not known: at most this.") .. "|r", 1, 1, 1, true)
		GameTooltip:AddLine(P.DIM .. "Sit by it for a minute: camp buffs for an hour.|r")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("|c" .. P.ACCENT_HEX .. "Click to go there|r")
		GameTooltip:Show()
		return
	end
	if mk.route then
		local title, who = P:StopLabel(mk.route)
		GameTooltip:SetText(title, 1, 1, 1)
		if who and who ~= "" then GameTooltip:AddLine(who, 0.7, 0.7, 0.7) end
		GameTooltip:AddLine(P.DIM .. "Stop " .. mk.n .. " on your route|r")
	elseif mk.kind == "objective" then
		GameTooltip:SetText(mk.text or "Objective", 1, 1, 1)
		GameTooltip:AddLine(QuestLine(mk.quests[1]))
		if mk.name then GameTooltip:AddLine(mk.name, 0.7, 0.7, 0.7) end
	else
		GameTooltip:SetText(mk.name or "", 1, 1, 1)
		GameTooltip:AddLine(mk.kind == "turnin" and "|cff7cf29cReady to turn in|r" or (P.GOLD .. "Quests to pick up|r"))
		for i, qid in ipairs(mk.quests) do
			if i > 8 then GameTooltip:AddLine(P.DIM .. "...and " .. (#mk.quests - 8) .. " more|r"); break end
			GameTooltip:AddLine(QuestLine(qid), 1, 1, 1)
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("|c" .. P.ACCENT_HEX .. "Click to go there|r")
	GameTooltip:Show()
end

local function PinClick(pin)
	local mk = pin.mk
	if mk.fire then
		local f = mk.fire
		local map = WorldMapFrame and WorldMapFrame:GetMapID()
		local x, y = map and P:MapPos(map, f.x, f.y)
		if x then P:StartRoute("next", { single = { key = "fire", goal = "Campfire", name = "Campfire", point = { map, x, y }, reach = 10 }, title = "Campfire" }) end
		return
	end
	if mk.flight then
		local fp = mk.flight
		if not fp.known then
			P:StartRoute("next", { single = { key = "fm" .. fp.id, flight = fp.id, ents = { { "N", fp.id } }, name = fp.name,
				point = { fp.map, fp.x, fp.y } }, title = "Flight path" })
		end
		return
	end
	if mk.route then
		-- jump the route to this stop
		local r = P:LiveRoute()
		for i, s in ipairs(r.stops) do
			if s == mk.route then table.remove(r.stops, i); table.insert(r.stops, 1, s); break end
		end
		P:Send("ROUTE_CHANGED")
		return
	end
	local stop
	if mk.kind == "objective" then
		stop = { key = "q" .. mk.quests[1] .. ":" .. (mk.index or 0), quest = mk.quests[1], index = mk.index, text = mk.text, ents = mk.ents or (mk.ent and { mk.ent }), point = mk.point }
	else
		stop = { key = mk.ent[1] .. mk.ent[2], ents = { mk.ent }, name = mk.name }
	end
	P:StartRoute("next", { single = stop, title = "Go to" })
end

local function AcquirePin(parent)
	local pin = table.remove(pool)
	if not pin then
		pin = CreateFrame("Button", nil, parent)
		pin.tex = pin:CreateTexture(nil, "ARTWORK")
		pin.tex:SetAllPoints()
		pin.glow = pin:CreateTexture(nil, "BACKGROUND")
		pin.glow:SetTexture(P.MEDIA .. "Glow")
		pin.glow:SetPoint("CENTER")
		pin.num = pin:CreateFontString(nil, "OVERLAY")
		pin.num:SetFontObject(P.fonts.small)
		pin.num:SetPoint("CENTER", 0, 0)
		pin:SetScript("OnEnter", PinTooltip)
		pin:SetScript("OnLeave", GameTooltip_Hide)
		pin:SetScript("OnClick", PinClick)
	end
	pin:SetParent(parent)
	pin.glow:Hide(); pin.num:SetText("")
	pin.tex:SetVertexColor(1, 1, 1); pin.tex:SetAlpha(1)
	pins[#pins + 1] = pin
	return pin
end

local ClearLine, DrawRouteLine
local function ReleasePins()
	for _, pin in ipairs(pins) do pin:Hide(); pin.mk = nil; pool[#pool + 1] = pin end
	wipe(pins)
	if ClearLine then ClearLine() end
end

-- pins keep a constant size while the map zooms: they're scaled by 1/zoom,
-- and anchor offsets are in the pin's own scale, so offsets are divided too
local function Anchor(pin)
	local child, k = pin.child, pin:GetScale()
	pin:ClearAllPoints()
	pin:SetPoint("CENTER", child, "TOPLEFT", pin.px * child:GetWidth() / k, -pin.py * child:GetHeight() / k)
end

local function Place(pin, child, x, y, size)
	pin:SetSize(size, size)
	pin.child, pin.px, pin.py = child, x, y
	pin:SetScale(canvasScale or 1)
	Anchor(pin)
	pin:Show()
end

local function Scale()
	local s = WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale() or 1
	return 1 / s
end

function P:DrawPins()
	ReleasePins()
	if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end
	local map = WorldMapFrame:GetMapID()
	local child = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
	if not map or not child then return end
	canvasScale = Scale()
	local level = child:GetFrameLevel() + 20

	if S().mapPins then
		for _, mk in ipairs(self:Markers(map)) do
			local pin = AcquirePin(child)
			pin.mk = mk
			if mk.kind == "objective" then
				pin.tex:SetTexture(P.MEDIA .. "Dot")
				pin.tex:SetVertexColor(A[1], A[2], A[3])
				Place(pin, child, mk.x, mk.y, 9)
				pin:SetFrameLevel(level)
			else
				pin.tex:SetTexture(mk.kind == "turnin" and ICON_TURN or ICON_PICK)
				Place(pin, child, mk.x, mk.y, 16)
				pin:SetFrameLevel(level + (mk.kind == "turnin" and 2 or 1))
			end
		end
	end

	-- flight paths: the ones you haven't found stand out
	local fmode = S().flightPins or "undiscovered"
	if fmode ~= "off" then
		local t = P:MapXform(map)
		for _, fp in ipairs(P:FlightList()) do
			if (not fp.known or fmode == "all") and t and fp.inst == t[1] then
				local x, y = P:MapPos(map, fp.wx, fp.wy)
				if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
					local pin = AcquirePin(child)
					pin.mk = { flight = fp }
					if fp.known then
						pin.tex:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-Green")
						Place(pin, child, x, y, 12)
					else
						pin.tex:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Icon-White")
						pin.tex:SetVertexColor(1, 0.82, 0.3)
						pin.glow:SetVertexColor(1, 0.82, 0.3, 0.55); pin.glow:SetSize(30, 30); pin.glow:Show()
						Place(pin, child, x, y, 16)
					end
					pin:SetFrameLevel(level + 3)
				end
			end
		end
	end

	-- campfires: yours and the ones other players shared, while they burn
	if S().firePins ~= false and P.Campfires then
		local t = P:MapXform(map)
		for _, fire in ipairs(t and P:FirePins(t[1]) or {}) do
			local x, y = P:MapPos(map, fire.x, fire.y)
			if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
				local pin = AcquirePin(child)
				pin.mk = { fire = fire }
				pin.tex:SetTexture(FIRE_ICON)
				pin.glow:SetVertexColor(1, 0.5, 0.15, fire.exact and 0.7 or 0.35); pin.glow:SetSize(30, 30); pin.glow:Show()
				Place(pin, child, x, y, fire.exact and 16 or 14)
				pin.tex:SetAlpha(fire.exact and 1 or 0.7)
				pin:SetFrameLevel(level + 4)
			end
		end
	end

	DrawRouteLine(child, map)

	-- your route, numbered, always on top
	local r = self:LiveRoute()
	if r then
		for i, s in ipairs(r.stops) do
			if s.map == map then
				local pin = AcquirePin(child)
				pin.mk = { route = s, n = i }
				pin.tex:SetTexture(P.MEDIA .. "Ring")
				pin.tex:SetVertexColor(A[1], A[2], A[3])
				pin.num:SetText(i)
				pin.glow:SetVertexColor(A[1], A[2], A[3], i == 1 and 0.9 or 0)
				pin.glow:SetSize(40, 40)
				pin.glow:SetShown(i == 1)
				Place(pin, child, s.x, s.y, i == 1 and 22 or 18)
				pin:SetFrameLevel(level + 10)
				end
		end
	end
end

local function Rescale()
	local s = Scale()
	if s == canvasScale then return end
	P:DrawPins()
end

---------------------------------------------------------------------------
-- The route as a dotted line: from you, through each stop on this map
---------------------------------------------------------------------------
local lineDots, lineUsed = {}, 0

local function LineDot(child)
	lineUsed = lineUsed + 1
	local d = lineDots[lineUsed]
	if not d then
		d = child:CreateTexture(nil, "OVERLAY", nil, 5)
		d:SetTexture(P.MEDIA .. "Dot")
		lineDots[lineUsed] = d
	end
	if d:GetParent() ~= child then d:SetParent(child) end
	return d
end

function ClearLine()
	for i = 1, #lineDots do lineDots[i]:Hide() end
	lineUsed = 0
end

function DrawRouteLine(child, map)
	ClearLine()
	local r = P:LiveRoute()
	if not (S().mapPath and r) then return end
	local W, H = child:GetWidth(), child:GetHeight()
	local pts = {}
	local inst, px, py = P:PlayerPos()
	local t = P:MapXform(map)
	if inst and t and t[1] == inst then
		local x, y = P:MapPos(map, px, py)
		if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then pts[1] = { x * W, y * H } end
	end
	for _, s in ipairs(r.stops) do
		if s.map ~= map then break end
		pts[#pts + 1] = { s.x * W, s.y * H }
	end
	local k = canvasScale or 1
	local spacing, size = 11 * k, 5 * k
	for i = 2, #pts do
		local x1, y1, x2, y2 = pts[i - 1][1], pts[i - 1][2], pts[i][1], pts[i][2]
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local alpha = (i == 2) and 0.95 or 0.45
		local step = spacing
		local n = math.floor(len / step)
		for j = 1, n - 1 do
			local d = LineDot(child)
			d:SetSize(size, size)
			d:SetVertexColor(A[1], A[2], A[3], alpha)
			d:ClearAllPoints()
			d:SetPoint("CENTER", child, "TOPLEFT", x1 + dx * j / n, -(y1 + dy * j / n))
			d:Show()
		end
	end
end

---------------------------------------------------------------------------
-- The bar along the bottom of the map
---------------------------------------------------------------------------
local function Icon(path, size, r, g, b)
	if r then
		return ("|T%s:%d:%d:0:0:32:32:0:32:0:32:%d:%d:%d|t"):format(path, size, size, floor(r * 255), floor(g * 255), floor(b * 255))
	end
	return ("|T%s:%d|t"):format(path, size)
end

local function BuildBar()
	local parent = WorldMapFrame.ScrollContainer or WorldMapFrame
	bar = CreateFrame("Frame", "PathwayMapBar", WorldMapFrame, "BackdropTemplate")
	P.Flat(bar, P.colors.BG, P.colors.EDGE)
	bar:SetHeight(28)
	bar:SetPoint("BOTTOM", parent, "BOTTOM", 0, 8)
	bar:SetFrameStrata(WorldMapFrame:GetFrameStrata())
	bar:SetFrameLevel(parent:GetFrameLevel() + 100)

	local logo = bar:CreateFontString(nil, "OVERLAY")
	logo:SetFontObject(P.fonts.title)
	logo:SetPoint("LEFT", 10, 0)
	bar.logo = logo

	local function Btn(key, label, tip, onClick, accent)
		local b = P:FlatButton(bar, label, accent)
		b.tip = tip
		b:SetScript("OnClick", onClick)
		bar[key] = b
		return b
	end
	Btn("next", "Next set", "Go to the closest set of quests for you: turn-ins, objectives and new quests, nearest first.",
		function() P:StartRoute("next") end, true)
	Btn("pick", "", "Go pick up the closest quests that suit your level.", function() P:StartRoute("pickup") end)
	Btn("obj", "", "Go to the nearest objectives for quests you have.", function() P:StartRoute("objective") end)
	Btn("turn", "", "Go turn in the closest finished quests.", function() P:StartRoute("turnin") end)
	local book = Btn("book", "|TInterface\\Icons\\INV_Misc_Book_09:14:14:0:0:64:64:5:59:5:59|t  Guides",
		"|cffffffffClick|r  the quest journal, on this zone: load its storyline, all its quests, a chain or one quest.\n|cffffffffRight-click|r  this zone's guides in a quick menu.",
		function(b, button)
			if button == "RightButton" then P:ZoneMenu(b, bar.zoneMap) return end
			P:ShowZoneInJournal(bar.zoneMap)
		end)
	book:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	Btn("find", "|TInterface\\Icons\\INV_Misc_Spyglass_02:14:14:0:0:64:64:5:59:5:59|t  Find",
		"The nearest repair, food and drink, innkeeper, trainer, bank or auction house.",
		function(b) P.Find:Menu(b) end)
	Btn("stop", "Stop", "Stop navigating.", function() P:StopRoute() end)

	local gear = CreateFrame("Button", nil, bar, "BackdropTemplate")
	gear:SetSize(22, 20)
	P.Flat(gear, P.colors.PANEL, P.colors.EDGE)
	gear.icon = gear:CreateTexture(nil, "ARTWORK"); gear.icon:SetSize(14, 14); gear.icon:SetPoint("CENTER")
	gear.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
	gear:SetScript("OnClick", function() P:OpenSettings() end)
	gear:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(A[1], A[2], A[3], 1) end)
	gear:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(P.colors.EDGE)) end)
	bar.gear = gear

	P:OnPaint(function() logo:SetText(P.TITLE) end)
	logo:SetText(P.TITLE)
end

-- a zone's guides, from the map bar or a zone prompt
function P:ZoneMenu(owner, map)
	map = map or self:PlayerZone()
	local menu = MenuUtil or P.MiniMenu
	P.Cat:Build()
	local z = P.Cat.zones[map or 0]
	menu.CreateContextMenu(owner, function(_, root)
		root:CreateTitle((map and self:MapName(map) or "Zone") .. " guides")
		if z and next(z.story) then
			local _, _, f = P.Cat:SetProgress(z.story)
			root:CreateButton(("Storyline  %s(%d%%)|r"):format(P.DIM, math.floor(f * 100 + 0.5)), function() P:PlayZone(map, "story") end)
		end
		if z then
			local _, _, f = P.Cat:Progress(z.quests)
			root:CreateButton(("All quests, chain to chain  %s(%d%%)|r"):format(P.DIM, math.floor(f * 100 + 0.5)), function() P:PlayZone(map, "all") end)
			root:CreateButton("Fastest XP", function() P:PlayZone(map, "fast") end)
		end
		root:CreateButton("Everything for my level here", function() P:StartRoute("zone", { map = map }) end)
		root:CreateDivider()
		root:CreateButton("Open in journal", function() P:ShowZoneInJournal(map) end)
	end)
end

function P:UpdateBar()
	if not bar then return end
	if not S().mapBar then bar:Hide(); return end
	local zone = ViewedZone()
	bar.zoneMap = zone
	local pick, obj, turn = 0, 0, 0
	if zone then pick, obj, turn = self:ZoneCounts(zone) end
	local DIM = P.DIM
	bar.pick:SetLabel(Icon(ICON_PICK, 14) .. " Pick up  " .. (pick > 0 and ("|cffffffff" .. pick .. "|r") or (DIM .. "0|r")))
	bar.obj:SetLabel(Icon(P.MEDIA .. "Dot", 10, A[1], A[2], A[3]) .. " Objectives  " .. (obj > 0 and ("|cffffffff" .. obj .. "|r") or (DIM .. "0|r")))
	bar.turn:SetLabel(Icon(ICON_TURN, 14) .. " Turn in  " .. (turn > 0 and ("|cffffffff" .. turn .. "|r") or (DIM .. "0|r")))
	bar.stop:SetShown(self.route ~= nil)

	-- lay out left to right after the logo
	local prev, x = nil, 10 + bar.logo:GetStringWidth() + 12
	-- Journal and Find live on the minimap's button bar now; the map keeps what's about this map
	local order = { bar.next, bar.pick, bar.obj, bar.turn, bar.stop, bar.gear }
	bar.book:Hide(); bar.find:Hide()
	for _, b in ipairs(order) do
		if b:IsShown() then
			b:ClearAllPoints()
			b:SetPoint("LEFT", bar, "LEFT", x, 0)
			x = x + b:GetWidth() + 4
		end
	end
	bar:SetWidth(x + 6)
	bar:Show()
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
local function Refresh()
	if not (WorldMapFrame and WorldMapFrame:IsShown()) then return end
	P:DrawPins()
	P:UpdateBar()
end
P.RefreshMap = Refresh

P:Listen("READY", function()
	if not WorldMapFrame then return end
	BuildBar()
	WorldMapFrame:HookScript("OnShow", Refresh)
	WorldMapFrame:HookScript("OnHide", ReleasePins)
	if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", Refresh) end
	-- keep pins the same size as you zoom
	local watcher = CreateFrame("Frame", nil, WorldMapFrame)
	local t = 0
	local moved = 0
	watcher:SetScript("OnUpdate", function(_, dt)
		t, moved = t + dt, moved + dt
		if t > 0.1 then t = 0; Rescale() end
		-- the line starts at you, so follow along while the map is open
		if moved > 0.5 then moved = 0; if P:LiveRoute() and S().mapPath then P:DrawPins() end end
	end)
	P.Perf.Hook(watcher, "World map pins", "OnUpdate")
end)

P:Listen("MARKERS_CHANGED", function() P:Debounce("map", 0.1, Refresh) end)
P:Listen("ROUTE_CHANGED", function() P:Debounce("map", 0.1, Refresh) end)
P:Listen("SETTINGS_CHANGED", function() P:Debounce("map", 0.1, Refresh) end)

---------------------------------------------------------------------------
-- On Pathway's minimap (GoodMap): your route as a dotted line from you,
-- with numbered stops, clipped to the round map. GoodMap keeps these canvas
-- pins in place as it pans and zooms.
---------------------------------------------------------------------------
local gmPins = {}

local function GMClear()
	local E = P.GoodMap.E
	if not E then return end
	for _, f in ipairs(gmPins) do E.FreeCanvasPin(f) end
	wipe(gmPins)
end

local function GMPin(kind, level, tex, size, alpha)
	local NS = P.GoodMap
	local f = NS.E.CanvasPin("pathway_" .. kind, level)
	if not f.tex then
		f.tex = f:CreateTexture(nil, "OVERLAY")
		f.tex:SetPoint("CENTER")
		NS.Mask(f.tex)
		if kind == "stop" then
			f.num = f:CreateFontString(nil, "OVERLAY")
			f.num:SetFontObject(P.fonts.small)
			f.num:SetPoint("CENTER")
		end
	end
	f.tex:SetTexture(tex)
	f.tex:SetSize(size, size)
	f.tex:SetVertexColor(A[1], A[2], A[3], alpha)
	gmPins[#gmPins + 1] = f
	return f
end

---------------------------------------------------------------------------
-- What you track, at all times. Inside the radar (the real minimap, inside
-- Pathway's) the game shows its own blips, live. Everywhere it isn't (indoors,
-- where it steps out; on a flight; when you've moved the map; past its edge on
-- a zoomed-out map) Pathway shows what it knows: the herbs and ore you can
-- gather, while you track them (Find Herbs, Find Minerals), and the town's
-- services you track: mailboxes, inns, banks, the auction house, repairs, your
-- class trainer and flight masters. Where a node can be, not whether it's up
-- right now: only the game knows that.
---------------------------------------------------------------------------
-- node name -> kind ("H" herb, "O" ore) and the skill it needs
local NODES = {
	["Copper Vein"] = { "O", 1 }, ["Tin Vein"] = { "O", 65 }, ["Incendicite Mineral Vein"] = { "O", 65 },
	["Silver Vein"] = { "O", 75 }, ["Lesser Bloodstone Deposit"] = { "O", 75 }, ["Ooze Covered Silver Vein"] = { "O", 75 },
	["Iron Deposit"] = { "O", 125 }, ["Indurium Mineral Vein"] = { "O", 150 }, ["Gold Vein"] = { "O", 155 },
	["Ooze Covered Gold Vein"] = { "O", 155 }, ["Mithril Deposit"] = { "O", 175 }, ["Ooze Covered Mithril Deposit"] = { "O", 175 },
	["Truesilver Deposit"] = { "O", 230 }, ["Ooze Covered Truesilver Deposit"] = { "O", 230 }, ["Dark Iron Deposit"] = { "O", 230 },
	["Small Thorium Vein"] = { "O", 245 }, ["Ooze Covered Thorium Vein"] = { "O", 245 }, ["Rich Thorium Vein"] = { "O", 275 },
	["Ooze Covered Rich Thorium Vein"] = { "O", 275 }, ["Hakkari Thorium Vein"] = { "O", 275 }, ["Small Obsidian Chunk"] = { "O", 305 },
	["Large Obsidian Chunk"] = { "O", 305 },
	["Peacebloom"] = { "H", 1 }, ["Silverleaf"] = { "H", 1 }, ["Earthroot"] = { "H", 15 }, ["Mageroyal"] = { "H", 50 },
	["Briarthorn"] = { "H", 70 }, ["Stranglekelp"] = { "H", 85 }, ["Bruiseweed"] = { "H", 100 }, ["Wild Steelbloom"] = { "H", 115 },
	["Grave Moss"] = { "H", 120 }, ["Kingsblood"] = { "H", 125 }, ["Liferoot"] = { "H", 150 }, ["Fadeleaf"] = { "H", 160 },
	["Goldthorn"] = { "H", 170 }, ["Khadgar's Whisker"] = { "H", 185 }, ["Wintersbite"] = { "H", 195 }, ["Firebloom"] = { "H", 205 },
	["Purple Lotus"] = { "H", 210 }, ["Arthas' Tears"] = { "H", 220 }, ["Sungrass"] = { "H", 230 }, ["Blindweed"] = { "H", 235 },
	["Ghost Mushroom"] = { "H", 245 }, ["Gromsblood"] = { "H", 250 }, ["Golden Sansam"] = { "H", 260 }, ["Dreamfoil"] = { "H", 270 },
	["Mountain Silversage"] = { "H", 280 }, ["Plaguebloom"] = { "H", 285 }, ["Icecap"] = { "H", 290 }, ["Black Lotus"] = { "H", 300 },
	["Bloodvine"] = { "H", 300 },
}
local NODE_COLOR = { H = { 0.45, 0.95, 0.40 }, O = { 1.00, 0.80, 0.30 } }
local nodeIndex                                  -- { { id, kind, skill }, ... } from the object data
local function NodeIndex()
	if nodeIndex then return nodeIndex end
	nodeIndex = {}
	for id, o in pairs(P.O or EMPTY) do
		local n = NODES[o[1]]
		if n then nodeIndex[#nodeIndex + 1] = { id, n[1], n[2] } end
	end
	return nodeIndex
end

-- your Mining and Herbalism, and whether you're tracking them
local skillAt, skills = 0, {}
local function Skills()
	if GetTime() - skillAt < 10 then return skills end
	skillAt = GetTime()
	wipe(skills)
	if GetProfessions and GetProfessionInfo then
		for _, idx in ipairs({ GetProfessions() }) do
			if idx then
				local _, _, level, _, _, _, line = GetProfessionInfo(idx)
				if line == 186 then skills.O = level elseif line == 182 then skills.H = level end
			end
		end
	end
	if not (skills.O or skills.H) and GetNumSkillLines and GetSkillLineInfo then
		for i = 1, GetNumSkillLines() do
			local name, header, _, level = GetSkillLineInfo(i)
			if not header and name == "Mining" then skills.O = level elseif not header and name == "Herbalism" then skills.H = level end
		end
	end
	return skills
end
local TRACK_NAMES = { O = "Find Minerals", H = "Find Herbs", mail = "Mailbox", inn = "Innkeeper", bank = "Banker",
	auction = "Auctioneer", repair = "Repair", class = "Trainer", flight = "Flight Master" }
local TRACK_SPELLS = { [2580] = "O", [2383] = "H" }
local tracked, trackAt = {}, 0
local function Tracked()
	if GetTime() - trackAt < 2 then return tracked end
	trackAt = GetTime()
	wipe(tracked)
	local MM = C_Minimap
	if not (MM and MM.GetNumTrackingTypes and MM.GetTrackingInfo) then tracked.all = true return tracked end
	local known = false
	for i = 1, MM.GetNumTrackingTypes() do
		local a, _, c = MM.GetTrackingInfo(i)
		local name, active, spell
		if type(a) == "table" then name, active, spell = a.name, a.active, a.spellID else name, active = a, c end
		if active then
			if spell and TRACK_SPELLS[spell] then tracked[TRACK_SPELLS[spell]] = true; known = true end
			for key, label in pairs(TRACK_NAMES) do
				if type(name) == "string" and name:find(label, 1, true) then tracked[key] = true; known = true end
			end
		end
	end
	-- a game in another language: names don't match, so show everything you could track
	if not known then
		local any = false
		for i = 1, MM.GetNumTrackingTypes() do
			local a, _, c = MM.GetTrackingInfo(i)
			if (type(a) == "table" and a.active) or (type(a) ~= "table" and c) then any = true break end
		end
		if any and GetLocale and GetLocale() ~= "enUS" and GetLocale() ~= "enGB" then tracked.all = true end
	end
	return tracked
end
P.IndoorTracked = Tracked

-- the nodes on a map you can gather, cached per map and skill
local nodeCache = {}
function P:NodesOn(map)
	local sk = Skills()
	local key = map .. ":" .. (sk.O or 0) .. ":" .. (sk.H or 0)
	local c = nodeCache[key]
	if c then return c end
	local zone = self:SubMapZone(map)
	if zone then
		c = self:OnSubMap(map, zone, self:NodesOn(zone))
		nodeCache[key] = c
		return c
	end
	c = {}
	local t = self:MapXform(map)
	for _, n in ipairs(NodeIndex()) do
		local have = sk[n[2]]
		if have and have >= n[3] then
			local o = P.O[n[1]]
			local pts = o and o[2] and o[2][map]
			for i = 1, #(pts or EMPTY) do
				local x, y = P.Unpack(pts[i])
				c[#c + 1] = { x = x, y = y, kind = n[2], name = o[1], wx = t and (t[2] - t[4] * x), wy = t and (t[3] - t[5] * y) }
			end
		end
	end
	nodeCache[key] = c
	return c
end

-- how far around you (in yards) the radar is showing its own blips right now; 0 when it isn't
function P:RadarReach(viewYards)
	local GS = self.GoodMap and self.GoodMap.S
	if not (GS and GS.radarEmbedded and GS.radarVisible and GS.radarFits ~= false and GS.radarD) then return 0 end
	local w = tonumber(GS.sc:GetWidth()) or 0
	if w <= 0 then return 0 end
	return GS.radarD * 0.5 * viewYards / w
end

function P:GoodMapShown()
	local NS = self.GoodMap
	return NS.ready and NS.S and NS.S.map and NS.S.map:IsShown() and true or false
end
-- the Blizzard minimap's own layers (route dots, quest spots) are drawn unless
-- GoodMap draws them itself: in its detail view the game's minimap picture is
-- what shows, so they're drawn there
function P:MinimapLayersOff()
	if not self:GoodMapShown() then return false end
	local E = self.GoodMap.E
	return not (E and E.InDetail and E.InDetail())
end

---------------------------------------------------------------------------
-- Town services on the minimap: inns, flight masters, mailboxes, banks,
-- auction houses, repairs and your class trainer. They come in when you're
-- close to some, or zoomed in on a town, and the quest dots step back.
---------------------------------------------------------------------------
local band = bit.band
local SERVICE = {
	{ key = "inn", flag = 128, icon = "Interface\\Minimap\\Tracking\\Innkeeper" },
	{ key = "bank", flag = 256, icon = "Interface\\Minimap\\Tracking\\Banker" },
	{ key = "auction", flag = 4096, icon = "Interface\\Minimap\\Tracking\\Auctioneer" },
	{ key = "repair", flag = 16384, icon = "Interface\\Minimap\\Tracking\\Repair" },
}
local ICON_MAIL, ICON_FLIGHT, ICON_CLASS = "Interface\\Minimap\\Tracking\\Mailbox", "Interface\\Minimap\\Tracking\\FlightMaster", "Interface\\Minimap\\Tracking\\Class"
local serviceCache = {}
-- every service on a map: { x, y, wx, wy, icon, name }
function P:ServicesOn(map)
	local c = serviceCache[map]
	if c then return c end
	local zone = self:SubMapZone(map)
	if zone then
		c = self:OnSubMap(map, zone, self:ServicesOn(zone))
		serviceCache[map] = c
		return c
	end
	c = {}
	local me = (self.me and self.me.faction == "Horde") and "H" or "A"
	local cls = (UnitClass("player") or ""):lower()
	local function add(x, y, icon, name)
		local _, wx, wy = self:WorldPos(map, x, y)
		c[#c + 1] = { x = x, y = y, wx = wx, wy = wy, icon = icon, name = name }
	end
	for _, row in pairs(self.SV or EMPTY) do
		if type(row[5]) == "string" and row[5]:find(me, 1, true) then
			local icon
			for _, sv in ipairs(SERVICE) do if band(row[3] or 0, sv.flag) ~= 0 then icon = sv.icon break end end
			if not icon and band(row[3] or 0, 16) ~= 0 and (row[2] or ""):lower():find(cls .. " trainer", 1, true) then icon = ICON_CLASS end
			if icon then
				local pts = row[4]
				for i = 1, #pts, 2 do
					if pts[i] == map then local x, y = P.Unpack(pts[i + 1]); add(x, y, icon, row[1]) end
				end
			end
		end
	end
	local mb = self.MB or EMPTY
	for i = 1, #mb, 2 do if mb[i] == map then local x, y = P.Unpack(mb[i + 1]); add(x, y, ICON_MAIL, "Mailbox") end end
	for _, row in pairs(self.FM or EMPTY) do
		if row[2] == map and type(row[4]) == "string" and row[4]:find(me, 1, true) then
			local x, y = P.Unpack(row[3]); add(x, y, ICON_FLIGHT, row[1])
		end
	end
	serviceCache[map] = c
	return c
end

-- are you close to a few town services (an inn, a flight master, a mailbox)? Checked once a second.
local nearAt, nearWas = 0, false
function P:NearServices()
	local now = GetTime()
	if now - nearAt < 1 then return nearWas end
	nearAt = now
	nearWas = false
	if S().serviceZoom == false then return false end
	local map = self:PlayerZone()
	local inst, px, py = self:PlayerPos()
	if not (map and inst) then return false end
	local n = 0
	for _, sv in ipairs(self:ServicesOn(map)) do
		if sv.wx and (sv.wx - px) ^ 2 + (sv.wy - py) ^ 2 < 90 * 90 then
			n = n + 1
			if n >= 2 then nearWas = true break end
		end
	end
	return nearWas
end

-- redraw only when something you'd see changed: the map, its zoom, where you
-- stand (to a few yards), the route, your quests or the settings
local lastSig
P:Listen("QUESTS_CHANGED", function() lastSig = nil end)
P:Listen("QUEST_PROGRESS", function() lastSig = nil end)
P:Listen("SETTINGS_CHANGED", function() lastSig = nil end)
P:Listen("FLIGHTS_CHANGED", function() lastSig = nil end)
function P:DrawGoodMap(force)
	if not self:GoodMapShown() then if #gmPins > 0 then GMClear() end lastSig = nil return end
	-- paths, pins and town services all off: clear once and rest
	local st = S()
	if not (st.minimapPath or st.questLayer ~= false or (st.mapPins and st.gmPins ~= false) or st.serviceZoom ~= false) then
		if #gmPins > 0 then GMClear() end
		lastSig = nil
		return
	end
	local NS = self.GoodMap
	local map = NS.S.map:GetMapID()
	local inst, px, py = self:PlayerPos()
	local r = self:LiveRoute()
	local first = r and r.stops and r.stops[1]
	local sig = table.concat({ tostring(map), ("%.3f"):format(NS.S.sc:GetCanvasScale() or 1), tostring(NS.S.round),
		px and floor(px / 4) or "-", py and floor(py / 4) or "-", tostring(P:NearServices()), r and #r.stops or 0, first and (first.key or first.quest or "") or "",
		P.layerVer or 0, first and first.atPt or "", self.corpse and "dead" or "",
		(IsIndoors and IsIndoors()) and "in" or "out", P.trackVer or 0,
		NS.S.radarVisible and NS.S.radarFits ~= false and floor((NS.S.radarD or 0) / 4) or "-", P.fireVer or 0 }, ":")
	if not force and sig == lastSig then return end
	lastSig = sig
	GMClear()
	if not map then return end
	local t = self:MapXform(map)
	if not (t and inst and t[1] == inst) then return end
	local base = (NS.E.PinLevel and NS.E.PinLevel("PIN_FRAME_LEVEL_TOPMOST", 2100) or NS.S.canvas:GetFrameLevel() + 40) + 1
	local W, H = NS.S.canvas:GetWidth(), NS.S.canvas:GetHeight()
	-- Pathway's icons follow the minimap's own icon size (60% is the usual)
	local k = (tonumber(NS.E.Get and NS.E.Get("pinScale")) or 0.6) / 0.6
	-- and grow a little with a bigger minimap, so they read the same at any size
	local mw = tonumber(NS.S.map:GetWidth()) or 300
	k = k * math.max(0.85, math.min(1.6, (mw / 300) ^ 0.5))

	-- the same quest pins as the world map: who to pick up from, who to turn in to
	-- in town, or zoomed in close: the services come up and the quests step back
	local viewYards = math.abs(t[4]) * (tonumber(NS.S.sc:GetWidth()) or 200) / math.max(W * (NS.S.sc:GetCanvasScale() or 1), 1)
	local town = S().serviceZoom ~= false and (viewYards < 450 or self:NearServices())
	if town then
		for _, sv in ipairs(self:ServicesOn(map)) do
			local f = GMPin("service", base + 4, sv.icon, 15 * k, 1)
			f.tex:SetVertexColor(1, 1, 1, 1)
			NS.E.PlaceCanvasPin(f, sv.x, sv.y)
		end
	end
	local questAlpha = town and 0.45 or 1

	-- what you track, wherever the radar isn't showing its own blips
	if S().indoorBlips ~= false and px then
		local tr = Tracked()
		local view2 = (viewYards * 0.75) ^ 2
		local hole = self:RadarReach(viewYards)
		local hole2 = hole > 0 and (hole - 4) ^ 2 or -1          -- inside the radar: its own, live blips
		if not town then
			local SVC_KEY = { ["Interface\\Minimap\\Tracking\\Mailbox"] = "mail", ["Interface\\Minimap\\Tracking\\Innkeeper"] = "inn",
				["Interface\\Minimap\\Tracking\\Banker"] = "bank", ["Interface\\Minimap\\Tracking\\Auctioneer"] = "auction",
				["Interface\\Minimap\\Tracking\\Repair"] = "repair", ["Interface\\Minimap\\Tracking\\Class"] = "class",
				["Interface\\Minimap\\Tracking\\FlightMaster"] = "flight" }
			for _, sv in ipairs(self:ServicesOn(map)) do
				local key = SVC_KEY[sv.icon]
				local d2 = sv.wx and (sv.wx - px) ^ 2 + (sv.wy - py) ^ 2
				if (tr.all or (key and tr[key])) and d2 and d2 < view2 and d2 > hole2 then
					local f = GMPin("service", base + 4, sv.icon, 15 * k, 1)
					f.tex:SetVertexColor(1, 1, 1, 1)
					NS.E.PlaceCanvasPin(f, sv.x, sv.y)
				end
			end
		end
		if tr.all or tr.O or tr.H then
			for _, n in ipairs(self:NodesOn(map)) do
				local d2 = n.wx and (n.wx - px) ^ 2 + (n.wy - py) ^ 2
				if (tr.all or tr[n.kind]) and d2 and d2 < view2 and d2 > hole2 then
					local c = NODE_COLOR[n.kind]
					local f = GMPin("node", base + 3, P.MEDIA .. "Pip", 9 * k, 1)
					f.tex:SetVertexColor(c[1], c[2], c[3], 1)
					NS.E.PlaceCanvasPin(f, n.x, n.y)
				end
			end
		end
	end

	local layerOn = S().questLayer ~= false
	if layerOn then self:DrawGoodMapQuestLayer(map, t, px, py, base, k, W, H, questAlpha) end
	if S().mapPins and S().gmPins ~= false then
		-- where each objective is: soft areas under the dots, clipped to a round map
		-- (the game's own quest areas can't be clipped, so on a round map they're off)
		if NS.S.round and not layerOn then
			local cur = r and r.stops and r.stops[1]
			local yd = W / math.max(math.abs(t[4]), 1) * (NS.S.sc:GetCanvasScale() or 1)      -- screen pixels a yard
			local size = math.max(18, math.min(90, 70 * yd))                                  -- about 70 yards across
			for _, mk in ipairs(self:Markers(map)) do
				if mk.kind == "objective" then
					local mine = cur and cur.quest and mk.quests and mk.quests[1] == cur.quest
					local f = GMPin("area", base - 2, P.MEDIA .. "Glow", size, (mine and 0.32 or 0.14) * questAlpha)
					NS.E.PlaceCanvasPin(f, mk.x, mk.y)
				end
			end
		end
		for _, mk in ipairs(self:Markers(map)) do
			if mk.kind == "objective" then
				if not layerOn then
					local f = GMPin("obj", base + 1, P.MEDIA .. "Dot", 6 * k, 0.9 * questAlpha)
					NS.E.PlaceCanvasPin(f, mk.x, mk.y)
				end
			else
				local f = GMPin("quest", base + 3, mk.kind == "turnin" and ICON_TURN or ICON_PICK, 14 * k, 1)
				f.tex:SetVertexColor(1, 1, 1, town and 0.8 or 1)
				NS.E.PlaceCanvasPin(f, mk.x, mk.y)
			end
		end
	end

	-- flight paths (undiscovered ones in gold)
	local fmode = S().flightPins or "undiscovered"
	if fmode ~= "off" then
		for _, fp in ipairs(self:FlightList()) do
			if fp.inst == inst and (not fp.known or fmode == "all") then
				local fx, fy = self:MapPos(map, fp.wx, fp.wy)
				if fx and fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1 then
					local f = GMPin("flight", base + 2, fp.known and "Interface\\TaxiFrame\\UI-Taxi-Icon-Green"
						or "Interface\\TaxiFrame\\UI-Taxi-Icon-White", (fp.known and 10 or 14) * k, 1)
					if fp.known then f.tex:SetVertexColor(1, 1, 1, 1) else f.tex:SetVertexColor(1, 0.82, 0.3, 1) end
					NS.E.PlaceCanvasPin(f, fx, fy)
				end
			end
		end
	end
	if S().firePins ~= false and self.Campfires then
		for _, fire in ipairs(self:FirePins(inst)) do
			local fx, fy = self:MapPos(map, fire.x, fire.y)
			if fx and fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1 then
				local g = GMPin("fireglow", base + 1, P.MEDIA .. "Glow", 24 * k, 1)
				g.tex:SetVertexColor(1, 0.5, 0.15, fire.exact and 0.7 or 0.35)
				NS.E.PlaceCanvasPin(g, fx, fy)
				local f = GMPin("fire", base + 3, FIRE_ICON, (fire.exact and 14 or 12) * k, 1)
				f.tex:SetVertexColor(1, 1, 1, fire.exact and 1 or 0.7)
				NS.E.PlaceCanvasPin(f, fx, fy)
			end
		end
	end
	if not ((self.corpse or self.route) and S().minimapPath) then return end
	local spacing = 10 / math.max(NS.S.sc:GetCanvasScale(), 0.01)

	local pts = {}
	local x, y = self:MapPos(map, px, py)
	pts[1] = { x, y }
	-- a turn-in run shows every stop, numbered in order; other routes the next four
	local most = (not self.corpse and self.route.mode == "turnins") and 30 or 4
	for i, s in ipairs(self.corpse and { self.corpse } or self.route.stops) do
		if i > most or not s.wx then break end
		local sx, sy = self:MapPos(map, s.wx, s.wy)
		pts[#pts + 1] = { sx, sy, s, i }
	end
	for i = 2, #pts do
		local x1, y1, x2, y2 = pts[i - 1][1], pts[i - 1][2], pts[i][1], pts[i][2]
		local dx, dy = (x2 - x1) * W, (y2 - y1) * H
		local n = math.floor(math.sqrt(dx * dx + dy * dy) / spacing)
		if i > 5 then n = 0 end                    -- the trail only to the next four: the rest are numbered rings
		for j = 1, math.min(n - 1, 160) do
			local f = GMPin("dot", base, P.MEDIA .. "Dot", (i == 2 and 5 or 4) * k, i == 2 and 0.95 or 0.45)
			NS.E.PlaceCanvasPin(f, x1 + (x2 - x1) * j / n, y1 + (y2 - y1) * j / n)
		end
		local stop = GMPin("stop", base + 5, P.MEDIA .. "Ring", (pts[i][4] == 1 and 16 or 12) * k, pts[i][4] == 1 and 1 or 0.6)
		stop.num:SetText(pts[i][4])
		NS.E.PlaceCanvasPin(stop, x2, y2)
	end
end

-- The quest layer on GoodMap: each quest's spots in its color, the next spot
-- pulsing (an animation on the pin, so no redraws), checked spots hollow, and
-- a chevron on the rim for a quest with nothing in view.
local function Pulse(f)
	if f.pwPulse then return end
	local ag = f.tex:CreateAnimationGroup()
	ag:SetLooping("REPEAT")
	local sc = ag:CreateAnimation("Scale"); sc:SetScale(1.6, 1.6); sc:SetDuration(0.9); sc:SetOrder(1)
	local al = ag:CreateAnimation("Alpha"); al:SetFromAlpha(1); al:SetToAlpha(0.2); al:SetDuration(0.9); al:SetOrder(1)
	f.pwPulse = ag
end
function P:DrawGoodMapQuestLayer(map, t, px, py, base, k, W, H, dim)
	local NS = self.GoodMap
	local E = NS.E
	local cs = NS.S.sc:GetCanvasScale() or 1
	local viewYards = math.abs(t[4]) * (tonumber(NS.S.sc:GetWidth()) or 200) / math.max(W * cs, 1)
	local inView, outside = self:QuestLayerAround(map, px, py, viewYards * 0.75)
	dim = dim or 1
	for i = 1, #inView do
		local s = inView[i]
		local c, mine = self:QuestColor(s.qid)
		if s.checked then
			local f = GMPin("qring", base + 1, P.MEDIA .. "PipHollow", 10 * k, 1)
			f.tex:SetVertexColor(c[1], c[2], c[3], 0.85 * dim)
			E.PlaceCanvasPin(f, s.x, s.y)
		else
			-- the guide's quest glows under its spots, so it stands out from the rest
			if mine then
				local g = GMPin("qglow", base - 1, P.MEDIA .. "Glow", 26 * k, 1)
				g.tex:SetVertexColor(c[1], c[2], c[3], 0.45 * dim)
				E.PlaceCanvasPin(g, s.x, s.y)
			end
			local f = GMPin("qcore", base + 1, P.MEDIA .. "Pip", (mine and 13 or 11) * k, 1)
			f.tex:SetVertexColor(c[1], c[2], c[3], dim)
			E.PlaceCanvasPin(f, s.x, s.y)
			if s.isNext then
				local p = GMPin("qpulse", base + 2, P.MEDIA .. "Halo", 16 * k, 1)
				p.tex:SetVertexColor(c[1], c[2], c[3], 1)
				Pulse(p)
				E.PlaceCanvasPin(p, s.x, s.y)
				if not p.pwPulse:IsPlaying() then p.pwPulse:Play() end
			end
		end
	end
	-- off the map: a chevron on the rim, toward the quest's closest spot
	local cx, cy = NS.S.sc:GetCurrentScrollX(), NS.S.sc:GetCurrentScrollY()
	local diam = E.Diameter and E.Diameter() or NS.S.map:GetWidth()
	if not (cx and diam) then return end
	local r = diam / 2 - 11
	for i = 1, #outside do
		local s = outside[i]
		local dx, dy = (s.x - cx) * W * cs, (s.y - cy) * H * cs        -- screen pixels, y down
		local d = math.sqrt(dx * dx + dy * dy)
		if d > 1 then
			local kk = NS.S.round and r / d or r / math.max(math.abs(dx), math.abs(dy))
			local c, mine = self:QuestColor(s.qid)
			local f = GMPin("qchev", base + 6, P.MEDIA .. "Pointer", (mine and 18 or 15) * k, 1)
			f.tex:SetVertexColor(c[1], c[2], c[3], 1)
			f.tex:SetRotation(P.PointAngle(dx, -dy))
			E.PlaceCanvasPin(f, cx + dx * kk / (W * cs), cy + dy * kk / (H * cs))
		end
	end
end

P:Listen("READY", function()
	local t = 0
	local ticker = CreateFrame("Frame")
	ticker:SetScript("OnUpdate", function(_, dt)
		t = t + dt
		if t < 0.5 then return end
		t = 0
		P:DrawGoodMap()
	end)
	P.Perf.Hook(ticker, "World map pins", "OnUpdate")
end)
P:Listen("ROUTE_CHANGED", function() P:DrawGoodMap(true) end)
P:Listen("SETTINGS_CHANGED", function() P:DrawGoodMap() end)
P:Listen("MAP_LOOK_CHANGED", function() C_Timer.After(0.05, function() P:DrawGoodMap() end) end)
P:Listen("FLIGHTS_CHANGED", function() P:DrawGoodMap(); if WorldMapFrame and WorldMapFrame:IsShown() then P:DrawPins() end end)
P:Listen("FIRES_CHANGED", function() P:DrawGoodMap(); if WorldMapFrame and WorldMapFrame:IsShown() then P:DrawPins() end end)

-- what you track and what you can gather change what the indoor layer shows
local function TrackChanged()
	skillAt, trackAt = 0, 0
	P.trackVer = (P.trackVer or 0) + 1
	if P.DrawGoodMap then P:DrawGoodMap() end
end
P:On("MINIMAP_UPDATE_TRACKING", TrackChanged)
P:On("SKILL_LINES_CHANGED", TrackChanged)
P:On("ZONE_CHANGED_INDOORS", function() if P.DrawGoodMap then P:DrawGoodMap() end end)
end part() end
-- ==================== Guide.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Step guide
     The guide window: the step you're on, in plain words ("Head north-east,
     230 yd"), a 3D look at who or what you're after, where drops come from,
     and the steps coming up (click one to do it next).
     The quest bar: a box with the face of each thing this step needs you to
     target, and a box for each quest item in your bags to use on it. Each
     can be bound to a key (Options > Keybindings). ]]

local ADDON, P = __addon, __ns
local A, K = P.ACCENT, P.K
local floor, pi, min, max = math.floor, math.pi, math.min, math.max
local ipairs, pairs = ipairs, pairs
local EMPTY = {}

local function S() return P.db.settings end

BINDING_HEADER_PATHWAY = "Pathway"
BINDING_NAME_PATHWAY_NEXT = "Go to the next set of quests"
BINDING_NAME_PATHWAY_SKIP = "Skip this stop"
BINDING_NAME_PATHWAY_GUIDE = "Show or hide the guide window"
BINDING_NAME_PATHWAY_JOURNAL = "Open the quest journal"
_G["BINDING_NAME_CLICK PathwayTargetButton:LeftButton"] = "Target what this step needs"
_G["BINDING_NAME_CLICK PathwayTargetButton2:LeftButton"] = "Target what this step needs (2nd)"
_G["BINDING_NAME_CLICK PathwayTargetButton3:LeftButton"] = "Target what this step needs (3rd)"
_G["BINDING_NAME_CLICK PathwayTargetButton4:LeftButton"] = "Target what this step needs (4th)"
_G["BINDING_NAME_CLICK PathwayItemButton:LeftButton"] = "Use this step's quest item"
_G["BINDING_NAME_CLICK PathwayItemButton2:LeftButton"] = "Use this step's quest item (2nd)"
_G["BINDING_NAME_CLICK PathwayItemButton3:LeftButton"] = "Use this step's quest item (3rd)"
_G["BINDING_NAME_CLICK PathwayStepButton:LeftButton"] = "Do this step: target, then use its item"

---------------------------------------------------------------------------
-- Plain-language directions
---------------------------------------------------------------------------
local COMPASS = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" }

function P:Compass(angle)
	local cw = (2 * pi - angle) % (2 * pi)                -- clockwise from north
	return COMPASS[floor((cw + pi / 8) / (pi / 4)) % 8 + 1]
end

function P:Directions(s)
	-- a hearth or teleport is used where you stand: no walking first
	if s.trip == "jump" then return "|c" .. P.ACCENT_HEX .. "Use it where you stand|r" end
	local where = ("%s  %.1f, %.1f"):format(self:MapName(s.map), s.x * 100, s.y * 100)
	local inst, px, py = self:PlayerPos()
	local t = self:MapXform(s.map)
	if not inst or not t or t[1] ~= inst then return "In " .. where .. P.DIM .. "  (another continent)|r" end
	local dist, angle = P.Vector(px, py, s.wx, s.wy)
	if dist < (s.quest and 25 or S().arriveDistance) then return "|c" .. P.ACCENT_HEX .. "You're here|r  " .. P.DIM .. where .. "|r" end
	local yd = dist >= 1000 and ("%.1fk yd"):format(dist / 1000) or ("%d yd"):format(floor(dist + 0.5))
	return ("Head |cffffffff%s|r  ·  %s  " .. P.DIM .. "%s|r"):format(self:Compass(angle), yd, where)
end

local function Names(ents, kind, n)
	local out, seen = {}, {}
	for _, e in ipairs(ents or {}) do
		if (not kind or e[1] == kind) then
			local name = P:EntityName(e[1], e[2])
			if name ~= "" and not seen[name] then seen[name] = true; out[#out + 1] = name end
			if #out >= n then break end
		end
	end
	return table.concat(out, ", ")
end

-- what to say about a stop, line by line
function P:StopDetails(s)
	local lines = {}
	if s.travel then
		lines[1] = ("Talk to %s and fly to |cffffffff%s|r in %s."):format(s.name, s.flyName, self:MapName(s.flyMap))
		local saves = tonumber(s.saves)
		if s.easier then
			lines[2] = P.DIM .. ("Less running: about %d min of it in the air."):format(max(1, floor(s.easier / 60 + 0.5))) .. "|r"
		elseif saves and saves > 0 and saves < 1e6 then
			lines[2] = P.DIM .. ("Saves about %d min over running."):format(max(1, floor(saves / 60 + 0.5))) .. "|r"
		end
		return lines
	end
	-- a leg of a longer trip: a boat, the tram, a hearth: say what it's for
	if s.trip then
		lines[1] = "On the way to |cffffffff" .. (s.name or "your next step") .. "|r"
		if s.easier then
			lines[2] = P.DIM .. ("Less running: about %d min sitting back."):format(max(1, floor(s.easier / 60 + 0.5))) .. "|r"
		elseif s.saves and s.saves < 1e6 and s.saves > 30 then
			lines[2] = P.DIM .. ("Saves about %d min."):format(max(1, floor(s.saves / 60 + 0.5))) .. "|r"
		else
			lines[2] = P.DIM .. "It's the only way there from here.|r"
		end
		return lines
	end
	if s.bind then
		lines[1] = "Talk to |cffffffff" .. (s.name or "the innkeeper") .. "|r and choose |cffffffffMake this inn your home|r."
		if s.tip then lines[2] = P.DIM .. s.tip .. "|r" end
		return lines
	end
	if s.inZone then
		lines[1] = "On your way to |cffffffff" .. self:MapName(s.inZone) .. "|r, the fastest way."
		if s.way then lines[2] = P.DIM .. s.way .. "|r" end
		return lines
	end
	if s.flight then
		lines[1] = "Talk to |cffffffff" .. (s.name or "the flight master") .. "|r: a new flight path is yours, and the flight map shows Pathway every one you know."
		lines[2] = P.DIM .. "From then on it flies you whenever that's faster. Already know it? Click Done.|r"
		return lines
	end
	if s.quest then
		local q = self.Q[s.quest]
		local e = self.log[s.quest]
		local o = e and e.objectives and e.objectives[s.index]
		lines[#lines + 1] = P.GOLD .. (q and q[K.NAME] or "") .. "|r"
		local mates = self.PartyOn and self:PartyOn(s.quest)
		if mates then lines[#lines + 1] = "|c" .. P.ACCENT_HEX .. "Your group has it too: " .. mates .. "|r" end
		if o and o.text then lines[#lines + 1] = "|cffffffff" .. o.text .. "|r" end
		local npcs, objs = Names(s.ents, "N", 3), Names(s.ents, "O", 3)
		local text = (o and o.text or ""):lower()
		local isItem = o and (o.type == "item")
		if npcs ~= "" then
			if isItem then lines[#lines + 1] = "Drops from: |cffffffff" .. npcs .. "|r"
			elseif text:find("slain") or o and o.type == "monster" then lines[#lines + 1] = "Look for: |cffffffff" .. npcs .. "|r"
			else lines[#lines + 1] = "Find: |cffffffff" .. npcs .. "|r" end
		end
		if objs ~= "" then lines[#lines + 1] = (isItem and "Found in: " or "Look for: ") .. "|cffffffff" .. objs .. "|r  " .. P.DIM .. "(click it in the world)|r" end
		if q and q[K.TEXT] and #lines < 5 then lines[#lines + 1] = P.DIM .. q[K.TEXT] .. "|r" end
		return lines
	end
	local pick, turn = self:EntityWork(s.key)
	for _, qid in ipairs(turn) do lines[#lines + 1] = "|cff7cf29cTurn in|r  " .. (self.Q[qid] and self.Q[qid][K.NAME] or "") end
	-- one quest to hand in: its own words say where and who ("Speak with... in Stormwind")
	if #turn == 1 and #pick == 0 then
		local q = self.Q[turn[1]]
		if q and q[K.TEXT] and q[K.TEXT] ~= "" then lines[#lines + 1] = P.DIM .. q[K.TEXT] .. "|r" end
	end
	for _, qid in ipairs(pick) do
		local q = self.Q[qid]
		if q then lines[#lines + 1] = P.GOLD .. "Pick up|r  " .. q[K.NAME] .. P.DIM .. "  (level " .. (q[K.LVL] or "?") .. ")|r" end
	end
	return lines
end

---------------------------------------------------------------------------
-- The plan for a step: what to do, in order, in plain words. "Kill Sneed's
-- Shredder", "Loot the Gnoam Sprecklesprocket", "Then: hand it in to Shoni the
-- Shilent, Stormwind". Shown numbered in the guide; the first one not done yet
-- is lit.
---------------------------------------------------------------------------
local W = "|cffffffff"
local function Dungeon(ents)
	for _, e in ipairs(ents or EMPTY) do
		local ent = P:Entity(e[1], e[2])
		if ent and type(ent[3]) == "string" and ent[3] ~= "" then return ent[3] end
	end
end

-- who a finished quest goes back to, and where they are
function P:HandInTo(qid)
	local q = self.Q[qid]
	if not q then return end
	local id = q[K.EN] and q[K.EN][1]
	local who = id and self:EntityName("N", id)
	if (not who or who == "") and q[K.EO] and q[K.EO][1] then who = self:EntityName("O", q[K.EO][1]) end
	local ent = id and self:Entity("N", id)
	local map = ent and ent[2] and next(ent[2])
	local zone = map and self:MapName(self:ZoneOf(map) or map)
	if zone == "?" or zone == "" then zone = nil end
	return (who ~= "" and who or nil), zone
end

-- "level 9-10" for the creatures of a step
local function Levels(ents)
	local lo, hi
	for _, e in ipairs(ents or EMPTY) do
		if e[1] == "N" then
			local ent = P.N and P.N[e[2]]
			local l = ent and tonumber(ent[6])
			if l and l > 0 then lo, hi = math.min(lo or l, l), math.max(hi or l, l) end
		end
	end
	if not lo then return "" end
	return P.DIM .. "  (level " .. (lo == hi and lo or (lo .. "-" .. hi)) .. ")|r"
end

function P:StepPlan(s)
	local plan = {}
	local function add(t, done) plan[#plan + 1] = { text = t, done = done } end
	if s.travel then
		add("Talk to " .. W .. (s.name or "the flight master") .. "|r")
		add("Fly to " .. W .. (s.flyName or self:MapName(s.flyMap)) .. "|r")
		return plan
	end
	if s.flight then
		add("Talk to " .. W .. (s.name or "the flight master") .. "|r")
		add("The flight map opens: that's the flight path learned")
		return plan
	end
	if s.trip then return plan end
	if s.bind then
		add("Talk to " .. W .. (s.name or "the innkeeper") .. "|r")
		add("Choose " .. W .. "Make this inn your home|r")
		return plan
	end
	if s.goal then add(s.goal .. (s.name and s.name ~= "" and (" " .. W .. s.name .. "|r") or "")) return plan end
	if s.quest then
		local qid = s.quest
		local q, e = self.Q[qid], self.log[qid]
		local o = e and e.objectives and e.objectives[s.index]
		local otext = (o and o.text) or s.text or ""
		local count = otext:match("(%d+%s*/%s*%d+)%s*$")
		local thing = otext:gsub(":?%s*%d+%s*/%s*%d+%s*$", ""):gsub("%s+slain$", "")
		local npcs, objs = Names(s.ents, "N", 2), Names(s.ents, "O", 2)
		local dungeon = Dungeon(s.ents)
		local elite = self:QuestElite(qid)
		local typ = o and o.type
		local low = otext:lower()
		local how = self.HowHint and self:HowHint(qid, s.index)
		if how then
			-- a guide writer's own words for it, one action a line
			local parts = {}
			for part in (how .. "."):gmatch("%s*(.-)%.") do if part ~= "" then parts[#parts + 1] = part end end
			for i, part in ipairs(parts) do
				if i > 3 then break end
				local last = i == #parts or i == 3
				add(part:gsub("^%l", string.upper) .. ((last and count) and ("  " .. W .. count .. "|r") or ""), last and o and o.finished)
			end
		elseif s.area and #npcs == 0 and #objs == 0 then
			add("Head to the quest area on your map")
			add(W .. (thing ~= "" and thing or "Do the objective") .. "|r" .. (count and ("  " .. count) or ""), o and o.finished)
		elseif s.point and #npcs == 0 and #objs == 0 then
			add("Go to the spot on your map: " .. W .. (thing ~= "" and thing or "it counts when you get there") .. "|r")
		elseif typ == "item" or (q and q[K.OI] and not low:find("slain")) and (#npcs > 0 or #objs > 0) and typ ~= "monster" then
			if #objs > 0 then
				add("Find " .. W .. objs .. "|r and click it")
			end
			if #npcs > 0 then
				add("Kill " .. W .. npcs .. "|r" .. Levels(s.ents))
			end
			add("Loot " .. W .. thing .. "|r" .. (count and ("  " .. count) or ""), o and o.finished)
		elseif typ == "monster" or low:find("slain") then
			add("Kill " .. W .. (npcs ~= "" and npcs or thing) .. "|r" .. (count and ("  " .. count) or "") .. Levels(s.ents), o and o.finished)
		elseif #objs > 0 then
			add("Find " .. W .. objs .. "|r and click it" .. (count and ("  " .. count) or ""), o and o.finished)
		elseif #npcs > 0 then
			add("Find " .. W .. npcs .. "|r and talk to them", o and o.finished)
		else
			add(W .. (otext ~= "" and otext or "Do the objective") .. "|r", o and o.finished)
		end
		-- no guide writer's tip: say how many spots there are, and what the quest itself says
		if not how then
			local spots = false
			if #objs > 0 then
				local n, map = self:SpotCount(s.ents)
				if n > 1 then
					spots = true
					add(P.DIM .. ("%d spots in %s: the arrow moves on as you check each one|r"):format(n, self:MapName(self:ZoneOf(map) or map)))
				end
			end
			local txt = not spots and q and q[K.TEXT]
			if type(txt) == "string" and txt ~= "" then
				if #txt > 140 then txt = txt:sub(1, 137):gsub("%s+%S*$", "") .. "..." end
				add(P.DIM .. txt .. "|r")
			end
		end
		-- a quest item to use: say so, unless the writer already did
		for _, id in ipairs(q and q[K.USE] or EMPTY) do
			local it = P.I and P.I[id]
			local nm = it and it[1]
			if nm and not (how and how:find(nm, 1, true)) then
				add("Use " .. W .. nm .. "|r" .. P.DIM .. "  (it's on your quest bar)|r")
				break
			end
		end
		if dungeon then
			table.insert(plan, 1, { text = "|cffff8c4dInside " .. dungeon .. " (a dungeon): bring a group|r" })
		elseif elite then
			table.insert(plan, 1, { text = ("|cffff8c4dElite (level %d): bring a friend or two|r"):format(elite) })
		end
		-- what comes after: the next objective, or the hand-in
		local left = 0
		for i, ob in ipairs(e and e.objectives or EMPTY) do if i ~= s.index and not ob.finished then left = left + 1 end end
		if left == 0 then
			local who, zone = self:HandInTo(qid)
			if who then add(P.DIM .. "Then hand it in: |r" .. who .. (zone and (P.DIM .. ", " .. zone .. "|r") or "")) end
		else
			add(P.DIM .. ("Then %d more objective%s for this quest|r"):format(left, left == 1 and "" or "s"))
		end
		return plan
	end
	local pick, turn = self:EntityWork(s.key)
	local who = s.name and s.name ~= "" and s.name or "them"
	local isObj = s.key and s.key:sub(1, 1) == "O"
	add((isObj and "Click " or "Talk to ") .. W .. who .. "|r")
	for _, qid in ipairs(turn) do
		local q = self.Q[qid]
		add("Turn in " .. W .. (q and q[K.NAME] or "") .. "|r")
	end
	for _, qid in ipairs(pick) do
		local q = self.Q[qid]
		if q then add("Accept " .. W .. q[K.NAME] .. "|r" .. P.DIM .. "  (level " .. (q[K.LVL] or "?") .. ")|r") end
	end
	-- a pickup that sends you straight on: what it asks for, in its words
	if #pick == 1 and #turn == 0 then
		local q = self.Q[pick[1]]
		local t = q and q[K.TEXT]
		if t and t ~= "" then
			if #t > 140 then t = t:sub(1, 137):gsub("%s+%S*$", "") .. "..." end
			add(P.DIM .. t .. "|r")
		end
	elseif #turn == 1 and #pick == 0 then
		-- nothing new here: where the story goes next is the next step's job
	end
	return plan
end

-- the plan as text: numbered, the first step not done lit up
function P:PlanText(plan, max)
	local out, n, lit = {}, 0, false
	for _, p in ipairs(plan) do
		if #out >= (max or 5) then break end
		local t = p.text
		if t:find("^|cffff8c4d") or t:find("^" .. P.DIM:gsub("%|", "%%|")) then
			out[#out + 1] = t                                  -- a warning or a "then": no number
		else
			n = n + 1
			local num
			if p.done then num = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12|t"
			elseif not lit then lit = true; num = "|c" .. P.ACCENT_HEX .. n .. "|r"
			else num = P.DIM .. n .. "|r" end
			out[#out + 1] = num .. "  " .. (p.done and (P.DIM .. t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. "|r") or t)
		end
	end
	return out
end

-- the creature to show and target for a stop
function P:StopCreature(s)
	if s.travel then return s.ents[1][2], s.name end
	local at = s.at
	if at and at[1] == "N" then return at[2], P:EntityName("N", at[2]) end
	for _, e in ipairs(s.ents or {}) do if e[1] == "N" then return e[2], P:EntityName("N", e[2]) end end
end

---------------------------------------------------------------------------
-- The guide window
---------------------------------------------------------------------------
local win

local function SavePos(f)
	-- the guide is kept by its top: a long step makes it grow down, not up over the minimap
	if f == win then P:KeepTop(f) return end
	local p, _, rp, x, y = f:GetPoint(); P.db.pos[f:GetName()] = { p, rp, x, y }
end

local W_GUIDE, NEXT_ROWS, QUEST_ROWS = 300, 1, 10

-- your quests, the ones that matter most now first: the step you're on, then
-- what your guide (its style: story, all quests or fastest XP) has next, then the
-- most experience for the least travel. Ready to hand in counts double.
function P:QuestsByRelevance(s)
	local cur = s and s.quest
	local inRoute, order = {}, 0
	local r = self.route
	if r then
		for _, st in ipairs(r.stops or EMPTY) do
			order = order + 1
			if st.quest and not inRoute[st.quest] then inRoute[st.quest] = order end
			if st.key and not st.quest then
				local pick, turn = self:EntityWork(st.key)
				for _, qid in ipairs(turn) do if not inRoute[qid] then inRoute[qid] = order end end
			end
		end
		for qid in pairs(r.quests or EMPTY) do if self.log[qid] and not inRoute[qid] then inRoute[qid] = 900 end end
	end
	local speed = (self.TravelSpeed and self.TravelSpeed()) or 7
	local list = {}
	for qid, e in pairs(self.log) do
	  if not self:Hidden(qid) then
		local ok, where, far, yd = pcall(self.QuestWhere, self, qid)
		if not ok then where, far, yd = nil, false, 1e6 end
		local xp = self.QuestXP and self:QuestXP(qid) or 100
		if e.complete then xp = xp * 2 end
		local secs = (yd or 1e6) / speed + 60 + (far and 600 or 0)
		list[#list + 1] = { qid = qid, e = e, where = where, value = xp / secs, route = inRoute[qid] }
	  end
	end
	table.sort(list, function(a, b)
		if (a.qid == cur) ~= (b.qid == cur) then return a.qid == cur end
		if (a.route ~= nil) ~= (b.route ~= nil) then return a.route ~= nil end
		if a.route and b.route and a.route ~= b.route then return a.route < b.route end
		if a.value ~= b.value then return a.value > b.value end
		return (a.e.title or "") < (b.e.title or "")
	end)
	return list, cur
end

-- click a quest: follow just that one. If Pathway can't place any of it yet,
-- the journal opens on it, with what it says to do.
function P:FollowQuest(qid)
	local q = self.Q[qid]
	if self:Hidden(qid) then self:BringBack(qid) end           -- you asked for it: it's back
	if self:LoadGuide("quest:" .. qid, true) then
		self:Toast("Following: " .. (q and q[P.K.NAME] or "your quest"))
		if self.SetGuideState then self:SetGuideState("open") end
		return true
	end
	self:Toast("Pathway doesn't know where this one's done yet: here's what it says")
	if q and self.ShowQuestInJournal then self:ShowQuestInJournal(qid)
	elseif QuestMapFrame_OpenToQuestDetails then QuestMapFrame_OpenToQuestDetails(qid) end
	return false
end
local KIND_ICON = {
	pickup = "Interface\\GossipFrame\\AvailableQuestIcon", turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
	objective = "Interface\\Icons\\INV_Misc_Spyglass_02", travel = "Interface\\Icons\\Ability_Mount_Gryphon_01",
	flight = "Interface\\TaxiFrame\\UI-Taxi-Icon-White", goal = "Interface\\Icons\\INV_Misc_Map_01",
}
local KIND_FULL = { pickup = true, turnin = true, flight = true }   -- glyph textures shown whole, not cropped

local function Build()
	win = CreateFrame("Frame", "PathwayGuide", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	P.Flat(win, P.colors.BG, nil, true)
	win:SetSize(W_GUIDE, 120)
	win:SetClampedToScreen(true)
	win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", function(self) if P:CanDrag() then self:StartMoving() end end)
	win:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos(self) end)
	win:Hide()
	P:PlaceAt(win)
	-- a spot saved by its bottom (from before): turned into the same spot by its top, the
	-- first time it's on screen with its step in it
	local was = P.db.pos.PathwayGuide
	if was and not tostring(was[1]):find("^TOP") then
		win:HookScript("OnShow", function(self)
			C_Timer.After(0.3, function()
				local now = P.db.pos.PathwayGuide
				if now and not tostring(now[1]):find("^TOP") and self:IsShown() then P:KeepTop(self) end
			end)
		end)
	end

	-- header: the guide's name, a menu, close
	win.title = win:CreateFontString(nil, "OVERLAY")
	win.title:SetFontObject(P.fonts.head)
	win.title:SetPoint("TOPLEFT", 14, -12)
	win.title:SetJustifyH("LEFT"); win.title:SetWordWrap(false)
	local close = P:CloseButton(win, function() P:SetGuideState("mini") end)
	close:SetPoint("TOPRIGHT", -6, -6)
	close.tip = "Tuck it away: a slim bar stays, click it to bring the guide back"
	win.close = close
	local menu = CreateFrame("Button", nil, win)
	menu:SetSize(18, 16); menu:SetPoint("RIGHT", close, "LEFT", -2, 0)
	menu.dots = {}
	for i = 1, 3 do
		local d = menu:CreateTexture(nil, "ARTWORK")
		d:SetColorTexture(0.75, 0.78, 0.82, 1); d:SetSize(3, 3); d:SetPoint("CENTER", (i - 2) * 5, 0)
		menu.dots[i] = d
	end
	menu:SetScript("OnEnter", function(self) for _, d in ipairs(self.dots) do d:SetColorTexture(A[1], A[2], A[3], 1) end end)
	menu:SetScript("OnLeave", function(self) for _, d in ipairs(self.dots) do d:SetColorTexture(0.75, 0.78, 0.82, 1) end end)
	menu:SetScript("OnClick", function(self)
		local m = MenuUtil or P.MiniMenu
		m.CreateContextMenu(self, function(_, root)
			local cur = P:Current()
			root:CreateButton("Skip (until my next level)", function() P:SkipStop() end)
			if cur and #P:StepQuests(cur) > 0 then
				root:CreateButton("Mark quest completed (never show it again)", function() P:NeverStep() end)
			end
			root:CreateButton("Mark this step done", function() P:MarkStepDone() end)
			if cur and not cur.quest and cur.key and #(P:EntityWork(cur.key)) > 0 then
				root:CreateButton("I can't get this quest here", function() P:NotOfferedHere(cur) end)
			end
			root:CreateButton("Quest journal", function() P:ToggleJournal() end)
			root:CreateButton("Closest quests", function() P:StartRoute("next") end)
			root:CreateDivider()
			root:CreateButton("Close this guide", function() P:StopRoute() end)
			root:CreateButton("Hide the guide window", function() P:SetGuideState("hidden") end)
		end)
	end)
	-- the journal, one click from the guide
	local book = CreateFrame("Button", nil, win)
	book:SetSize(18, 18); book:SetPoint("RIGHT", menu, "LEFT", -4, 0)
	book.icon = book:CreateTexture(nil, "ARTWORK"); book.icon:SetAllPoints()
	book.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09"); book.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	book.icon:SetVertexColor(0.85, 0.87, 0.9)
	book:SetScript("OnClick", function() P:ToggleJournal() end)
	book:SetScript("OnEnter", function(self)
		self.icon:SetVertexColor(1, 1, 1)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("Quest journal", 1, 1, 1)
		GameTooltip:AddLine("Every zone, story chain and quest, and what to do next", 0.7, 0.75, 0.8, true)
		GameTooltip:Show()
	end)
	book:SetScript("OnLeave", function(self) self.icon:SetVertexColor(0.85, 0.87, 0.9); GameTooltip:Hide() end)
	win.book = book
	win.title:SetPoint("RIGHT", book, "LEFT", -6, 0)
	win.menu = menu

	-- tabs: each guide you're following, side by side
	win.tabs = {}
	for i = 1, 6 do
		local b = CreateFrame("Button", nil, win)
		b:SetHeight(20)
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b.text = b:CreateFontString(nil, "OVERLAY"); b.text:SetFontObject(P.fonts.head)
		b.text:SetPoint("LEFT", 6, 0); b.text:SetPoint("RIGHT", -16, 0); b.text:SetWordWrap(false)
		-- an x on every tab closes that guide
		b.x = CreateFrame("Button", nil, b)
		b.x:SetSize(12, 12); b.x:SetPoint("RIGHT", -2, 1)
		b.x.t = b.x:CreateFontString(nil, "OVERLAY"); b.x.t:SetFontObject(P.fonts.head); b.x.t:SetPoint("CENTER")
		b.x.t:SetText("x"); b.x.t:SetTextColor(0.55, 0.58, 0.62)
		b.x:SetScript("OnEnter", function(self) self.t:SetTextColor(1, 0.4, 0.35); GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Close this guide", 1, 1, 1); GameTooltip:Show() end)
		b.x:SetScript("OnLeave", function(self) self.t:SetTextColor(0.55, 0.58, 0.62); GameTooltip:Hide() end)
		b.x:SetScript("OnClick", function() if b.track then P:CloseTrack(b.track) end end)
		b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetHeight(2)
		b.line:SetPoint("BOTTOMLEFT", 2, 0); b.line:SetPoint("BOTTOMRIGHT", -2, 0)
		b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.05)
		b:SetScript("OnClick", function(self, button)
			if self.add then P:ToggleJournal() return end
			if button == "RightButton" then P:CloseTrack(self.track) else P:SwitchTrack(self.track) end
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			if self.add then
				GameTooltip:SetText("Add a guide", 1, 1, 1)
				GameTooltip:AddLine("Pick one in the journal: it opens in a new tab", 0.7, 0.75, 0.8)
			else
				GameTooltip:SetText(self.full or "", 1, 1, 1)
				GameTooltip:AddLine("Click to switch  ·  x or right-click to close", 0.7, 0.75, 0.8)
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		b:Hide()
		win.tabs[i] = b
	end

	-- how to quest this zone: Story · All quests · Fastest XP, one click to switch
	win.styles = {}
	for i = 1, 3 do
		local b = CreateFrame("Button", nil, win)
		b:SetHeight(20)
		b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
		b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetHeight(2)
		b.line:SetPoint("BOTTOMLEFT", 3, 0); b.line:SetPoint("BOTTOMRIGHT", -3, 0)
		b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.06)
		b.text = b:CreateFontString(nil, "OVERLAY"); b.text:SetFontObject(P.fonts.head); b.text:SetPoint("CENTER", 0, 1)
		b:SetScript("OnClick", function(self)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
			P:PlayZone(P:RouteZone(), self.style.key)
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.style.long .. ": " .. P:MapName(P:RouteZone()), 1, 1, 1)
			GameTooltip:AddLine(self.style.tip, 0.7, 0.75, 0.8, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		win.styles[i] = b
	end

	-- Turn in all: a small tab with the yellow "?" after the styles. One click and
	-- the guide takes you to every quest that's ready, in the quickest order.
	do
		local b = CreateFrame("Button", nil, win)
		b:SetHeight(20)
		b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints()
		b.line = b:CreateTexture(nil, "ARTWORK"); b.line:SetHeight(2)
		b.line:SetPoint("BOTTOMLEFT", 3, 0); b.line:SetPoint("BOTTOMRIGHT", -3, 0)
		b.hl = b:CreateTexture(nil, "HIGHLIGHT"); b.hl:SetAllPoints(); b.hl:SetColorTexture(1, 1, 1, 0.06)
		b.icon = b:CreateTexture(nil, "OVERLAY")
		b.icon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
		b.icon:SetSize(14, 14)
		b.count = b:CreateFontString(nil, "OVERLAY"); b.count:SetFontObject(P.fonts.small or P.fonts.head)
		b:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
			P:TurnInAll()
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			local n = P:ReadyCount()
			if P.route and P.route.mode == "turnins" then
				GameTooltip:SetText("Turn in all", 1, 1, 1)
				GameTooltip:AddLine("Click to stop and go back to your guide", 0.7, 0.75, 0.8, true)
			elseif n > 0 then
				GameTooltip:SetText("Turn in all (" .. n .. ")", 1, 1, 1)
				GameTooltip:AddLine("Every quest that's ready to turn in, in the quickest order from where you are: flights, boats and the tram included. Your guide waits and comes back after.", 0.7, 0.75, 0.8, true)
			else
				GameTooltip:SetText("Turn in all", 1, 1, 1)
				GameTooltip:AddLine("No quests ready to turn in yet", 0.7, 0.75, 0.8, true)
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		win.turnins = b
	end

	-- nothing to follow yet: the next thing worth doing, one click away
	win.actions = {}
	local function act(label, accent, tip, fn)
		local b = P:FlatButton(win, label, accent)
		b.tip = tip
		b:SetScript("OnClick", fn)
		b:Hide()
		win.actions[#win.actions + 1] = b
		return b
	end
	act("Load Fastest XP guide", true, "The best quest for your time, after every hand-in", function() P:PlayZone(nil, "fast") end)
	act("Find something else?", false, "The journal: a zone's story, every quest in it, chains, dungeons and more", function() P:ToggleJournal("home") end)
	win.pct = win:CreateFontString(nil, "OVERLAY")
	win.pct:SetFontObject(P.fonts.head)
	-- progress: a hairline under the header
	win.track = win:CreateTexture(nil, "BORDER")
	win.track:SetPoint("TOPLEFT", 14, -28); win.track:SetPoint("TOPRIGHT", -14, -28); win.track:SetHeight(2)
	win.track:SetColorTexture(1, 1, 1, 0.07)
	win.fill = win:CreateTexture(nil, "ARTWORK")
	win.fill:SetPoint("TOPLEFT", win.track, "TOPLEFT"); win.fill:SetHeight(2)

	-- the step: an icon in a soft ring, what to do, which way
	win.badge = CreateFrame("Frame", nil, win)
	win.badge:SetSize(34, 34); win.badge:SetPoint("TOPLEFT", 12, -40)
	win.badge.ring = win.badge:CreateTexture(nil, "BACKGROUND")
	win.badge.ring:SetTexture(P.MEDIA .. "Dot"); win.badge.ring:SetAllPoints()
	win.icon = win.badge:CreateTexture(nil, "ARTWORK")
	win.icon:SetSize(22, 22); win.icon:SetPoint("CENTER")
	win.model = { Hide = function() end, Show = function() end }     -- the faces live on the quest bar now

	win.step = win:CreateFontString(nil, "OVERLAY")
	win.step:SetFontObject(P.fonts.title)
	win.step:SetPoint("TOPLEFT", win.badge, "TOPRIGHT", 10, -1)
	win.step:SetPoint("RIGHT", -14, 0)
	win.step:SetJustifyH("LEFT"); win.step:SetWordWrap(true); win.step:SetMaxLines(2)
	win.dir = win:CreateFontString(nil, "OVERLAY")
	win.dir:SetFontObject(P.fonts.button)
	win.dir:SetPoint("TOPLEFT", win.step, "BOTTOMLEFT", 0, -4)
	win.dir:SetPoint("RIGHT", -14, 0)
	win.dir:SetJustifyH("LEFT"); win.dir:SetWordWrap(false)
	win.details = win:CreateFontString(nil, "OVERLAY")
	win.details:SetFontObject(P.fonts.head)
	win.details:SetPoint("TOPLEFT", win.dir, "BOTTOMLEFT", 0, -5)
	win.details:SetPoint("RIGHT", -14, 0)
	win.details:SetJustifyH("LEFT"); win.details:SetSpacing(3)

	-- the step's own buttons: it's done (it won't come back), or skip it for now
	win.done = P:FlatButton(win, "Done", true)
	win.done.tip = "Mark this step done: it won't come back for this character (undo it from your notifications)"
	win.done:SetScript("OnClick", function() P:MarkStepDone() end)
	win.skip = P:FlatButton(win, "Skip")
	win.skip.tip = "Skip it: its quest stays out of your guides until your next level. Right-click to mark the quest completed, so it never comes back on this character."
	win.skip:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	win.skip:SetScript("OnClick", function(_, button) if button == "RightButton" then P:NeverStep() else P:SkipStop() end end)

	-- what's next: quiet rows
	win.sep = win:CreateTexture(nil, "ARTWORK")
	win.sep:SetHeight(1); win.sep:SetColorTexture(1, 1, 1, 0.06)
	win.rows = {}
	for i = 1, NEXT_ROWS do
		local r = CreateFrame("Button", nil, win)
		r:SetHeight(18)
		r.dot = r:CreateTexture(nil, "ARTWORK"); r.dot:SetTexture(P.MEDIA .. "Dot"); r.dot:SetSize(6, 6); r.dot:SetPoint("LEFT", 2, 0)
		r.dot:SetVertexColor(0.45, 0.48, 0.53)
		r.then_ = r:CreateFontString(nil, "OVERLAY"); r.then_:SetFontObject(P.fonts.head); r.then_:SetPoint("LEFT", 0, 0)
		r.then_:SetText("THEN")
		r.dot:Hide()
		r.text = r:CreateFontString(nil, "OVERLAY"); r.text:SetFontObject(P.fonts.button); r.text:SetPoint("LEFT", 40, 0)
		r.text:SetPoint("RIGHT", -52, 0); r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false); r.text:SetTextColor(0.72, 0.75, 0.8)
		r.dist = r:CreateFontString(nil, "OVERLAY"); r.dist:SetFontObject(P.fonts.head); r.dist:SetPoint("RIGHT", 0, 0)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.04)
		r:SetScript("OnClick", function(self)
			local route = P.route
			if not route or not self.stop then return end
			for j, st in ipairs(route.stops) do
				if st == self.stop then table.remove(route.stops, j); table.insert(route.stops, 1, st); break end
			end
			P:Send("ROUTE_CHANGED")
		end)
		r:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText("Do this one next", 1, 1, 1)
			GameTooltip:Show()
		end)
		r:SetScript("OnLeave", GameTooltip_Hide)
		win.rows[i] = r
	end
	-- your quests: what the game's quest tracker would show, while it's tucked away
	-- a fold: "QUESTS (5) ▸" opens the list, and remembers
	win.qbtn = CreateFrame("Button", nil, win)
	win.qbtn:SetHeight(18)
	win.qhead = win.qbtn:CreateFontString(nil, "OVERLAY"); win.qhead:SetFontObject(P.fonts.head)
	win.qhead:SetPoint("LEFT", 0, 0)
	win.qbtn.hl = win.qbtn:CreateTexture(nil, "HIGHLIGHT"); win.qbtn.hl:SetAllPoints(); win.qbtn.hl:SetColorTexture(1, 1, 1, 0.04)
	win.qbtn:SetScript("OnClick", function() P.db.guideQuestsOpen = not P.db.guideQuestsOpen; P:UpdateGuide() end)
	win.qbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Your quests", 1, 1, 1)
		GameTooltip:AddLine("Click to " .. (P.db.guideQuestsOpen and "fold the list" or "see them all") .. "; click one to follow it", 0.7, 0.75, 0.8)
		GameTooltip:Show()
	end)
	win.qbtn:SetScript("OnLeave", GameTooltip_Hide)
	win.qsep = win:CreateTexture(nil, "ARTWORK"); win.qsep:SetHeight(1); win.qsep:SetColorTexture(1, 1, 1, 0.06)
	win.qrows = {}
	for i = 1, QUEST_ROWS do
		local r = CreateFrame("Button", nil, win)
		r:SetHeight(17)
		r.prog = r:CreateFontString(nil, "OVERLAY"); r.prog:SetFontObject(P.fonts.head); r.prog:SetPoint("RIGHT", 0, 0)
		r.prog:SetJustifyH("RIGHT"); r.prog:SetWordWrap(false); r.prog:SetWidth(150)
		r.text = r:CreateFontString(nil, "OVERLAY"); r.text:SetFontObject(P.fonts.button); r.text:SetPoint("LEFT", 0, 0)
		r.text:SetPoint("RIGHT", r.prog, "LEFT", -6, 0); r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.04)
		r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		r:SetScript("OnClick", function(self, button)
			if not self.qid then return end
			if button == "RightButton" then
				local qid = self.qid
				local m = MenuUtil or P.MiniMenu
				m.CreateContextMenu(self, function(_, root)
					root:CreateButton("Follow this quest", function() P:FollowQuest(qid) end)
					root:CreateButton("Skip (until my next level)", function()
						P.cdb.skipQ = P.cdb.skipQ or {}; P.cdb.skipQ[qid] = true; P:Send("QUESTS_CHANGED")
					end)
					root:CreateButton("Mark completed (never show it again)", function() P:NeverQuests({ qid }) end)
				end)
			else
				P:FollowQuest(self.qid)
			end
		end)
		r:SetScript("OnEnter", function(self)
			if not self.qid then return end
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			local e = P.log[self.qid]
			GameTooltip:SetText(e and e.title or "", 1, 1, 1)
			for _, o in ipairs(e and e.objectives or EMPTY) do
				if o.text then GameTooltip:AddLine((o.finished and "|cff66bf73" or "|cffd8dde3") .. o.text .. "|r") end
			end
			local q = P.Q[self.qid]
			if q and q[P.K.TEXT] and q[P.K.TEXT] ~= "" then GameTooltip:AddLine(q[P.K.TEXT], 0.7, 0.73, 0.78, true) end
			local where, far = P:QuestWhere(self.qid)
			if where then GameTooltip:AddLine((e and e.complete and "Hand in: " or "Where: ") .. where .. (far and "  (Pathway plans the trip)" or ""), 1, 0.82, 0.3) end
			GameTooltip:AddLine("Click to follow just this quest. Right-click to skip it or mark it completed.", 0.5, 0.55, 0.6, true)
			GameTooltip:Show()
		end)
		r:SetScript("OnLeave", GameTooltip_Hide)
		r:Hide()
		win.qrows[i] = r
	end

	win.hint = win:CreateFontString(nil, "OVERLAY")
	win.hint:SetFontObject(P.fonts.head)
	win.hint:SetPoint("BOTTOMLEFT", 14, 9)
	win.hint:SetPoint("RIGHT", -14, 0); win.hint:SetJustifyH("LEFT"); win.hint:SetWordWrap(false)
	-- hover the bottom line for how this session is going
	local hov = CreateFrame("Frame", nil, win)
	hov:SetPoint("BOTTOMLEFT", 6, 2); hov:SetPoint("BOTTOMRIGHT", -6, 2); hov:SetHeight(20)
	hov:SetScript("OnEnter", function(self) if P.SessionTooltip then P:SessionTooltip(self) end end)
	hov:SetScript("OnLeave", GameTooltip_Hide)

	local function paint()
		win.fill:SetColorTexture(A[1], A[2], A[3], 0.9)
		win.badge.ring:SetVertexColor(A[1] * 0.35, A[2] * 0.35, A[3] * 0.35, 1)
	end
	P:OnPaint(paint); paint()

	local t = 0
	win:SetScript("OnUpdate", function(_, dt)
		t = t + dt
		if t > 0.5 then t = 0; P:UpdateGuideLive() end
	end)
	P.Perf.Hook(win, "Guide window", "OnUpdate")
end

-- with tabs, everything sits a little lower
local function Place(off)
	if win.off == off then return end
	win.off = off
	win.title:ClearAllPoints(); win.title:SetPoint("TOPLEFT", 14, -12 - off); win.title:SetPoint("RIGHT", win.book or win.menu, "LEFT", -6, 0)
	win.close:ClearAllPoints(); win.close:SetPoint("TOPRIGHT", -6, -6 - off)
	win.track:ClearAllPoints(); win.track:SetPoint("TOPLEFT", 14, -28 - off); win.track:SetPoint("TOPRIGHT", -14, -28 - off)
	win.badge:ClearAllPoints(); win.badge:SetPoint("TOPLEFT", 12, -40 - off)
end

local function Label(t)
	local title = (t.route and t.route.title) or t.spec.title or (t.spec.mode == "next" and "Nearest set") or "Guide"
	title = title:gsub("%s+%d+/%d+$", "")
	local short = title:match(":%s*(.+)$") or title
	return short, title
end

-- the style switch sits at the very top (under the tabs, when there are some)
local STYLE_H = 24
local TURNINS_W = 34
local function Styles(y)
	local w = math.floor((W_GUIDE - 16 - TURNINS_W) / 3)
	local active = P:RouteStyle()
	for i, b in ipairs(win.styles) do
		local st = P.STYLES[i]
		b.style = st
		local on = st.key == active
		b:ClearAllPoints(); b:SetPoint("TOPLEFT", 8 + (i - 1) * w, -4 - y); b:SetWidth(w)
		b.text:SetText((on and "|cffffffff" or "|cff8a929b") .. st.label .. "|r")
		b.bg:SetColorTexture(A[1], A[2], A[3], on and 0.16 or 0.03)
		b.line:SetColorTexture(A[1], A[2], A[3], on and 1 or 0)
		b:Show()
	end
	local t = win.turnins
	if t then
		local on = P.route and P.route.mode == "turnins"
		local n = P:ReadyCount()
		t:ClearAllPoints(); t:SetPoint("TOPLEFT", 8 + 3 * w, -4 - y); t:SetWidth(W_GUIDE - 16 - 3 * w)
		t.icon:ClearAllPoints()
		t.count:ClearAllPoints()
		if n > 0 then
			t.icon:SetPoint("CENTER", -5, 1)
			t.count:SetPoint("LEFT", t.icon, "RIGHT", 0, 0)
			t.count:SetText((on and "|cffffffff" or "|cffffd100") .. n .. "|r")
			t.count:Show()
		else
			t.icon:SetPoint("CENTER", 0, 1)
			t.count:Hide()
		end
		t.icon:SetDesaturated(n == 0 and not on)
		t.icon:SetAlpha((n > 0 or on) and 1 or 0.45)
		t.bg:SetColorTexture(A[1], A[2], A[3], on and 0.16 or 0.03)
		t.line:SetColorTexture(1, 0.82, 0, on and 1 or 0)
		t:Show()
	end
	return STYLE_H
end

local function Tabs()
	local list = P.tracks or EMPTY
	if #list < 2 then for _, b in ipairs(win.tabs) do b:Hide() end return 0 end
	local n = math.min(#list, #win.tabs - 1)
	local avail = W_GUIDE - 16 - 22
	local w = math.floor(avail / n)
	local x = 8
	for i = 1, n do
		local t = list[#list - n + i]
		local b = win.tabs[i]
		b.track, b.add = t, nil
		local short, full = Label(t)
		b.full = full
		local on = t == P.track
		b.text:SetText((on and "|cffffffff" or "|cff8a929b") .. short .. "|r")
		b.x:Show()
		b.line:SetColorTexture(A[1], A[2], A[3], on and 1 or 0)
		b:SetWidth(w); b:ClearAllPoints(); b:SetPoint("TOPLEFT", x, -4)
		b:Show()
		x = x + w
	end
	local add = win.tabs[#win.tabs]
	add.add, add.track = true, nil
	add.text:SetText(P.DIM .. "+|r"); add.line:SetColorTexture(0, 0, 0, 0)
	add.x:Hide()
	add:SetWidth(20); add:ClearAllPoints(); add:SetPoint("TOPLEFT", x, -4); add:Show()
	for i = n + 1, #win.tabs - 1 do win.tabs[i]:Hide() end
	return 22
end

-- what to do when nothing is loaded: the closest thing for you, cached briefly
local suggestAt, suggestion = -1e9, nil
function P:Suggest()
	if GetTime() - suggestAt < 3 then return suggestion end
	suggestAt, suggestion = GetTime(), nil
	local list = self:Stops(self.MODES.next)
	local best
	for _, st in ipairs(list) do if not best or st.dist < best.dist then best = st end end
	suggestion = best
	return best
end

-- the guide window is open, tucked into a slim bar, or hidden
function P:GuideState() return (self.db and self.db.guideState) or "open" end
function P:SetGuideState(state)
	self.db.guideState = state
	if state == "hidden" then self:Toast("Guide hidden: the Pathway button on your minimap brings it back") end
	self:UpdateGuide()
	self:TidyTracker()
end

local function Short(d)
	if not d then return "" end
	return d >= 1000 and ("%.1fk"):format(d / 1000) or tostring(floor(d + 0.5))
end

-- the parts that change as you move
local idleT = 0
function P:UpdateGuideLive()
	if not win or not win:IsShown() then return end
	local s = self:Current()
	if not s then return end
	win.dir:SetText(self:Directions(s))
	local inst, px, py = self:PlayerPos()
	for _, r in ipairs(win.rows) do
		if r.stop and inst and r.stop.wx then
			r.dist:SetText(P.DIM .. Short(math.sqrt((r.stop.wx - px) ^ 2 + (r.stop.wy - py) ^ 2)) .. " yd|r")
		end
	end
end

-- no guide loaded: a calm, empty guide with two ways in (and no arrow)
local function Idle()
	win.title:SetText(P.TITLE or "Pathway")
	win.fill:SetWidth(1)
	for _, row in ipairs(win.rows) do row.stop = nil; row:Hide() end
	for _, row in ipairs(win.qrows) do row:Hide() end
	win.qsep:Hide(); win.qbtn:Hide()
	win.sep:Hide(); win.done:Hide(); win.skip:Hide()
	win.step:SetText("No guide loaded")
	win.dir:SetText(P.DIM .. "Pick one and the arrow takes you from there.|r")
	win.details:SetText("")
	win.icon:SetTexture(P.MEDIA .. "Icon")
	win.icon:SetTexCoord(0, 1, 0, 1); win.icon:SetSize(20, 20)
	local stepH = win.step:GetStringHeight() + 4 + 14
	local top = 40 + (win.off or 0) + math.max(34, stepH) + 10
	for _, b in ipairs(win.actions) do
		b.minW = W_GUIDE - 28; b:SetLabel(b.text:GetText())
		b:ClearAllPoints(); b:SetPoint("TOPLEFT", 14, -top)
		b:Show()
		top = top + b:GetHeight() + 6
	end
	win.hint:SetText(P.DIM .. "Or pick Storyline or All quests at the top.|r")
	win:SetHeight(top + 24 + 4)
	win:Show()
end

function P:UpdateGuide()
	if not win then return end
	local s = self:Current()
	local state = self:GuideState()
	if self.UpdatePill then self:UpdatePill() end
	if not S().guideWindow or state ~= "open" or (P:InSetup() and not P.placing) then win:Hide(); return end
	local tabsH = Tabs()
	Place(tabsH + Styles(tabsH))
	if not s then Idle() return end
	for _, b in ipairs(win.actions) do b:Hide() end
	local r = self.route
	win.title:SetText((r.title or "Guide"):upper())

	-- progress through the guide (its quests), else through this set of stops
	local frac
	local storyZone = r.guide and tonumber(r.guide:match("^story:(%d+)"))
	local z = storyZone and P.Cat and P.Cat.zones and P.Cat.zones[storyZone]
	if z then local _, _, f = P.Cat:SetProgress(z.story); frac = f
	elseif r.quests and P.Cat then local _, _, f = P.Cat:SetProgress(r.quests); frac = f
	else frac = r.total > 0 and (r.total - #r.stops) / r.total or 0 end
	win.fill:SetWidth(math.max(1, (W_GUIDE - 28) * frac))

	local kind = self:StopKind(s)
	win.step:SetText((self:StopLabel(s)))
	-- the plan: what to do here, step by step, in plain words
	local keep = self:PlanText(self:StepPlan(s), 4)
	if #keep == 0 then
		-- a leg of a trip: what it's for
		for _, l in ipairs(self:StopDetails(s)) do if #keep < 2 then keep[#keep + 1] = l end end
	end
	-- where exactly: the building, the cave, the landmark next to it
	local where, placeKind = self.Whereabouts and self:Whereabouts(s)
	if where then
		table.insert(keep, 1, "|cffd8dde3" .. where:gsub("^%l", string.upper) .. "|r")
		local hint = self:PlaceHint(placeKind)
		local inst, px, py = self:PlayerPos()
		local near = inst and s.wx and ((s.wx - px) ^ 2 + (s.wy - py) ^ 2) < 200 * 200
		if hint and near then keep[#keep + 1] = P.DIM .. hint .. "|r" end
	end
	-- the step's own tip ("upstairs in the inn"), right under the step
	local tip = self.StepHint and self:StepHint(s)
	if tip then table.insert(keep, 1, "|cff5ad18a" .. tip .. "|r") end
	-- Fastest XP: where the set after this one is
	if self.route and self.route.mode == "fast" and self.FastStatus then
		local left, _, _, nx = self:FastStatus()
		if nx and left and left <= 3 then
			keep[#keep + 1] = P.DIM .. ("Next: %s  ·  %d quests, %s XP"):format(self:MapName(nx.zone), nx.n, P.Short(nx.xp)) .. "|r"
		end
	end
	-- a ghost: the arrow is taking you to your body first
	if self.corpse then table.insert(keep, 1, "|cffff6b6bYou died: the arrow takes you to your corpse first|r") end
	while #keep > 6 do table.remove(keep) end
	win.details:SetText(table.concat(keep, "\n"))
	-- a hearth or teleport leg shows what you use: your hearthstone or the spell
	local legIcon
	if s.trip then
		if s.useItem then legIcon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(s.useItem) or (GetItemIcon and GetItemIcon(s.useItem))
		elseif s.useSpell then legIcon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(s.useSpell) or (GetSpellTexture and GetSpellTexture(s.useSpell))
		end
	end
	win.icon:SetTexture(legIcon or KIND_ICON[kind] or KIND_ICON.objective)
	if legIcon then win.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); win.icon:SetSize(22, 22)
	elseif KIND_FULL[kind] then win.icon:SetTexCoord(0, 1, 0, 1); win.icon:SetSize(20, 20)
	else win.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); win.icon:SetSize(22, 22) end
	if s.quest then
		local q = self.Q[s.quest]
		if q then win.title:SetText((r.title or "Guide"):upper() .. P.DIM .. "  ·  " .. q[K.NAME] .. "|r") end
	end

	-- the step's buttons, right under it
	local stepH = win.step:GetStringHeight() + 4 + 14 + (#keep > 0 and (win.details:GetStringHeight() + 5) or 0)
	local top = 40 + (win.off or 0) + math.max(34, stepH) + 8
	win.done:ClearAllPoints(); win.done:SetPoint("TOPLEFT", 56, -top); win.done:Show()
	win.skip:ClearAllPoints(); win.skip:SetPoint("LEFT", win.done, "RIGHT", 6, 0); win.skip:Show()
	top = top + 30

	-- then: just the one after this (click it to do it first)
	win.sep:ClearAllPoints()
	win.sep:SetPoint("TOPLEFT", 14, -top + 4); win.sep:SetPoint("TOPRIGHT", -14, -top + 4)
	win.sep:SetShown(#r.stops > 1)
	local n = 0
	for i, row in ipairs(win.rows) do
		local st = r.stops[i + 1]
		if st then
			n = n + 1
			row.stop = st
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 14, -top - 2 - (i - 1) * 18)
			row:SetPoint("RIGHT", -14, 0)
			row.then_:SetText(P.DIM .. "THEN|r")
			row.text:SetText((self:StopLabel(st)))
			row:Show()
		else
			row.stop = nil
			row:Hide()
		end
	end
	local hearth = self.HearthHint and self:HearthHint(s)
	local pace = self.PaceLine and self:PaceLine()
	local fmTip = self.FlightMasterTip and self:FlightMasterTip(s)
	if fmTip then win.hint:SetText("|cffffd27a" .. fmTip .. "|r")
	elseif hearth then win.hint:SetText("|cffffd27a" .. hearth.text .. "|r")
	elseif pace then win.hint:SetText(pace)
	else win.hint:SetText(P.DIM .. math.floor(frac * 100 + 0.5) .. "% of this guide done|r") end

	-- your quests: folded into one line until you open it
	local qy = top + n * 18 + (n > 0 and 8 or 0)
	local shownQ = 0
	local list, cur = self:QuestsByRelevance(s)
	local open = P.db.guideQuestsOpen
	if #list > 0 then
		win.qsep:ClearAllPoints(); win.qsep:SetPoint("TOPLEFT", 14, -qy); win.qsep:SetPoint("TOPRIGHT", -14, -qy); win.qsep:Show()
		win.qbtn:ClearAllPoints(); win.qbtn:SetPoint("TOPLEFT", 14, -qy - 4); win.qbtn:SetPoint("RIGHT", -14, 0)
		win.qhead:SetText(("%s  QUESTS  %s%d%s|r"):format(open and "|TInterface\\Buttons\\UI-MinusButton-Up:14:14|t" or "|TInterface\\Buttons\\UI-PlusButton-Up:14:14|t", P.DIM, #list,
			(open and #list > QUEST_ROWS) and ("  ·  the " .. QUEST_ROWS .. " that matter most now") or ""))
		win.qbtn:Show()
		qy = qy + 26
	else
		win.qsep:Hide(); win.qbtn:Hide()
	end
	for i, row in ipairs(win.qrows) do
		local it = open and list[i]
		if it then
			local e = it.e
			local prog
			if e.complete then prog = "|cff66bf73ready|r"
			else
				local have, need = 0, 0
				for _, o in ipairs(e.objectives or EMPTY) do
					local a, b = (o.text or ""):match("(%d+)%s*/%s*(%d+)")
					if a then have, need = have + tonumber(a), need + tonumber(b)
					elseif o.finished then have, need = have + 1, need + 1 else need = need + 1 end
				end
				prog = need > 0 and (P.DIM .. have .. "/" .. need .. "|r") or ""
			end
			row.qid = it.qid
			row.text:SetText((it.qid == cur and "|c" .. P.ACCENT_HEX or "|cffd8dde3") .. (e.title or "?") .. "|r")
			local where = it.where
			row.prog:SetText(prog .. (where and ((prog ~= "" and (P.DIM .. "  ·  |r") or "") .. P.DIM .. where .. "|r") or ""))
			row:ClearAllPoints(); row:SetPoint("TOPLEFT", 22, -qy - (i - 1) * 17); row:SetPoint("RIGHT", -14, 0)
			row:Show()
			shownQ = shownQ + 1
		else
			row.qid = nil; row:Hide()
		end
	end
	win:SetHeight(qy + shownQ * 17 + (shownQ > 0 and 6 or 0) + 24)
	win:Show()
	self:UpdateGuideLive()
	if P.db.setupDone and self.Tip then
		self:Tip("guide", win, "Your guide", "What to do now, which way, and what comes next. Click a step below to do it first.\n\nThe × tucks it into a slim bar. The Pathway button on your minimap brings it back.")
		if win.tabs[1]:IsShown() then
			self:Tip("tabs", win.tabs[1], "Tabs", "Every guide you follow gets a tab. Click one to switch, the x closes it, + to add one from the journal.", "TOP")
		end
	end
end

function P:ToggleGuide()
	if not win then return end
	self:SetGuideState(self:GuideState() == "open" and "mini" or "open")
end

---------------------------------------------------------------------------
-- The slim bar: the guide tucked away, still saying what's next
---------------------------------------------------------------------------
local pill
local function BuildPill()
	pill = CreateFrame("Button", "PathwayGuidePill", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	P.Flat(pill, P.colors.BG, nil, true)
	pill:SetSize(W_GUIDE, 26)
	pill:SetPoint("TOPRIGHT", win, "TOPRIGHT")
	pill:SetFrameStrata("MEDIUM")
	pill:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	-- dragging the slim bar moves the guide it belongs to
	pill:RegisterForDrag("LeftButton")
	pill:SetScript("OnDragStart", function() if P:CanDrag() then win:StartMoving() end end)
	pill:SetScript("OnDragStop", function() win:StopMovingOrSizing(); SavePos(win) end)
	pill.icon = pill:CreateTexture(nil, "ARTWORK"); pill.icon:SetSize(16, 16); pill.icon:SetPoint("LEFT", 8, 0)
	pill.icon:SetTexture(P.MEDIA .. "Icon")
	pill.text = pill:CreateFontString(nil, "OVERLAY"); pill.text:SetFontObject(P.fonts.button)
	pill.text:SetPoint("LEFT", pill.icon, "RIGHT", 7, 0); pill.text:SetPoint("RIGHT", -52, 0)
	pill.text:SetJustifyH("LEFT"); pill.text:SetWordWrap(false)
	pill.dist = pill:CreateFontString(nil, "OVERLAY"); pill.dist:SetFontObject(P.fonts.head); pill.dist:SetPoint("RIGHT", -24, 0)
	local x = P:CloseButton(pill, function() P:SetGuideState("hidden") end)
	x:SetPoint("RIGHT", -4, 0)
	x.tip = "Hide it completely (the Pathway button on your minimap brings it back)"
	pill:SetScript("OnClick", function(_, button)
		if button == "RightButton" and not P:Current() then P:StartRoute("next") return end
		P:SetGuideState("open")
	end)
	pill:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Show the guide", 1, 1, 1)
		if not P:Current() then GameTooltip:AddLine("Right-click: go to the closest quests", 0.7, 0.75, 0.8) end
		GameTooltip:Show()
	end)
	pill:SetScript("OnLeave", GameTooltip_Hide)
	local t = 0
	pill:SetScript("OnUpdate", function(_, dt)
		t = t + dt
		if t < 0.5 then return end
		t = 0
		local s = P:Current()
		local inst, px, py = P:PlayerPos()
		if s and inst and s.wx then pill.dist:SetText(P.DIM .. Short(math.sqrt((s.wx - px) ^ 2 + (s.wy - py) ^ 2)) .. " yd|r") else pill.dist:SetText("") end
	end)
	P.Perf.Hook(pill, "Guide window", "OnUpdate")
end

function P:UpdatePill()
	if not win then return end
	local show = S().guideWindow and self:GuideState() == "mini"
	if not show then if pill then pill:Hide() end return end
	if not pill then BuildPill() end
	local s = self:Current()
	if s then
		pill.text:SetText((self:StopLabel(s)))
	else
		pill.text:SetText(P.DIM .. "Pathway: no guide loaded, open to pick one|r")
	end
	pill:Show()
end

---------------------------------------------------------------------------
-- The quest bar: a box for each thing this step needs you to target, showing
-- its face, and a box for each quest item in your bags you'll use on it.
-- Secure buttons: they can only change outside combat.
---------------------------------------------------------------------------
local MAX_T, MAX_I, BOX = 4, 3, 40
local qbar, tBtns, iBtns = nil, {}, {}
local pendingBar = false

local function ItemSpell(id)
	if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(id) end
	return GetItemSpell and GetItemSpell(id)
end
local function Count(id) return (C_Item and C_Item.GetItemCount or GetItemCount)(id) or 0 end
local function Icon(id) return (C_Item and C_Item.GetItemIconByID or GetItemIcon)(id) end

-- the stops that belong with this one: the same quest, or right next to it
local function Together(self, s)
	local out = { s }
	local r = self.route
	for i = 2, math.min(#r.stops, 6) do
		local o = r.stops[i]
		if o.quest and (o.quest == s.quest or (s.wx and o.wx and (o.wx - s.wx) ^ 2 + (o.wy - s.wy) ^ 2 < 100 * 100)) then
			out[#out + 1] = o
		end
	end
	return out
end

-- every creature to target for this step, the nearest first: { {id, name}, ... }
function P:StopTargets(s)
	local out, seen = {}, {}
	local function add(id)
		local name = id and self:EntityName("N", id)
		if name and name ~= "" and not seen[name] and #out < MAX_T then
			seen[name] = true
			out[#out + 1] = { id = id, name = name }
		end
	end
	if not s then return out end
	if s.travel then add(s.ents[1][2]) return out end
	for _, st in ipairs(Together(self, s)) do
		if st.at and st.at[1] == "N" then add(st.at[2]) end
		for _, e in ipairs(st.ents or EMPTY) do if e[1] == "N" then add(e[2]) end end
	end
	return out
end

-- every usable quest item in your bags for this step's quests
function P:StopItems(s)
	local out, seen = {}, {}
	if not s then return out end
	local boost = self.BoostItem and self:BoostItem()        -- a Sleeping Bag or XP food you said yes to
	if boost then out[1] = boost; seen[boost] = true end
	if s.useSpell then out[#out + 1] = { spell = s.useSpell } end
	if s.useItem then out[#out + 1] = s.useItem; seen[s.useItem] = true end
	local hearth = not s.trip and self.HearthHint and self:HearthHint(s)
	if hearth and not seen[hearth.item] then out[#out + 1] = hearth.item; seen[hearth.item] = true end
	local quests = {}
	for _, st in ipairs(Together(self, s)) do if st.quest then quests[#quests + 1] = st.quest end end
	for _, list in ipairs({ s.pick or EMPTY, s.turn or EMPTY }) do
		for _, qid in ipairs(list) do if self.log[qid] then quests[#quests + 1] = qid end end
	end
	for _, qid in ipairs(quests) do
		local q = self.Q[qid]
		for _, l in ipairs({ q and q[K.USE] or EMPTY, q and q[K.OI] or EMPTY }) do
			for _, id in ipairs(l) do
				if not seen[id] and #out < MAX_I and Count(id) > 0 and ItemSpell(id) then
					seen[id] = true
					out[#out + 1] = id
				end
			end
		end
	end
	return out
end
function P:StopItem(s) return self:StopItems(s)[1] end

local function BarButton(name)
	local b = CreateFrame("Button", name, qbar, "SecureActionButtonTemplate,BackdropTemplate")
	b:SetSize(BOX, BOX)
	b:RegisterForClicks("AnyUp", "AnyDown")
	P.Flat(b, P.colors.PANEL, P.colors.EDGE)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.label = b:CreateFontString(nil, "OVERLAY")
	b.label:SetFontObject(P.fonts.small)
	b.label:SetPoint("TOP", b, "BOTTOM", 0, -2)
	b.label:SetWidth(BOX + 14); b.label:SetWordWrap(false)
	b.key = b:CreateFontString(nil, "OVERLAY", nil, 7)
	b.key:SetFontObject(P.fonts.small)
	b.key:SetPoint("TOPRIGHT", -2, -2)
	b.count = b:CreateFontString(nil, "OVERLAY", nil, 7)
	b.count:SetFontObject(P.fonts.small)
	b.count:SetPoint("BOTTOMRIGHT", -2, 2)
	b:HookScript("OnEnter", function(self)
		self:SetBackdropBorderColor(A[1], A[2], A[3], 1)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		if self.itemID then GameTooltip:SetItemByID(self.itemID) else GameTooltip:SetText(self.tip or "", 1, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	b:HookScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(self.on and A or P.colors.EDGE)); GameTooltip:Hide() end)
	b:RegisterForDrag("LeftButton")
	b:SetScript("OnDragStart", function() if (IsShiftKeyDown() or P.placing) and not InCombatLockdown() then qbar:StartMoving() end end)
	b:SetScript("OnDragStop", function() qbar:StopMovingOrSizing(); SavePos(qbar) end)
	return b
end

local function TargetButton(i)
	local name = i == 1 and "PathwayTargetButton" or ("PathwayTargetButton" .. i)
	local b = BarButton(name)
	b:SetAttribute("type", "macro")
	b.bind = "CLICK " .. name .. ":LeftButton"
	-- the face of who you're after; a crosshair behind it until the model loads
	b.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
	b.icon:SetDesaturated(true); b.icon:SetAlpha(0.35)
	b.model = CreateFrame("PlayerModel", nil, b)
	b.model:SetPoint("TOPLEFT", 2, -2); b.model:SetPoint("BOTTOMRIGHT", -2, 2)
	b.model:SetFrameLevel(b:GetFrameLevel() + 1)
	b.model:EnableMouse(false)
	b.badge = b:CreateTexture(nil, "OVERLAY", nil, 6)
	b.badge:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
	b.badge:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.badge:SetSize(13, 13); b.badge:SetPoint("BOTTOMLEFT", 2, 2)
	b.key:SetParent(b.model); b.badge:SetParent(b.model)
	-- the raid marker this box puts on what it finds
	b.mark = b:CreateTexture(nil, "OVERLAY", nil, 7)
	b.mark:SetSize(14, 14); b.mark:SetPoint("TOPLEFT", -4, 4)
	b.mark:SetParent(b.model)
	b.markTop = b:CreateTexture(nil, "OVERLAY", nil, 7)       -- the same, when there's no model (plain buttons)
	b.markTop:SetSize(14, 14); b.markTop:SetPoint("TOPLEFT", -4, 4)
	return b
end

local function ItemButton(i)
	local name = i == 1 and "PathwayItemButton" or ("PathwayItemButton" .. i)
	local b = BarButton(name)
	b:SetAttribute("type", "item")
	b.bind = "CLICK " .. name .. ":LeftButton"
	b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	b.cd:SetAllPoints(b.icon)
	return b
end

local stepBtn, magic
local PAD, CAP, LBL = 8, 14, 14           -- padding, caption height, name under each box

-- the magic button: the step key as a button you can see and move
local function BuildMagic()
	magic = CreateFrame("Button", "PathwayMagicButton", UIParent, "SecureActionButtonTemplate")
	if P.ApplySizes then P:ApplySizes() end
	magic:SetSize(60, 60)
	magic:SetAttribute("type", "macro")
	magic:RegisterForClicks("AnyUp", "AnyDown")
	magic:SetMovable(true); magic:SetClampedToScreen(true)
	-- just under your character, above the action bars, until you move it
	P:PlaceAt(magic)
	magic.bg = magic:CreateTexture(nil, "BACKGROUND"); magic.bg:SetTexture(P.MEDIA .. "Dot"); magic.bg:SetAllPoints()
	magic.bg:SetVertexColor(0.04, 0.05, 0.06, 0.92)
	magic.icon = magic:CreateTexture(nil, "ARTWORK"); magic.icon:SetSize(42, 42); magic.icon:SetPoint("CENTER")
	local mask = magic:CreateMaskTexture()
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(magic.icon); magic.icon:AddMaskTexture(mask)
	magic.ring = magic:CreateTexture(nil, "OVERLAY"); magic.ring:SetTexture(P.MEDIA .. "Ring"); magic.ring:SetAllPoints()
	magic.glow = magic:CreateTexture(nil, "BACKGROUND", nil, -1); magic.glow:SetTexture(P.MEDIA .. "Dot")
	magic.glow:SetPoint("CENTER"); magic.glow:SetSize(84, 84); magic.glow:SetBlendMode("ADD")
	magic.pulse = magic:CreateAnimationGroup(); magic.pulse:SetLooping("BOUNCE")
	local a = magic.pulse:CreateAnimation("Alpha"); a:SetFromAlpha(0.15); a:SetToAlpha(0.55); a:SetDuration(1.1)
	a:SetTarget(magic.glow)
	magic.text = magic:CreateFontString(nil, "OVERLAY"); magic.text:SetFontObject(P.fonts.button)
	magic.text:SetPoint("TOP", magic, "BOTTOM", 0, -2)
	magic.key = magic:CreateFontString(nil, "OVERLAY"); magic.key:SetFontObject(P.fonts.small); magic.key:SetPoint("TOPRIGHT", -4, -4)
	magic:SetHighlightTexture(P.MEDIA .. "Dot", "ADD")
	magic:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
	magic:RegisterForDrag("LeftButton")
	magic:SetScript("OnDragStart", function(self) if (IsShiftKeyDown() or P.placing) and not InCombatLockdown() then self:StartMoving() end end)
	magic:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos(self) end)
	magic:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("Magic button", 1, 1, 1)
		for _, l in ipairs(self.plan or EMPTY) do GameTooltip:AddLine(l, 0.85, 0.88, 0.92) end
		GameTooltip:AddLine("Shift-drag to move  ·  bind \"Do this step\" for a key", 0.5, 0.55, 0.6)
		GameTooltip:Show()
	end)
	magic:HookScript("OnLeave", GameTooltip_Hide)
	-- a step with nothing to target or use (walk somewhere, explore): the button opens the guide
	magic:SetScript("PostClick", function(self, _, down)
		if self.idle and not down then P:SetGuideState("open") end
	end)
	magic:Hide()
end

-- what the magic button shows: the thing it'll do on the next click
function P:UpdateMagicFace()
	if not (magic and magic:IsShown() and magic.targets) then return end
	local t, item = magic.targets[1], magic.items[1]
	local name = UnitExists("target") and UnitName("target")
	if name and issecretvalue and issecretvalue(name) then name = nil end
	local targeted = t and name == t.name and not UnitIsDead("target")
	if t and not targeted then
		magic.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
		magic.text:SetText(P.DIM .. "Target|r")
	elseif type(item) == "table" then
		magic.icon:SetTexture(C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(item.spell) or (GetSpellTexture and GetSpellTexture(item.spell)))
		magic.text:SetText(P.DIM .. "Cast|r")
	elseif item then
		magic.icon:SetTexture(Icon(item))
		magic.text:SetText(P.DIM .. "Use|r")
	elseif t then
		magic.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")
		magic.text:SetText(P.DIM .. "Targeted|r")
	else
		magic.icon:SetTexture(P.MEDIA .. "Icon")
		magic.text:SetText(P.DIM .. "Guide|r")
	end
	magic.ring:SetVertexColor(A[1], A[2], A[3], 1)
	magic.glow:SetVertexColor(A[1], A[2], A[3], 1)
end

local function BuildBar()
	qbar = CreateFrame("Frame", "PathwayQuestBar", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	P.Flat(qbar, P.colors.BG, nil, true)
	qbar:SetSize(BOX + PAD * 2, BOX + PAD * 2 + CAP + LBL)
	qbar.capT = qbar:CreateFontString(nil, "OVERLAY"); qbar.capT:SetFontObject(P.fonts.small)
	qbar.capU = qbar:CreateFontString(nil, "OVERLAY"); qbar.capU:SetFontObject(P.fonts.small)
	qbar.div = qbar:CreateTexture(nil, "ARTWORK"); qbar.div:SetColorTexture(1, 1, 1, 0.08); qbar.div:SetWidth(1)
	qbar:SetMovable(true); qbar:SetClampedToScreen(true); qbar:EnableMouse(false)
	P:PlaceAt(qbar)
	for i = 1, MAX_T do tBtns[i] = TargetButton(i) end
	for i = 1, MAX_I do iBtns[i] = ItemButton(i) end
	-- a grip on the left to drag the bar (hidden once you lock it)
	local grip = CreateFrame("Button", nil, qbar)
	grip:SetSize(10, BOX)
	grip:SetPoint("RIGHT", qbar, "LEFT", -2, 0)
	for row = 0, 3 do
		for col = 0, 1 do
			local d = grip:CreateTexture(nil, "ARTWORK")
			d:SetColorTexture(1, 1, 1, 0.35); d:SetSize(2, 2)
			d:SetPoint("TOPLEFT", 2 + col * 4, -9 - row * 6)
		end
	end
	grip:RegisterForDrag("LeftButton")
	grip:SetScript("OnDragStart", function() if P:CanDrag(true) then qbar:StartMoving() end end)
	grip:SetScript("OnDragStop", function() qbar:StopMovingOrSizing(); SavePos(qbar) end)
	grip:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Quest bar", 1, 1, 1)
		GameTooltip:AddLine("Drag to move. Lock it in Settings > Quest help.", 0.7, 0.75, 0.8)
		GameTooltip:Show()
	end)
	grip:SetScript("OnLeave", GameTooltip_Hide)
	qbar.grip = grip
	-- the step key: one press targets what the step needs, the next uses its item
	stepBtn = CreateFrame("Button", "PathwayStepButton", UIParent, "SecureActionButtonTemplate")
	stepBtn:SetAttribute("type", "macro")
	stepBtn.bind = "CLICK PathwayStepButton:LeftButton"
	stepBtn:RegisterForClicks("AnyUp", "AnyDown")
	stepBtn:SetSize(1, 1); stepBtn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
	qbar:Hide()
	BuildMagic()
end

-- the objective count for a creature this step needs ("3/8"), if there is one
local function CountFor(self, s, id)
	for _, st in ipairs(Together(self, s)) do
		if st.quest then
			for _, e in ipairs(st.ents or EMPTY) do
				if e[1] == "N" and e[2] == id then
					local le = self.log[st.quest]
					local o = le and le.objectives and le.objectives[st.index]
					local have, need
					if o and o.text then have, need = o.text:match("(%d+)%s*/%s*(%d+)") end
					if have then return have .. "/" .. need end
				end
			end
		end
	end
end

local function Short(name)
	if #name <= 12 then return name end
	local first = name:match("^(%S+)")
	return (first and #first <= 12) and first or (name:sub(1, 11) .. ".")
end

local function KeyText(b)
	if not (b and b.bind) then return "" end
	local key = GetBindingKey and GetBindingKey(b.bind)
	if not key then return "" end
	key = key:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A"):gsub("NUMPAD", "N")
	return "|cffd8dde3" .. key .. "|r"
end

function P:UpdateQuestBar()
	if not qbar then return end
	if InCombatLockdown() then pendingBar = true; return end
	if P.placing then return end           -- being placed: it stays shown until setup is done
	pendingBar = false
	local s = self:Current()
	if not s or not P:RouteShown() or not (S().questBar or S().magicButton or S().stepKey) then
		qbar:Hide()
		if magic then magic:Hide() end
		return
	end

	local targets, items = self:StopTargets(s), self:StopItems(s)
	local style = S().barStyle or "animated"
	P:ApplySizes()
	qbar.grip:SetShown(not S().barLocked)
	-- the step key: target (if it isn't already), then use the item on it
	local lines = {}
	if targets[1] then
		lines[#lines + 1] = "/cleartarget [dead]"
		lines[#lines + 1] = "/targetexact [noexists] " .. targets[1].name
	end
	if type(items[1]) == "table" then lines[#lines + 1] = "/cast " .. ((C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(items[1].spell)) or (GetSpellInfo and GetSpellInfo(items[1].spell)) or "")
	elseif items[1] then lines[#lines + 1] = "/use item:" .. items[1] end
	stepBtn:SetAttribute("macrotext", S().stepKey and table.concat(lines, "\n") or "")
	if magic then
		-- there when the step has something to target or use; out of the way otherwise
		local on = S().magicButton and #lines > 0 and true or false
		magic:SetAttribute("macrotext", table.concat(lines, "\n"))
		magic.idle = #lines == 0

		magic.targets, magic.items = targets, items
		local plan = {}
		if #lines == 0 then plan[1] = "Nothing to target here: follow the arrow. Click to open the guide." end
		if targets[1] then plan[#plan + 1] = "1. Target |cffffffff" .. targets[1].name .. "|r" end
		if type(items[1]) == "table" then plan[#plan + 1] = (#plan + 1) .. ". Cast it"
		elseif items[1] then plan[#plan + 1] = (#plan + 1) .. ". Use |cffffffff" .. ((C_Item and C_Item.GetItemNameByID or GetItemInfo)(items[1]) or "the item") .. "|r" end
		magic.plan = plan
		magic.key:SetText(KeyText(stepBtn))
		magic:SetShown(on)
		if on then
			if not magic.pulse:IsPlaying() then magic.pulse:Play() end
			self:UpdateMagicFace()
			if P.db.setupDone and self.Tip then
				self:Tip("magic", magic, "Your magic button", "Click it to target what this step needs. Click again to use the quest item on it.\n\nShift-drag to move it. Bind \"Do this step\" in Keybindings to do the same with a key.", "TOP")
			end
		end
	end
	local x, shown = 0, 0
	for i, b in ipairs(tBtns) do
		local t = targets[i]
		if t then
			b:SetAttribute("macrotext", "/cleartarget\n/targetexact " .. t.name)
			if b.targetName ~= t.name then
				b.targetName = t.name
				-- a marker of its own: random, but never one another box is using
				local used, free = {}, {}
				for _, o in ipairs(tBtns) do if o ~= b and o:IsShown() and o.markIndex then used[o.markIndex] = true end end
				for m = 1, 8 do if not used[m] then free[#free + 1] = m end end
				b.markIndex = free[math.random(#free)]
			end
			local markTex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. b.markIndex
			local marks = S().targetMarks
			b.mark:SetTexture(markTex); b.markTop:SetTexture(markTex)
			b.mark:SetShown(marks); b.markTop:SetShown(marks and style == "plain")
			b.tip = "Target |cffffffff" .. t.name .. "|r\n" .. P.DIM .. "Works when it's in range. Bind keys in Options > Keybindings > AddOns.|r"
			b.label:SetText(P.DIM .. Short(t.name) .. "|r")
			b.key:SetText(KeyText(b))
			if style == "plain" then
				b.model:Hide(); b.badge:Hide()
				b.icon:SetDesaturated(false); b.icon:SetAlpha(1)
				b.npc = nil
			else
				b.model:Show(); b.badge:Show()
				b.icon:SetDesaturated(true); b.icon:SetAlpha(0.35)
				if b.npc ~= t.id or b.style ~= style then
					b.npc, b.style = t.id, style
					b.model:ClearModel()
					b.model:SetCreature(t.id)
					if b.model.SetPortraitZoom then b.model:SetPortraitZoom(0.9) end
					if b.model.SetCamDistanceScale then b.model:SetCamDistanceScale(1.1) end
					if style == "still" then
						-- hold the first frame: a portrait, not an animation
						local m = b.model
						C_Timer.After(0.1, function() if m.FreezeAnimation then m:FreezeAnimation(0, 0, 0) elseif m.SetAnimation then m:SetAnimation(0) end end)
					end
				end
			end
			local c = CountFor(self, s, t.id)
			b.count:SetText(c and ("|cffffffff" .. c .. "|r") or "")
			b:ClearAllPoints(); b:SetPoint("TOPLEFT", qbar, "TOPLEFT", PAD + x, -(PAD + CAP))
			x = x + BOX + 10
			b:Show(); shown = shown + 1
		else
			b.npc = nil
			b:Hide()
		end
	end
	local nT = shown
	qbar.capT:ClearAllPoints(); qbar.capT:SetPoint("TOPLEFT", PAD, -PAD + 1)
	qbar.capT:SetText(nT > 0 and (P.DIM .. "TARGET|r") or "")
	local uStart = x
	if shown > 0 and #items > 0 then
		qbar.div:ClearAllPoints()
		qbar.div:SetPoint("TOPLEFT", qbar, "TOPLEFT", PAD + x, -PAD - 2); qbar.div:SetPoint("BOTTOMLEFT", qbar, "BOTTOMLEFT", PAD + x, PAD)
		qbar.div:Show()
		x = x + 10; uStart = x
	else
		qbar.div:Hide()
	end
	for i, b in ipairs(iBtns) do
		local id = items[i]
		if type(id) == "table" then
			-- a spell this step casts (a teleport, Astral Recall)
			local sp = id.spell
			b:SetAttribute("type", "spell"); b:SetAttribute("spell", sp)
			b.itemID = nil
			local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(sp) or (GetSpellTexture and GetSpellTexture(sp))
			b.icon:SetTexture(tex)
			b.count:SetText("")
			b.tip = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(sp)) or (GetSpellInfo and GetSpellInfo(sp)) or ""
			b.label:SetText("|cffffd27aCast|r")
			b.key:SetText(KeyText(b))
			b:ClearAllPoints(); b:SetPoint("TOPLEFT", qbar, "TOPLEFT", PAD + x, -(PAD + CAP))
			x = x + BOX + 10
			b:Show(); shown = shown + 1
		elseif id then
			b:SetAttribute("type", "item")
			b:SetAttribute("item", "item:" .. id)
			b.itemID = id
			b.icon:SetTexture(Icon(id))
			local n = Count(id)
			b.count:SetText(n > 1 and n or "")
			local name = (C_Item and C_Item.GetItemNameByID or GetItemInfo)(id)
			local hearth = self.HearthHint and self:HearthHint(s)
			if hearth and hearth.item == id then
				b.label:SetText("|cffffd27aHearth|r")
				b.tip = nil
			else
				b.label:SetText(P.DIM .. (name and Short(name) or "Use") .. "|r")
			end
			b.key:SetText(KeyText(b))
			b:ClearAllPoints(); b:SetPoint("TOPLEFT", qbar, "TOPLEFT", PAD + x, -(PAD + CAP))
			x = x + BOX + 10
			b:Show(); shown = shown + 1
		else
			b.itemID = nil
			b:Hide()
		end
	end
	qbar.capU:ClearAllPoints(); qbar.capU:SetPoint("TOPLEFT", PAD + uStart, -PAD + 1)
	qbar.capU:SetText(shown > nT and (P.DIM .. "USE|r") or "")
	qbar:SetSize(math.max(BOX, x - 10) + PAD * 2, BOX + PAD * 2 + CAP + LBL)
	qbar:SetShown(shown > 0 and S().questBar)
	self:MarkTargeted()
end

-- what a target box finds gets its raid marker, so you can spot it in a crowd
local function Secret(v) return issecretvalue and issecretvalue(v) end
function P:MarkFound()
	if not (P.db and S().targetMarks) or not UnitExists("target") then return end
	if UnitIsPlayer("target") or UnitIsDead("target") then return end
	local name = UnitName("target")
	if not name or Secret(name) then return end
	local cur = GetRaidTargetIndex("target")
	if Secret(cur) or cur then return end
	-- the game keeps real raid marks to itself, so we draw the icon on its nameplate
	P.plateIcons = P.plateIcons or {}
	for _, b in ipairs(tBtns) do
		if b:IsShown() and b.targetName == name and b.markIndex then
			P.plateIcons[name] = b.markIndex
			if P.RefreshPlates then P:RefreshPlates() end
			return
		end
	end
end

-- the box of whoever you have targeted lights up
function P:MarkTargeted()
	local name = UnitExists("target") and UnitName("target")
	if Secret(name) then name = nil end
	for _, b in ipairs(tBtns) do
		local on = b:IsShown() and name ~= nil and b.targetName == name
		b.on = on
		b:SetBackdropBorderColor(unpack(on and A or P.colors.EDGE))
	end
end

local function CooldownTick()
	local getCd = C_Container and C_Container.GetItemCooldown or GetItemCooldown
	for _, b in ipairs(iBtns) do
		if b:IsShown() and b.itemID then
			local start, dur = getCd(b.itemID)
			if start and dur and dur > 0 then b.cd:SetCooldown(start, dur) end
		end
	end
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
P:Listen("READY", function()
	Build()
	BuildBar()
end)

-- Blizzard's quest tracker steps aside while the guide shows your quests.
-- It's tucked into a hidden frame (one widget call): Pathway never runs the
-- tracker's own code, so the game's frames stay clean (no taint).
local tucked, home = false, nil
local hider = CreateFrame("Frame"); hider:Hide()
local function TrackerFrame() return _G.ObjectiveTrackerFrame end
function P:TidyTracker()
	if not P.db then return end
	local want = S().tidyTracker and S().guideWindow and P:GuideState() == "open" and P:Current() ~= nil
	local f = TrackerFrame()
	if not f or (f.IsProtected and f:IsProtected() and InCombatLockdown()) then return end
	if want and not tucked then
		home = f:GetParent() or UIParent
		f:SetParent(hider)
		tucked = true
	elseif not want and tucked then
		f:SetParent(home or UIParent)
		tucked = false
	end
end

local function Refresh()
	P:UpdateGuide()
	P:UpdateQuestBar()
	P:TidyTracker()
end
P:Listen("ROUTE_CHANGED", function() P.plateIcons = {}; if win then Refresh() end end)
P:Listen("QUESTS_CHANGED", function() P:Debounce("guide", 0.2, Refresh) end)
P:Listen("QUEST_PROGRESS", function() P:Debounce("guide", 0.2, Refresh) end)
P:Listen("TARGET_CHANGED", function() P:Debounce("guide", 0.2, Refresh) end)
P:Listen("SETTINGS_CHANGED", Refresh)
P:On("BAG_UPDATE_DELAYED", function() if P.db then P:Debounce("questbar", 0.3, function() P:UpdateQuestBar() end) end end)
P:On("BAG_UPDATE_COOLDOWN", CooldownTick)
P:On("UPDATE_BINDINGS", function() if P.db then Refresh() end end)
P:On("PLAYER_REGEN_ENABLED", function() if pendingBar then P:UpdateQuestBar() end; P:TidyTracker() end)
P:On("PLAYER_TARGET_CHANGED", function() if P.db then P:MarkTargeted(); P:MarkFound(); P:UpdateMagicFace() end end)
end part() end
-- ==================== Highlight.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Highlights
     Makes quest things easy to spot:
       · tooltips on mobs, NPCs and objects say what they're for
         ("Kobold Vermin slain: 3/10 · Kobold Camp Cleanup")
       · a marker above the nameplate of every mob your quests need,
         a bigger one for the step you're on
       · optional: quest mobs get a raid marker when you mouse over them ]]

local ADDON, P = __addon, __ns
local A, K = P.ACCENT, P.K
local ipairs, pairs, wipe = ipairs, pairs, wipe

local function S() return P.db.settings end

---------------------------------------------------------------------------
-- What's wanted, by name
---------------------------------------------------------------------------
local wanted = {}       -- [name] = { "line", ... }
local current = {}      -- [name] = true for the step you're on

local function add(name, line)
	if not name or name == "" then return end
	local l = wanted[name]
	if not l then l = {}; wanted[name] = l end
	for _, x in ipairs(l) do if x == line then return end end
	l[#l + 1] = line
end

local function Rebuild()
	wipe(wanted)
	if not P.db then return end
	if not (S().plateMarks or S().tipLines) then return end       -- both off: no list to keep
	for qid, e in pairs(P.log) do
		local q = P.Q[qid]
		if q then
			local qname = q[K.NAME]
			if e.complete then
				for _, id in ipairs(q[K.EN] or {}) do add(P:EntityName("N", id), "|cff7cf29cTurn in|r " .. qname) end
				for _, id in ipairs(q[K.EO] or {}) do add(P:EntityName("O", id), "|cff7cf29cTurn in|r " .. qname) end
			else
				for _, t in ipairs(P:ObjectiveTargets(qid)) do
					for _, ent in ipairs(t.ents or {}) do
						add(P:EntityName(ent[1], ent[2]), (t.text or "Objective") .. P.DIM .. "  ·  " .. qname .. "|r")
					end
				end
			end
		end
	end
	P:RebuildCurrent()
end

function P:RebuildCurrent()
	wipe(current)
	local s = self:Current()
	if not s then return end
	for _, ent in ipairs(s.ents or {}) do current[self:EntityName(ent[1], ent[2])] = true end
end

function P:Wanted(name) return wanted[name] end

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------
-- some names are hidden from add-ons on this client ("secret values"): skip those
local isSecret = _G.issecretvalue or function() return false end
local adding = false
local function AddLines(tt, name)
	if not S().tipLines or adding or name == nil or isSecret(name) then return end
	local lines = wanted[name]
	if not lines then return end
	adding = true
	for i, l in ipairs(lines) do
		if i > 4 then break end
		tt:AddLine(("|T%sDot:8:8:0:0:32:32:0:32:0:32:%d:%d:%d|t "):format(P.MEDIA, math.floor(A[1] * 255), math.floor(A[2] * 255), math.floor(A[3] * 255)) .. l, 1, 1, 1)
	end
	if current[name] then tt:AddLine(P.DIM .. "Your current step|r") end
	tt:Show()
	adding = false
end

local function Name(unit)
	local n = unit and UnitName(unit)
	if n == nil or isSecret(n) then return nil end
	return n
end

local function OnUnit(tt)
	local _, unit = tt:GetUnit()
	if unit and not isSecret(unit) then
		local n = Name(unit)
		if n then AddLines(tt, n) end
	end
end

---------------------------------------------------------------------------
-- Nameplates
---------------------------------------------------------------------------
local function Mark(plate, unit)
	if not plate then return end
	local m = plate.PathwayMark
	local name = Name(unit)
	local icon = name and P.plateIcons and P.plateIcons[name]
	local show = name and (icon or (S().plateMarks and wanted[name])) and not UnitIsDead(unit) and not UnitIsPlayer(unit)
	if not show then if m then m:Hide() end; return end
	if not m then
		m = plate:CreateTexture(nil, "OVERLAY")
		plate.PathwayMark = m
	end
	local big = current[name]
	if icon then
		m:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon)
		m:SetSize(22, 22); m:SetVertexColor(1, 1, 1, 1)
	else
		m:SetTexture(P.MEDIA .. "Ring")
		m:SetSize(big and 18 or 12, big and 18 or 12)
		m:SetVertexColor(A[1], A[2], A[3], big and 1 or 0.75)
	end
	m:ClearAllPoints()
	m:SetPoint("BOTTOM", plate, "TOP", 0, big and 4 or 2)
	m:Show()
end

local function RefreshPlates()
	if not P.db then return end
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit then Mark(plate, unit) end
	end
end

function P:RefreshPlates() RefreshPlates() end

P:On("NAME_PLATE_UNIT_ADDED", function(_, unit)
	if not P.db then return end
	Mark(C_NamePlate.GetNamePlateForUnit(unit), unit)
end)
P:On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if plate and plate.PathwayMark then plate.PathwayMark:Hide() end
end)
P:On("UNIT_HEALTH", function(_, unit)
	if unit and unit:find("^nameplate") and UnitIsDead(unit) then
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		if plate and plate.PathwayMark then plate.PathwayMark:Hide() end
	end
end)

---------------------------------------------------------------------------
-- (raid marks are protected on this client: the nameplate icon above does the job)
---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
P:Listen("READY", function()
	if TooltipDataProcessor and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tt) if tt == GameTooltip then OnUnit(tt) end end)
	else
		GameTooltip:HookScript("OnTooltipSetUnit", OnUnit)
	end
	-- world objects only have a name line: match on that
	GameTooltip:HookScript("OnShow", function(tt)
		if tt:GetUnit() or (tt.GetItem and tt:GetItem()) then return end
		local line = _G.GameTooltipTextLeft1
		local name = line and line:GetText()
		if name then AddLines(tt, name) end
	end)
	Rebuild()
end)
P:Listen("QUESTS_CHANGED", function() Rebuild(); RefreshPlates() end)
P:Listen("QUEST_PROGRESS", function() P:Debounce("plates", 0.3, function() Rebuild(); RefreshPlates() end) end)
P:Listen("ROUTE_CHANGED", function() P:RebuildCurrent(); RefreshPlates() end)
P:Listen("TARGET_CHANGED", function() P:RebuildCurrent(); RefreshPlates() end)
P:Listen("SETTINGS_CHANGED", function() Rebuild(); RefreshPlates() end)
end part() end
-- ==================== AutoQuest.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Quest helpers
     Talk to an NPC and Pathway can:
       · accept the quests it suggests for you (only those, never everything)
       · turn in anything that's complete
       · point out the best reward: an upgrade if there is one, otherwise
         the one worth the most (and pick it for you, if you like)
     Hold Shift while talking to someone to do it all yourself. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local ipairs = ipairs

local function S() return P.db.settings end
local function Paused() return IsShiftKeyDown() end
-- on a turn-in run nothing new is taken: it hands in and moves on
local function TurnInRun() return P.route and P.TURN_ONLY and P.TURN_ONLY[P.route.mode] end
local function Suggested(id) return id and id > 0 and P.Q[id] and not TurnInRun() and (P:Available(id)) end

local function NpcID()
	local guid = UnitGUID("npc")
	if not guid then return end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind == "Creature" or kind == "GameObject" then return tonumber(id), kind == "GameObject" and "O" or "N" end
end

-- quest by title among what this NPC starts (older dialogs give titles, not IDs)
local function ByTitle(title)
	local id, kind = NpcID()
	if not id or not title then return end
	for _, qid in ipairs(P.startsBy[kind .. id] or {}) do
		local q = P.Q[qid]
		if q and q[P.K.NAME] == title and P:Available(qid) then return qid end
	end
end

---------------------------------------------------------------------------
-- What the giver didn't offer: quests we expected here that aren't on the
-- list are ones you've done (or can't take), so the guide moves past them
---------------------------------------------------------------------------
local function NotOffered(ids, titles)
	local id, kind = NpcID()
	if not id or not P.cdb then return end
	local changed
	for _, qid in ipairs(P.startsBy[kind .. id] or {}) do
		local q = P.Q[qid]
		if q and P:Available(qid) and not ids[qid] and not titles[q[P.K.NAME]] then
			P.cdb.notOffered[qid] = true
			P.done[qid] = true
			changed = true
		end
	end
	if changed then P:Debounce("notoffered", 0.3, function() P:Send("QUESTS_CHANGED") end) end
end

---------------------------------------------------------------------------
-- Gossip and greeting windows
---------------------------------------------------------------------------
P:On("GOSSIP_SHOW", function()
	if not P.db then return end
	local G = C_GossipInfo
	if not G then return end
	if G.GetAvailableQuests then
		local ids, titles = {}, {}
		for _, q in ipairs(G.GetAvailableQuests() or {}) do
			if q.questID then ids[q.questID] = true end
			if q.title then titles[q.title] = true end
		end
		for _, q in ipairs(G.GetActiveQuests and G.GetActiveQuests() or {}) do
			if q.questID then ids[q.questID] = true end
			if q.title then titles[q.title] = true end
		end
		NotOffered(ids, titles)
	end
	if Paused() then return end
	if S().autoTurnIn and G.GetActiveQuests then
		for _, q in ipairs(G.GetActiveQuests() or {}) do
			if q.isComplete and q.questID then G.SelectActiveQuest(q.questID); return end
		end
	end
	if S().autoAccept and G.GetAvailableQuests then
		for _, q in ipairs(G.GetAvailableQuests() or {}) do
			if Suggested(q.questID) then G.SelectAvailableQuest(q.questID); return end
		end
	end
end)

P:On("PLAYER_LEVEL_UP", function() if P.cdb then wipe(P.cdb.notOffered) end end)   -- try again: a level can change what's offered

P:On("QUEST_GREETING", function()
	if not P.db then return end
	do
		local ids, titles = {}, {}
		for i = 1, (GetNumAvailableQuests() or 0) do
			titles[GetAvailableTitle(i) or ""] = true
			local id = GetAvailableQuestInfo and select(5, GetAvailableQuestInfo(i))
			if id then ids[id] = true end
		end
		for i = 1, (GetNumActiveQuests() or 0) do titles[GetActiveTitle(i) or ""] = true end
		NotOffered(ids, titles)
	end
	if Paused() then return end
	if S().autoTurnIn then
		for i = 1, (GetNumActiveQuests() or 0) do
			local _, complete = GetActiveTitle(i)
			if complete then SelectActiveQuest(i); return end
		end
	end
	if S().autoAccept then
		for i = 1, (GetNumAvailableQuests() or 0) do
			local id = GetAvailableQuestInfo and select(5, GetAvailableQuestInfo(i))
			if (id and Suggested(id)) or (not id and not TurnInRun() and ByTitle(GetAvailableTitle(i))) then SelectAvailableQuest(i); return end
		end
	end
end)

-- the quest window shows what a quest pays: Pathway notes it (see P:LearnQuestXP)
local function Learn()
	local id = GetQuestID and GetQuestID()
	local ok, xp = pcall(GetRewardXP or function() end)
	if ok and id then P:LearnQuestXP(id, xp) end
end

P:On("QUEST_DETAIL", function()
	if not P.db then return end
	Learn()
	if Paused() or not S().autoAccept then return end
	local id = GetQuestID and GetQuestID()
	if Suggested(id) then AcceptQuest() end
end)

P:On("QUEST_PROGRESS", function()
	if not P.db or Paused() or not S().autoTurnIn then return end
	if IsQuestCompletable() then CompleteQuest() end
end)

---------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------
local glow

local function RewardButton(i)
	if QuestInfo_GetRewardButton and QuestInfoFrame and QuestInfoFrame.rewardsFrame then
		local ok, b = pcall(QuestInfo_GetRewardButton, QuestInfoFrame.rewardsFrame, i)
		if ok and b then return b end
	end
	return _G["QuestInfoRewardsFrameQuestInfoItem" .. i] or _G["QuestInfoItem" .. i]
end

local function Highlight(i, why)
	local b = RewardButton(i)
	if not b then return end
	if not glow then
		glow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		glow:SetFrameStrata("DIALOG")
		P.Flat(glow, { 0, 0, 0, 0 }, P.colors.ACCENT_EDGE)
		-- a small badge in the corner (a label above it ran into the next reward's name)
		glow.badge = glow:CreateTexture(nil, "OVERLAY"); glow.badge:SetTexture(P.MEDIA .. "Dot")
		glow.badge:SetSize(16, 16); glow.badge:SetPoint("CENTER", glow, "TOPRIGHT", -3, -3)
		glow.tick = glow:CreateTexture(nil, "OVERLAY", nil, 2); glow.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		glow.tick:SetSize(12, 12); glow.tick:SetPoint("CENTER", glow.badge, "CENTER", 0, 0)
		hooksecurefunc(GameTooltip, "SetQuestItem", function(tip, kind, i)
			if glow:IsShown() and kind == "choice" and i == glow.index and glow.why then
				tip:AddLine("|c" .. P.ACCENT_HEX .. "Pathway pick|r  " .. P.DIM .. glow.why .. "|r")
				tip:Show()
			end
		end)
	end
	glow.index, glow.why = i, why
	glow:SetParent(b)
	glow:ClearAllPoints()
	glow:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 2)
	glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
	glow:SetBackdropBorderColor(A[1], A[2], A[3], 1)
	glow.badge:SetVertexColor(A[1], A[2], A[3], 1)
	glow:Show()
end

local function BestChoice(n)
	local best, bestGain, priciest, bestPrice
	for i = 1, n do
		local link = GetQuestItemLink("choice", i)
		local _, _, _, _, usable = GetQuestItemInfo("choice", i)
		if link then
			if usable ~= false then
				local cmp = P:CompareToEquipped(link)
				if type(cmp) == "table" and (not bestGain or cmp.gain > bestGain) then best, bestGain = i, cmp.gain end
			end
			local price = select(11, (C_Item and C_Item.GetItemInfo or GetItemInfo)(link)) or 0
			if not bestPrice or price > bestPrice then priciest, bestPrice = i, price end
		end
	end
	if best then return best, "upgrade" end
	return priciest, "sells for the most"
end

P:On("QUEST_COMPLETE", function()
	if not P.db then return end
	Learn()
	local n = GetNumQuestChoices() or 0
	if n <= 1 then
		if S().autoTurnIn and not Paused() then GetQuestReward(n) end
		return
	end
	local pick, why = BestChoice(n)
	if not pick then return end
	Highlight(pick, why)
	if S().autoReward and not Paused() then GetQuestReward(pick) end
end)

P:On("QUEST_FINISHED", function() if glow then glow:Hide() end end)
end part() end
-- ==================== Gear.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Gear
     When you pick up a piece of gear that beats what you're wearing, Pathway
     tells you why and asks whether to put it on.
       · scores use simple, class-based stat weights (Classic gear has no specs)
       · can't-use items are skipped (anything the tooltip shows in red)
       · rings, trinkets, two-handers vs main hand + off hand are handled
       · Bind on Equip items are flagged (or skipped, if you prefer)
     Swapping gear, using the bank and moving bags never count as "new". ]]

local ADDON, P = __addon, __ns
local pairs, ipairs, wipe, floor, abs, max, min = pairs, ipairs, wipe, math.floor, math.abs, math.max, math.min
local tinsert, sort = table.insert, table.sort

local function S() return P.db.settings end

---------------------------------------------------------------------------
-- Compatibility
---------------------------------------------------------------------------
local Container = C_Container or {}
local function NumSlots(bag) return (Container.GetContainerNumSlots or GetContainerNumSlots)(bag) or 0 end
local function SlotLink(bag, slot) return (Container.GetContainerItemLink or GetContainerItemLink)(bag, slot) end
local function Pickup(bag, slot) return (Container.PickupContainerItem or PickupContainerItem)(bag, slot) end
local function ItemStats(link)
	if C_Item and C_Item.GetItemStats then return C_Item.GetItemStats(link) end
	if GetItemStats then return GetItemStats(link) end
end
local function ItemInfo(link) return (C_Item and C_Item.GetItemInfo or GetItemInfo)(link) end
local function ItemInfoInstant(id) return (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(id) end

---------------------------------------------------------------------------
-- Stat weights per class
---------------------------------------------------------------------------
local STAT = {
	STR = "ITEM_MOD_STRENGTH_SHORT", AGI = "ITEM_MOD_AGILITY_SHORT", STA = "ITEM_MOD_STAMINA_SHORT",
	INT = "ITEM_MOD_INTELLECT_SHORT", SPI = "ITEM_MOD_SPIRIT_SHORT", AP = "ITEM_MOD_ATTACK_POWER_SHORT",
	SP = "ITEM_MOD_SPELL_POWER_SHORT", SD = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", HEAL = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
	ARMOR = "RESISTANCE0_NAME", DPS = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
}
local WEIGHTS = {
	WARRIOR = { STR = 1, AGI = 0.5, STA = 0.6, AP = 0.45, ARMOR = 0.02, DPS = 4.5 },
	PALADIN = { STR = 1, INT = 0.5, STA = 0.6, SPI = 0.2, AP = 0.4, SP = 0.6, HEAL = 0.4, ARMOR = 0.02, DPS = 4 },
	HUNTER  = { AGI = 1, STA = 0.5, INT = 0.35, STR = 0.1, AP = 0.45, ARMOR = 0.01, DPS = 1.2, RDPS = 4.5 },
	ROGUE   = { AGI = 1, STR = 0.55, STA = 0.5, AP = 0.45, ARMOR = 0.01, DPS = 4.5 },
	PRIEST  = { INT = 1, SPI = 0.8, STA = 0.5, SP = 0.9, HEAL = 0.6, ARMOR = 0.005, DPS = 0.3 },
	SHAMAN  = { INT = 0.7, STR = 0.7, AGI = 0.4, STA = 0.5, SPI = 0.3, SP = 0.7, AP = 0.35, ARMOR = 0.015, DPS = 3.5 },
	MAGE    = { INT = 1, SPI = 0.6, STA = 0.5, SP = 1, ARMOR = 0.005, DPS = 0.3 },
	WARLOCK = { INT = 0.8, STA = 0.8, SPI = 0.4, SP = 1, ARMOR = 0.005, DPS = 0.3 },
	DRUID   = { INT = 0.6, AGI = 0.6, STR = 0.6, STA = 0.5, SPI = 0.4, SP = 0.6, AP = 0.35, ARMOR = 0.015, DPS = 2.5 },
}

local SLOTS = {
	INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
	INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
	INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
	INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
	INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}

-- by talent tree, where it changes what a class wants (tree order as in the talent window)
local SPEC = {
	WARRIOR = { [3] = { STA = 1, STR = 0.6, AGI = 0.6, ARMOR = 0.05, AP = 0.2, DPS = 2 } },                       -- Protection
	PALADIN = { [1] = { INT = 1, SPI = 0.5, HEAL = 1, SP = 0.3, STA = 0.4, ARMOR = 0.01, DPS = 0.3 },              -- Holy
		[2] = { STA = 1, STR = 0.6, AGI = 0.4, SP = 0.4, ARMOR = 0.05, DPS = 2 },                                -- Protection
		[3] = { STR = 1, AGI = 0.5, STA = 0.5, AP = 0.45, INT = 0.2, ARMOR = 0.02, DPS = 4.5 } },                -- Retribution
	PRIEST = { [1] = { INT = 1, SPI = 0.9, HEAL = 1, SP = 0.4, STA = 0.5, ARMOR = 0.005, DPS = 0.3 },            -- Discipline
		[2] = { INT = 1, SPI = 1, HEAL = 1, SP = 0.3, STA = 0.4, ARMOR = 0.005, DPS = 0.3 },                     -- Holy
		[3] = { INT = 0.8, SP = 1, STA = 0.6, SPI = 0.5, ARMOR = 0.005, DPS = 0.3 } },                           -- Shadow
	SHAMAN = { [1] = { INT = 1, SP = 1, STA = 0.5, SPI = 0.3, ARMOR = 0.01, DPS = 0.5 },                         -- Elemental
		[2] = { STR = 1, AGI = 0.7, STA = 0.5, AP = 0.45, INT = 0.3, ARMOR = 0.02, DPS = 4.5 },                  -- Enhancement
		[3] = { INT = 1, HEAL = 1, SPI = 0.4, SP = 0.3, STA = 0.5, ARMOR = 0.01, DPS = 0.5 } },                  -- Restoration
	DRUID = { [1] = { INT = 1, SP = 1, SPI = 0.5, STA = 0.5, ARMOR = 0.005, DPS = 0.3 },                         -- Balance
		[2] = { AGI = 1, STR = 0.8, STA = 0.7, AP = 0.45, ARMOR = 0.03, DPS = 0.5 },                             -- Feral
		[3] = { INT = 1, SPI = 0.8, HEAL = 1, SP = 0.3, STA = 0.4, ARMOR = 0.005, DPS = 0.3 } },                 -- Restoration
}

local specTree, specAt = nil, -1e9
local function Tree()
	if GetTime() - specAt < 30 then return specTree end
	specAt, specTree = GetTime(), nil
	-- the tree with the most points (10 before it counts), from Forever's specializations
	local SI = C_SpecializationInfo
	local best, bestPts = nil, 9
	local classID = select(3, UnitClass("player"))
	for i = 1, ((SI.GetNumSpecializationsForClassID and classID and SI.GetNumSpecializationsForClassID(classID)) or 3) do
		local ok, _, _, _, _, _, _, pts = pcall(SI.GetSpecializationInfo, i)
		if ok and type(pts) == "number" and pts > bestPts then best, bestPts = i, pts end
	end
	specTree = best
	return best
end
P:On("CHARACTER_POINTS_CHANGED", function() specAt = -1e9 end)
P:On("PLAYER_TALENT_UPDATE", function() specAt = -1e9 end)

local function Weights()
	local class = P.me.classFile or ""
	local tree = Tree()
	return (tree and SPEC[class] and SPEC[class][tree]) or WEIGHTS[class] or WEIGHTS.WARRIOR
end

-- weapon damage per second and armor, read from the tooltip when the item's stats leave them out
local tip
local DPS_PAT = "%(([%d%.,]+) " .. ((DPS_TEMPLATE or "(%s damage per second)"):match("%%s (.-)%)") or "damage per second") .. "%)"
local ARMOR_PAT = "^([%d,]+) " .. (ARMOR or "Armor") .. "$"
local function TooltipNumbers(link)
	if not tip then
		tip = CreateFrame("GameTooltip", "PathwayGearTooltip", nil, "GameTooltipTemplate")
		tip:SetOwner(WorldFrame, "ANCHOR_NONE")
	end
	tip:ClearLines()
	tip:SetHyperlink(link)
	local dps, armor
	for i = 2, tip:NumLines() do
		local fs = _G["PathwayGearTooltipTextLeft" .. i]
		local t = fs and fs:GetText()
		if t and not (issecretvalue and issecretvalue(t)) then
			local d = t:match(DPS_PAT)
			if d then dps = tonumber((d:gsub(",", ""))) end
			local a = t:match(ARMOR_PAT)
			if a then armor = tonumber((a:gsub(",", ""))) end
		end
	end
	return dps, armor
end

-- stats as { STR = n, ... } plus a score
local function Rate(link, slot)
	if not link then return 0, {} end
	local raw = ItemStats(link)
	if not raw then return nil end
	local _, _, _, equipLoc = ItemInfoInstant(link)
	local weapon = equipLoc and (equipLoc:find("WEAPON") or equipLoc:find("RANGED") or equipLoc == "INVTYPE_THROWN")
	if (weapon and not raw[STAT.DPS]) or not raw[STAT.ARMOR] then
		local dps, armor = TooltipNumbers(link)
		if weapon and dps and not raw[STAT.DPS] then raw[STAT.DPS] = dps end
		if armor and not raw[STAT.ARMOR] then raw[STAT.ARMOR] = armor end
	end
	local w, out, score = Weights(), {}, 0
	for short, key in pairs(STAT) do
		local v = raw[key]
		if v and v ~= 0 then
			out[short] = v
			local weight = w[short]
			if short == "SD" then weight = w.SP end
			if short == "DPS" then weight = (slot == 18) and (w.RDPS or 0.5) or w.DPS end
			score = score + v * (weight or 0)
		end
	end
	return score, out
end
P.RateItem = Rate

---------------------------------------------------------------------------
-- Can I use it? (anything red in the tooltip says no)
---------------------------------------------------------------------------
local scan
local function Usable(bag, slot)
	if not scan then
		scan = CreateFrame("GameTooltip", "PathwayScanTooltip", nil, "GameTooltipTemplate")
		scan:SetOwner(WorldFrame, "ANCHOR_NONE")
	end
	scan:ClearLines()
	scan:SetBagItem(bag, slot)
	local bound = false
	for i = 2, scan:NumLines() do
		local l = _G["PathwayScanTooltipTextLeft" .. i]
		local t = l and l:GetText()
		if t and (t == ITEM_SOULBOUND or t == ITEM_ACCOUNTBOUND or t == ITEM_BNETACCOUNTBOUND) then bound = true end
	end
	for i = 2, scan:NumLines() do
		for _, side in ipairs({ "Left", "Right" }) do
			local fs = _G["PathwayScanTooltipText" .. side .. i]
			if fs and fs:IsShown() and (fs:GetText() or "") ~= "" then
				local r, g, b = fs:GetTextColor()
				if r > 0.95 and g < 0.2 and b < 0.2 then return false, bound end
			end
		end
	end
	return true, bound
end

---------------------------------------------------------------------------
-- How does an item compare with what you're wearing?
--   returns nil (not better), "loading", or { slot, gain, oldScore, newStats, oldStats, oldLink }
---------------------------------------------------------------------------
function P:CompareToEquipped(link)
	local _, _, _, equipLoc = ItemInfoInstant(link)
	local slots = SLOTS[equipLoc or ""]
	if not slots then return end
	local newScore, newStats = Rate(link, slots[1])
	if newScore == nil then return "loading" end
	if newScore <= 0 then return end
	-- what it would replace: the weaker of two ring/trinket slots;
	-- a two-hander replaces main hand + off hand
	local target, oldScore, oldStats, oldLink
	for _, s in ipairs(slots) do
		local l = GetInventoryItemLink("player", s)
		local sc, st = Rate(l, s)
		if sc == nil then return "loading" end
		if equipLoc == "INVTYPE_2HWEAPON" then
			local oh = GetInventoryItemLink("player", 17)
			local sc2, st2 = Rate(oh, 17)
			if sc2 == nil then return "loading" end
			sc = sc + sc2
			for k, v in pairs(st2) do st[k] = (st[k] or 0) + v end
		end
		if not oldScore or sc < oldScore then target, oldScore, oldStats, oldLink = s, sc, st, l end
	end
	local gain = newScore - oldScore
	-- clearly better: a real gain, and at least 3% (early gear has small numbers, so no fixed floor)
	if gain <= 0.05 or (oldScore > 0 and gain / oldScore < 0.03) then return end
	return { slot = target, gain = gain, oldScore = oldScore, newStats = newStats, oldStats = oldStats or {}, oldLink = oldLink }
end

---------------------------------------------------------------------------
-- Is the item in this bag slot an upgrade?
---------------------------------------------------------------------------
function P:EvaluateGear(bag, slot)
	local link = SlotLink(bag, slot)
	if not link then return end
	local _, _, _, equipLoc = ItemInfoInstant(link)
	local slots = SLOTS[equipLoc or ""]
	if not slots then return end
	local itemID = tonumber(link:match("item:(%d+)"))
	if itemID and self.cdb.ignoredGear[itemID] then return end
	local _, _, quality, _, reqLevel, _, _, _, _, _, _, _, _, bindType = ItemInfo(link)
	if not quality then return nil, "loading" end
	if reqLevel and reqLevel > (self.me.level or 1) then return end
	local usable, bound = Usable(bag, slot)
	if not usable then return end
	local boe = bindType == 2 and not bound
	if boe and not S().gearBoE then return end

	local cmp = P:CompareToEquipped(link)
	if not cmp then return end
	if cmp == "loading" then return nil, "loading" end
	local target, gain, newStats, oldStats, oldLink, oldScore = cmp.slot, cmp.gain, cmp.newStats, cmp.oldStats, cmp.oldLink, cmp.oldScore
	return {
		link = link, itemID = itemID, slot = target, gain = gain, pct = oldScore > 0 and gain / oldScore or nil,
		newStats = newStats, oldStats = oldStats or {}, oldLink = oldLink, boe = boe,
	}
end

local function StatName(short)
	local key = STAT[short]
	local s = key and _G[key]
	if short == "DPS" then return "DPS" end
	return s or short
end

local function Diff(up)
	local parts = {}
	local seen = {}
	for k in pairs(up.newStats) do seen[k] = true end
	for k in pairs(up.oldStats) do seen[k] = true end
	local list = {}
	for k in pairs(seen) do
		local d = (up.newStats[k] or 0) - (up.oldStats[k] or 0)
		if abs(d) >= 0.05 then list[#list + 1] = { k = k, d = d, w = abs(d * (Weights()[k] or 0.1)) } end
	end
	sort(list, function(a, b) return a.w > b.w end)
	for i = 1, min(4, #list) do
		local e = list[i]
		local v = (e.k == "DPS") and ("%.1f"):format(abs(e.d)) or tostring(floor(abs(e.d) + 0.5))
		local c = e.d > 0 and "|cff7cf29c+" or "|cffff7a7a-"
		parts[#parts + 1] = c .. v .. " " .. StatName(e.k) .. "|r"
	end
	return table.concat(parts, "  ")
end

function P:GearDiff(up) return Diff(up) end

---------------------------------------------------------------------------
-- Equip
---------------------------------------------------------------------------
local function FindInBags(link)
	for bag = 0, 4 do
		for slot = 1, NumSlots(bag) do
			if SlotLink(bag, slot) == link then return bag, slot end
		end
	end
end

function P:GearInBags(link) return FindInBags(link) ~= nil end

function P:EquipUpgrade(up)
	if InCombatLockdown() then self:Toast("You can equip it after this fight"); return false end
	local bag, slot = FindInBags(up.link)
	if not bag then self:Toast("That item isn't in your bags anymore"); return end
	ClearCursor()
	Pickup(bag, slot)
	EquipCursorItem(up.slot)
	if StaticPopup_Visible and StaticPopup_Visible("EQUIP_BIND") then
		-- Blizzard asks to confirm Bind on Equip; the player answers that one
		return
	end
	if CursorHasItem() then ClearCursor() end
	if S().sound then PlaySound(SOUNDKIT.PUT_DOWN_SMALL_CHAIN or 1203) end
	if P.ClearNote then P:ClearNote("gear:" .. up.link) end
	if P.DismissPrompt then P:DismissPrompt("gear:" .. up.link) end
	return true
end

local function Offer(up)
	local name = up.link
	local old = up.oldLink and ("Replaces " .. up.oldLink) or "Fills an empty slot"
	local pct = up.pct and ("  " .. P.DIM .. ("(+%d%%)"):format(floor(up.pct * 100 + 0.5)) .. "|r") or ""
	local lines = { Diff(up) .. pct, P.DIM .. old .. "|r" }
	if up.boe then lines[#lines + 1] = P.GOLD .. "Binds when equipped|r" end
	local key = "gear:" .. up.link
	-- it also waits in your notifications, with an Equip button, until it's on or gone
	if P.Notify then
		P:Notify({ key = key, kind = "gear", icon = select(5, ItemInfoInstant(up.link)), item = up.link,
			text = "Upgrade: " .. up.link, sub = Diff(up) .. pct,
			action = { "Equip", function() return P:EquipUpgrade(up) end } })
	end
	-- soulbound and clearly better: put it on for you, if you asked for that
	if S().gearAutoEquip and not up.boe and not InCombatLockdown() then
		if P:EquipUpgrade(up) ~= false then
			P:Toast("Equipped " .. up.link .. "  " .. Diff(up))
			return
		end
	end
	if not S().gearAsk then
		P:Print("Upgrade: %s  %s", up.link, Diff(up))
		P:Toast("Upgrade in your bags: " .. up.link)
		return
	end
	P:Ask({
		key = key,
		icon = select(5, ItemInfoInstant(up.link)),
		item = up.link,
		title = "Upgrade  " .. name,
		text = table.concat(lines, "\n"),
		buttons = {
			{ "Never", function() P.cdb.ignoredGear[up.itemID] = true end },
			{ "Not now", function() end },
			{ "Equip", function() return P:EquipUpgrade(up) end, true },
		},
	})
end

---------------------------------------------------------------------------
-- Watching for new gear: diff counts of equippable items in bags + equipped
---------------------------------------------------------------------------
local baseline
local silentUntil = math.huge
local bankOpen = false

local function Counts()
	local t = {}
	for bag = 0, 4 do
		for slot = 1, NumSlots(bag) do
			local link = SlotLink(bag, slot)
			if link then
				local _, _, _, loc = ItemInfoInstant(link)
				if SLOTS[loc or ""] then t[link] = (t[link] or 0) + 1 end
			end
		end
	end
	for s = 1, 19 do
		local link = GetInventoryItemLink("player", s)
		if link then t[link] = (t[link] or 0) + 1 end
	end
	return t
end

local retry = {}
local function Check()
	if not S().gearAlerts then baseline = nil; return end
	local now = Counts()
	if baseline and GetTime() >= silentUntil and not bankOpen then
		for link, n in pairs(now) do
			if n > (baseline[link] or 0) then retry[link] = 3 end
		end
	end
	baseline = now
	for link, tries in pairs(retry) do
		local bag, slot = FindInBags(link)
		if not bag then
			retry[link] = nil
		else
			local up, why = P:EvaluateGear(bag, slot)
			if up then retry[link] = nil; Offer(up)
			elseif why == "loading" and tries > 1 then retry[link] = tries - 1
			else retry[link] = nil end
		end
	end
	if next(retry) then C_Timer.After(1, Check) end
end

function P:ScanAllGear()
	-- "/pw gear": look through everything in your bags right now
	local found = 0
	for bag = 0, 4 do
		for slot = 1, NumSlots(bag) do
			local up = self:EvaluateGear(bag, slot)
			if up then found = found + 1; Offer(up) end
		end
	end
	if found == 0 then self:Toast("Nothing in your bags beats what you're wearing") end
end

P:On("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
	silentUntil = GetTime() + ((isLogin or isReload) and 5 or 2)
	C_Timer.After((isLogin or isReload) and 5.2 or 2.2, function() baseline = Counts() end)
end)
P:On("BAG_UPDATE_DELAYED", function() if P.db then P:Debounce("gear", 0.3, Check) end end)
P:On("PLAYER_EQUIPMENT_CHANGED", function() C_Timer.After(0.3, function() baseline = Counts() end) end)
P:On("BANKFRAME_OPENED", function() bankOpen = true end)
P:On("BANKFRAME_CLOSED", function() bankOpen = false; C_Timer.After(0.3, function() baseline = Counts() end) end)
end part() end
-- ==================== Zones.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Zone guides
     A zone's guide: everything there that fits your level, in a sensible
     order. You load it from the guide window or /pw zone; Pathway never
     interrupts you with an offer when you walk into a zone. A brand-new
     character gets one welcome after setup. ]]

local ADDON, P = __addon, __ns


local function S() return P.db.settings end

---------------------------------------------------------------------------
-- Three ways to quest, picked by you (never switched for you):
--   story   Storyline: the story chain that fits your level best, start to
--           finish, then the next best one
--   all     All quests: every quest in the zone, chain to chain
--   fast    Fastest XP: only the quickest XP (top 25% by XP a minute), a set
--           at a time, wherever the next set gives the most XP a minute
---------------------------------------------------------------------------
P.STYLES = {
	{ key = "story", label = "Storyline", long = "Storyline", short = "The story chain that fits your level, start to finish.", tip = "Only the story chain that fits your level best, start to finish. Then the next best one." },
	{ key = "all", label = "All quests", long = "All quests", short = "Every quest here, one chain at a time.", tip = "Every quest in the zone, one chain at a time: a chain is finished before the next starts, with quests on the way picked up as you pass." },
	{ key = "fast", label = "Fastest XP", long = "Fastest XP", short = "Only the quickest XP (the top 25% by XP a minute), a set at a time.", tip = "Only the quickest experience: the top 25% by XP a minute, each quest timed from what it asks and your own pace. Pick up that set, finish it without picking up anything else, then on to wherever the next set gives the most XP per minute, trip included, on either continent." },
}
function P:QuestStyle() return S().questStyle or "fast" end

-- which style the guide you're on is (nil for other guides: a dungeon, a chain...)
function P:RouteStyle(r)
	r = r or self.route
	if not r then return end
	if r.mode == "fast" then return "fast" end
	if r.guide and r.guide:match("^story:") then return "story" end
	if r.mode == "zone" or (r.guide and r.guide:match("^zone:")) then return "all" end
end

-- the zone a guide is about, else where you are
function P:RouteZone(r)
	r = r or self.route
	local z = r and (r.map or (r.guide and tonumber(r.guide:match("^%a+:(%d+)$"))))
	return z or self:PlayerZone()
end

local function Load(zone, quiet, style)
	style = style or P:QuestStyle()
	local name = P:MapName(zone)
	if style == "fast" then
		if P:StartRoute("fast", { quiet = true }) then
			if not quiet then P:Toast("Fastest XP: the top quests for experience, one set at a time") end
			return true
		end
	elseif style == "story" and P.LoadGuide then
		if P:LoadGuide("story:" .. zone, true) then
			if not quiet then P:Toast(name .. ": storyline") end
			return true
		end
		-- no story chain here for you right now: the zone's other quests while
		-- there are some, else the closest zone with a chain for your level
		local any = false
		local cz = P.Cat and P.Cat.zones and P.Cat.zones[zone]
		for _, qid in ipairs(cz and cz.quests or {}) do if P:Available(qid) or P.log[qid] then any = true break end end
		if not any then
			local z = P.Cat and P.Cat.StoryElsewhere and P.Cat:StoryElsewhere(zone)
			if z and P:LoadGuide("story:" .. z.map, true) then
				P:Toast(("Nothing left in %s's story for you: on to %s"):format(name, z.name))
				return true
			end
		end
	end
	-- all quests (and a zone with no story of its own)
	if (P.LoadGuide and P:LoadGuide("zone:" .. zone, true)) or P:StartRoute("zone", { map = zone, quiet = true }) then
		if not quiet then P:Toast(name .. ": " .. (style == "story" and "all quests (no storyline here)" or "all quests")) end
		return true
	end
	return P:StartRoute("next", { quiet = quiet })
end
P.LoadZoneGuide = function(_, zone, quiet, style) return Load(zone or P:PlayerZone(), quiet, style) end

-- the switch on the guide window and in the journal: this zone, this way. The
-- guide you're on is replaced (not stacked up in tabs), and the choice is kept
-- for next time.
function P:PlayZone(zone, style)
	S().questStyle = style
	local same = self.route and self:RouteStyle() ~= nil
	if same and self.track then self:CloseTrack(self.track, true) end
	local ok = Load(zone or self:RouteZone(), false, style)
	self:Send("SETTINGS_CHANGED")
	return ok
end

-- a new character: everything in the starting area, nearest first, so the
-- quest in front of you is the first step. The zone's story follows after.
function P:StartFirstSteps(zone)
	zone = zone or self:PlayerZone()
	local name = self:MapName(zone)
	if zone and self:StartRoute("zone", { map = zone, quiet = true, title = name .. ": first steps", guide = "start:" .. zone }) then
		self:Toast("Follow the arrow: your first quest is right here")
		if self.GuideState and self:GuideState() ~= "open" then self:SetGuideState("open") end
		return true
	end
	if self:StartRoute("next", { quiet = true }) then return true end
	self:Ask({ key = "nothing", icon = "Interface\\Icons\\INV_Misc_QuestionMark", title = "Pathway is learning this area",
		text = "It doesn't know the quests here yet. Talk to anyone with a |cffffd200!|r over their head:\nPathway learns new quests as you do them and guides you from then on.",
		buttons = { { "Okay", function() end, true } } })
	return false
end

-- a brand-new character gets one friendly question: want a hand from the very start?
local function Welcome()
	local c = P.cdb
	if not c or c.welcomed then return false end
	c.welcomed = true
	if (UnitLevel("player") or 1) > 5 then return false end
	local zone = P:PlayerZone()
	if not zone then return false end
	local name = UnitName("player")
	P:Ask({
		key = "welcome",
		icon = "Interface\\AddOns\\Pathway\\Media\\Icon",
		title = "Welcome" .. ((type(name) == "string" and not (issecretvalue and issecretvalue(name))) and (", " .. name) or ""),
		text = ("Want Pathway to walk you through %s from your very first quest?\n"
			.. P.DIM .. "Follow the arrow, click the faces on the quest bar, and you're on your way.|r"):format(P:MapName(zone)),
		buttons = {
			{ "No thanks", function() end },
			{ "Start guide", function() P:StartFirstSteps(zone) end, true },
		},
	})
	return true
end

P:On("PLAYER_ENTERING_WORLD", function(_, isLogin, isReload)
	-- give the quest log a moment to load before counting
	local function go()
		-- the first-time setup goes first
		if P:InSetup() or P.placing then C_Timer.After(2, go) return end
		if isLogin then Welcome() end
	end
	C_Timer.After((isLogin or isReload) and 4 or 1.5, go)
end)

function P:ResetZoneChoices() wipe(self.db.zones) end
end part() end
-- ==================== Find.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Find the nearest…
     Repair, food and drink, an innkeeper, a mailbox, a flight master, your
     class trainer, a profession trainer, the bank, the auction house, a stable master or a spirit healer:
     one click and the arrow takes you to the closest friendly one.
       /pw find repair  ·  the Find button on the map bar  ·  key binding ]]

local ADDON, P = __addon, __ns
local floor, huge = math.floor, math.huge

local F = {}
P.Find = F

local VENDOR, TRAINER, SPIRIT, INN, BANK, AUCTION, STABLE, REPAIR = 4, 16, 32, 128, 256, 4096, 8192, 16384
local bit_band = bit and bit.band or function(a, b)
	local r, m = 0, 1
	while a > 0 and b > 0 do
		if a % 2 == 1 and b % 2 == 1 then r = r + m end
		a, b, m = floor(a / 2), floor(b / 2), m * 2
	end
	return r
end
local function Has(flags, f) return bit_band(flags, f) ~= 0 end

local FOOD = { "food", "drink", "baker", "butcher", "fruit", "cook", "meat", "inn", "bread", "wine", "general", "trade supplies" }
local PROFS = { "Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering", "First Aid", "Fishing", "Herbalism",
	"Leatherworking", "Mining", "Skinning", "Tailoring" }

-- what each kind looks for: a test on (flags, title lowercased)
F.KINDS = {
	{ "repair", "Repair", "Interface\\Icons\\Trade_BlackSmithing", function(fl) return Has(fl, REPAIR) end },
	{ "food", "Food & drink", "Interface\\Icons\\INV_Misc_Food_15", function(fl, sub)
		if Has(fl, INN) then return true end
		if not Has(fl, VENDOR) then return false end
		for _, w in ipairs(FOOD) do if sub:find(w, 1, true) then return true end end
	end },
	{ "inn", "Innkeeper", "Interface\\Icons\\INV_Misc_Rune_01", function(fl) return Has(fl, INN) end },
	{ "class", "Class trainer", "Interface\\Icons\\INV_Misc_Book_11", function(fl, sub)
		local class = (UnitClass("player") or ""):lower()
		return Has(fl, TRAINER) and sub:find(class .. " trainer", 1, true) ~= nil
	end },
	{ "bank", "Bank", "Interface\\Icons\\INV_Misc_Bag_10", function(fl) return Has(fl, BANK) end },
	{ "ammo", "Ammunition", "Interface\\Icons\\INV_Ammo_Arrow_02", function(fl, sub)
		return Has(fl, VENDOR) and (sub:find("ammo", 1, true) or sub:find("bowyer", 1, true) or sub:find("gunsmith", 1, true)
			or sub:find("arrow", 1, true) or sub:find("bow", 1, true) or sub:find("gun", 1, true)) ~= nil
	end },
	{ "mail", "Mailbox", "Interface\\Icons\\INV_Letter_15", nil, false, "MB" },
	{ "flight", "Flight master", "Interface\\Icons\\Ability_Mount_Wyvern_01", nil, false, "FM" },
	{ "auction", "Auction house", "Interface\\Icons\\INV_Misc_Coin_01", function(fl) return Has(fl, AUCTION) end },
	{ "stable", "Stable master", "Interface\\Icons\\Ability_Hunter_BeastCall", function(fl) return Has(fl, STABLE) end },
	{ "spirit", "Spirit healer", "Interface\\Icons\\Spell_Holy_Resurrection", function(fl) return Has(fl, SPIRIT) end },
}
for _, name in ipairs(PROFS) do
	local key = "prof:" .. name:lower()
	local want = name:lower()
	F.KINDS[#F.KINDS + 1] = { key, name .. " trainer", nil, function(fl, sub)
		return Has(fl, TRAINER) and sub:find(want, 1, true) ~= nil and not sub:find("supplies", 1, true)
	end, true }
end
local BY = {}
for _, k in ipairs(F.KINDS) do BY[k[1]] = k end

local function Friendly(fac)
	local me = (P.me and P.me.faction or UnitFactionGroup("player")) == "Horde" and "H" or "A"
	return fac and fac:find(me, 1, true) ~= nil
end

-- the nearest one on your continent: id, { name, title, map, x, y }, yards
function F:Nearest(key)
	local kind = BY[key]
	if not kind or not P.SV then return end
	local inst, px, py = P:PlayerPos()
	if not inst then return end
	local here = P:PlayerZone()
	local best, bestD, bestAt
	-- nearest on foot (roads and passes), not as the crow flies; the straight line
	-- is a quick floor, so the real walk is only worked out for real contenders
	local function Try(id, map, x, y, name, title)
		local ii, wx, wy = P:WorldPos(map, x, y)
		if ii ~= inst then return end
		local straight = math.sqrt((wx - px) ^ 2 + (wy - py) ^ 2)
		if bestD and straight >= bestD then return end
		local d = P.WalkYards and P:WalkYards(here, px, py, P:ZoneOf(map), wx, wy) or straight
		if d < huge and (not bestD or d < bestD) then best, bestD, bestAt = id, d, { name, title, map, x, y } end
	end
	if kind[6] == "MB" then                          -- mailboxes: anyone can use one
		local mb = P.MB or {}
		for i = 1, #mb, 2 do
			local x, y = P.Unpack(mb[i + 1])
			Try("mail" .. i, mb[i], x, y, "Mailbox", "")
		end
	elseif kind[6] == "FM" then                      -- flight masters of your side
		for id, row in pairs(P.FM or {}) do
			if Friendly(row[4]) then
				local x, y = P.Unpack(row[3])
				Try(id, row[2], x, y, row[1], "Flight Master")
			end
		end
	else
		for id, row in pairs(P.SV) do
			if Friendly(row[5]) and kind[4](row[3], (row[2] or ""):lower()) then
				local pts = row[4]
				for i = 1, #pts, 2 do
					local x, y = P.Unpack(pts[i + 1])
					Try(id, pts[i], x, y, row[1], row[2])
				end
			end
		end
	end
	if best then return best, bestAt, bestD end
end

function F:Go(key)
	local kind = BY[key]
	if not kind then
		P:Print("Find: repair, food, inn, mail, flight, class, bank, auction, stable, spirit, or a profession (\"/pw find mining\").")
		return
	end
	local id, row = self:Nearest(key)
	if not id then P:Toast("No " .. kind[2]:lower() .. " on this continent for you") return end
	local who = row[1] .. ((row[2] ~= "" and kind[1] ~= "flight") and (" <" .. row[2] .. ">") or "")
	P:StartRoute("next", { single = { key = "find" .. id, goal = (row[1] == kind[2]) and kind[2] or (kind[2] .. ": " .. who), point = { row[3], row[4], row[5] }, find = id },
		title = kind[2] })
	P:Toast(((row[1] == kind[2]) and kind[2] or (kind[2] .. ": " .. row[1])) .. " in " .. P:MapName(row[3]))
end

-- the Find menu (map bar, guide window), or its entries inside another menu
function F:Menu(owner)
	local menu = MenuUtil or P.MiniMenu
	menu.CreateContextMenu(owner, function(_, root)
		root:CreateTitle("Find the nearest")
		self:FillMenu(root)
	end)
end

function F:FillMenu(root)
	do
		local profs
		for _, k in ipairs(F.KINDS) do
			if not ((k[1] == "stable" or k[1] == "ammo") and select(2, UnitClass("player")) ~= "HUNTER") then
				local id, row, d = self:Nearest(k[1])
				if id then
					local label = ("%s  %s%s · %d yd|r"):format(k[2], P.DIM, P:MapName(row[3]), floor(d))
					if k[5] then
						profs = profs or root:CreateButton("Profession trainers")
						profs:CreateButton(label, function() self:Go(k[1]) end)
					else
						root:CreateButton((k[3] and ("|T" .. k[3] .. ":14|t ") or "") .. label, function() self:Go(k[1]) end)
					end
				end
			end
		end
	end
end

-- slash: "/pw find mining" → prof:mining
function F:Slash(arg)
	arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if arg == "" then self:Go(nil) return end
	if BY[arg] then return self:Go(arg) end
	if BY["prof:" .. arg] then return self:Go("prof:" .. arg) end
	for _, k in ipairs(F.KINDS) do
		if k[2]:lower():find(arg, 1, true) then return self:Go(k[1]) end
	end
	self:Go(nil)
end

BINDING_NAME_PATHWAY_FIND = "Go to the nearest repair"
function Pathway_FindRepair() F:Go("repair") end
end part() end
-- ==================== Extras.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — the little things
     · Corpse run: release and the arrow points to your body; back on your
       feet, your guide carries on.
     · Repair: when your gear is nearly broken, offers the nearest repair.
     · Full quest log: says so, and which gray quests you could drop. ]]

local ADDON, P = __addon, __ns
local floor = math.floor

local function S() return P.db.settings end

---------------------------------------------------------------------------
-- Corpse run
---------------------------------------------------------------------------
-- While you're a ghost the arrow and the paths point to your body; the guide
-- itself stays where it was, so back on your feet it simply carries on.
local function CorpsePos()
	-- where you died, kept in case the game can't say where your body is
	local fallback = P.cdb and P.cdb.deathAt
	local function Fallback() if fallback then return fallback[1], fallback[2], fallback[3] end end
	if not (C_DeathInfo and C_DeathInfo.GetCorpseMapPosition) then return Fallback() end
	-- the corpse can be on your zone's map or one above it (a sub-zone, a city)
	local map = C_Map.GetBestMapForUnit("player")
	for _ = 1, 4 do
		if not map then return Fallback() end
		local pos = C_DeathInfo.GetCorpseMapPosition(map)
		if pos then
			local x, y
			if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
			if x and y and not (x == 0 and y == 0) then return map, x, y end
		end
		local info = C_Map.GetMapInfo(map)
		map = info and info.parentMapID
		if map == 0 then map = nil end
	end
	return Fallback()
end

P:On("PLAYER_DEAD", function()
	local map = C_Map.GetBestMapForUnit("player")
	local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
	if pos and P.cdb then
		local x, y
		if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
		if x and y then P.cdb.deathAt = { map, x, y } end
	end
end)

local function ClearCorpse()
	if not P.corpse then return end
	P.corpse = nil
	P:Send("TARGET_CHANGED"); P:Send("ROUTE_CHANGED")
	if P.RefreshArrow then P:RefreshArrow() end
end

local tries = 0
local function CorpseRun()
	if not (P.db and S().corpseRun and UnitIsGhost("player")) then ClearCorpse() return end
	local map, x, y = CorpsePos()
	if not map then
		-- right after you release the game may not know yet: try again for a few seconds
		tries = tries + 1
		if tries < 10 then C_Timer.After(1, CorpseRun) end
		return
	end
	tries = 0
	local stop = { key = "corpse", goal = "Your corpse", name = "Run back and resurrect", point = { map, x, y }, corpse = true }
	local inst, px, py = P:PlayerPos()
	if not P.PlaceStop(stop, inst, px, py, nil, true) then return end
	P.corpse = stop
	P:Send("TARGET_CHANGED"); P:Send("ROUTE_CHANGED")
	if P.RefreshArrow then P:RefreshArrow() end
end
P.CorpseRun = CorpseRun

P:On("PLAYER_ALIVE", function() tries = 0; C_Timer.After(0.5, CorpseRun) end)        -- fires when you release, too
P:On("PLAYER_ENTERING_WORLD", function() tries = 0; C_Timer.After(2, CorpseRun) end)
P:On("ZONE_CHANGED_NEW_AREA", function() if UnitIsGhost("player") then tries = 0; C_Timer.After(1, CorpseRun) end end)
P:On("PLAYER_UNGHOST", function() if P.cdb then P.cdb.deathAt = nil end ClearCorpse() end)
P:Listen("SETTINGS_CHANGED", function() if P.corpse and not S().corpseRun then ClearCorpse() end end)

---------------------------------------------------------------------------
-- Repair
---------------------------------------------------------------------------
local warnedAt = -1e9
local function Durability()
	local low = 1
	for slot = 1, 18 do
		local cur, max = GetInventoryItemDurability(slot)
		if cur and max and max > 0 then low = math.min(low, cur / max) end
	end
	return low
end

local function CheckRepair()
	if not (P.db and S().repairAlert) or UnitIsDeadOrGhost("player") or InCombatLockdown() then return end
	if UnitOnTaxi("player") or GetTime() - warnedAt < 900 then return end
	local d = Durability()
	if d > 0.2 then return end
	warnedAt = GetTime()
	local id, row, yd = P.Find:Nearest("repair")
	P:Ask({
		key = "repair",
		icon = "Interface\\Icons\\Trade_BlackSmithing",
		title = ("Gear at %d%%"):format(floor(d * 100 + 0.5)),
		text = id and ("Nearest repair: |cffffffff%s|r, %s (%d yd)."):format(row[1], P:MapName(row[3]), floor(yd))
			or "Repair soon: broken gear gives no stats.",
		buttons = {
			{ "Not now", function() end },
			id and { "Go repair", function() P.Find:Go("repair") end, true } or nil,
		},
	})
end
P:On("UPDATE_INVENTORY_DURABILITY", function() if P.db then P:Debounce("repair", 2, CheckRepair) end end)

---------------------------------------------------------------------------
-- Full quest log
---------------------------------------------------------------------------
local fullSaid = false
local function MaxQuests()
	return (C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()) or MAX_QUESTLOG_QUESTS or 20
end

local function CheckLog()
	if not P.db or not P.log then return end
	local n = 0
	for _ in pairs(P.log) do n = n + 1 end
	if n < MaxQuests() then fullSaid = false return end
	if fullSaid then return end
	fullSaid = true
	local gray, ids = {}, {}
	local lvl = P.me.level or 1
	for qid in pairs(P.log) do
		local q = P.Q[qid]
		local ql = q and q[P.K.LVL] or 0
		if ql > 0 and ql <= P.GrayAtOrBelow(lvl) then
			gray[#gray + 1] = q[P.K.NAME]; ids[#ids + 1] = qid
		end
	end
	if #gray == 0 then
		P:Toast(("Quest log full (%d)"):format(n), true)
		return
	end
	P:Ask({
		key = "logfull", icon = "Interface\\Icons\\INV_Misc_Note_01",
		title = ("Quest log full (%d)"):format(n),
		text = ("%d gray quest%s give almost no experience now:\n"):format(#gray, #gray == 1 and "" or "s")
			.. P.DIM .. table.concat(gray, ", ", 1, math.min(#gray, 5)) .. "|r",
		buttons = {
			{ "Keep them", function() end },
			{ ("Drop %d"):format(#gray), function() P:AbandonQuests(ids) end, true },
		},
	})
end

-- abandon, one at a time
local function Abandon(qid)
	C_QuestLog.SetSelectedQuest(qid); C_QuestLog.SetAbandonQuest(); C_QuestLog.AbandonQuest()
end
-- all in the same click: the game only lets this happen from one
function P:AbandonQuests(ids)
	local n = 0
	-- from the bottom of the log up, so the ones left keep their places
	table.sort(ids, function(a, b) return ((P.log[a] and P.log[a].index) or 0) > ((P.log[b] and P.log[b].index) or 0) end)
	for _, qid in ipairs(ids) do
		if P.log[qid] and pcall(Abandon, qid) then n = n + 1 end
	end
	P:Toast(("Dropped %d quest%s"):format(n, n == 1 and "" or "s"))
end
P:Listen("QUESTS_CHANGED", function() P:Debounce("logfull", 1, CheckLog) end)

-- (deleting quests from the quest log: QuestDelete.lua)
P.AbandonOne = Abandon

---------------------------------------------------------------------------
-- Hearthstone: where it takes you (learned when you bind it or use it), and
-- a hint when hearthing beats running to your next stop
---------------------------------------------------------------------------
local HEARTH, HEARTH_SPELL, RUN = 6948, 8690, 7      -- yards a second, on foot
local function BindName() return GetBindLocation and GetBindLocation() or nil end
-- you're standing in the place your hearthstone is bound to (its name is the inn's
-- subzone, or for some inns the town's)
local function AtBind()
	local bind = BindName()
	if not bind or bind == "" then return false end
	for _, f in ipairs({ GetSubZoneText, GetMinimapZoneText, GetZoneText, GetRealZoneText }) do
		local ok, t = pcall(f)
		if ok and t == bind then return true end
	end
	return false
end
-- Learn where the hearthstone goes only from where you really are once it's taken you
-- there (or once you walk into that inn): a timer alone can fire before the teleport and
-- save the spot you left, and then Pathway would "hearth" you to where you already stand.
local function Remember(force)
	if not (force or AtBind()) then return false end
	local map = C_Map.GetBestMapForUnit("player")
	local pos = map and C_Map.GetPlayerMapPosition(map, "player")
	if not pos then return false end
	local x, y = pos.x, pos.y
	if pos.GetXY then x, y = pos:GetXY() end
	if not x then return false end
	P.cdb.hearth = { map = map, x = x, y = y, name = BindName() or "your inn" }
	return true
end
local hearthCast = 0
local function TryFor(secs)
	local tries = 0
	local function try()
		tries = tries + 1
		if not Remember() and tries < secs then C_Timer.After(1, try) end
	end
	C_Timer.After(1, try)
end
-- binding it: you're at the innkeeper, so here is right even if the names differ
P:On("HEARTHSTONE_BOUND", function() C_Timer.After(0.5, function() if not Remember() then Remember(true) end end) end)
P:On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spell)
	if unit == "player" and spell == HEARTH_SPELL then hearthCast = GetTime(); TryFor(15) end
end)
P:On("PLAYER_ENTERING_WORLD", function() if GetTime() - hearthCast < 60 then TryFor(10) end end)
-- walking into your inn puts it right, if it was saved somewhere else
local function Check()
	local h = P.cdb and P.cdb.hearth
	if not AtBind() then return end
	if not h or h.name ~= BindName() then Remember(); return end
	local i, hx, hy = P:WorldPos(h.map, h.x, h.y)
	local inst, wx, wy = P:PlayerPos()
	if not (i and inst) or i ~= inst or (hx - wx) ^ 2 + (hy - wy) ^ 2 > 150 * 150 then Remember() end
end
P:On("ZONE_CHANGED_INDOORS", Check)
P:On("ZONE_CHANGED", Check)
P:On("PLAYER_UPDATE_RESTING", Check)
-- you're standing in the inn your hearthstone takes you to
function P:AtBind() return AtBind() end
-- the hearthstone as Pathway knows it, or nil when that's out of date (bound elsewhere since)
function P:HearthKnown()
	local h = self.cdb and self.cdb.hearth
	if not h or AtBind() then return nil end     -- you're in your inn already
	local bind = BindName()
	if bind and bind ~= "" and h.name and h.name ~= bind then return nil end
	return h
end

-- your hearthstone is set within a short walk of here
function P:HearthAt(wx, wy, inst)
	local h = self.cdb and self.cdb.hearth
	if not (h and wx) then return false end
	local i, hx, hy = self:WorldPos(h.map, h.x, h.y)
	return i ~= nil and i == inst and (hx - wx) ^ 2 + (hy - wy) ^ 2 <= 120 * 120
end

---------------------------------------------------------------------------
-- Where to set your hearthstone (Storyline and All quests): at the inn by
-- the bunch of quests you'll be handing in, when your objectives take you
-- away from it. Bound there, you hearth back with everything done instead of
-- running. Pathway says so once per zone, and when your way passes that inn
-- it's a step in your guide (Skip it if you'd rather not).
---------------------------------------------------------------------------
local INN_FLAG, BUNCH, AWAY = 128, 220, 400
local innList
local function Inns()
	if innList then return innList end
	innList = {}
	local me = (P.me and P.me.faction == "Horde") and "H" or "A"
	for id, row in pairs(P.SV or {}) do
		if row[3] and bit.band(row[3], INN_FLAG) ~= 0 and row[5] and row[5]:find(me, 1, true) then
			local pts = row[4]
			for i = 1, #pts, 2 do
				local x, y = P.Unpack(pts[i + 1])
				local inst, wx, wy = P:WorldPos(pts[i], x, y)
				if inst then innList[#innList + 1] = { id = id, name = row[1], map = pts[i], x = x, y = y, inst = inst, wx = wx, wy = wy } end
			end
		end
	end
	return innList
end

local adviceCache = { t = -100 }
function P:HearthAdvice()
	local r = self.route
	if not (r and r.quests and P.db and S().hearthHints ~= false) then return end
	local style = self.RouteStyle and self:RouteStyle(r)
	if style ~= "story" and style ~= "all" then return end
	if self.Item.GetItemCount(HEARTH) == 0 then return end
	local now = GetTime()
	if adviceCache.r == r and now - adviceCache.t < 10 then return adviceCache.inn, adviceCache.n, adviceCache.of end
	adviceCache.r, adviceCache.t, adviceCache.inn = r, now, nil
	local inst, px, py = self:PlayerPos()
	if not inst then return end
	local K = self.K
	-- where you'll hand in, and where the work is
	local hands, works = {}, {}
	for qid in pairs(r.quests) do
		local q = self.Q[qid]
		if q and not self.done[qid] and (self.log[qid] or self:Available(qid)) then
			local ents = {}
			for _, id in ipairs(q[K.EN] or {}) do ents[#ents + 1] = { "N", id } end
			for _, id in ipairs(q[K.EO] or {}) do ents[#ents + 1] = { "O", id } end
			local d, _, _, _, wx, wy = self:Nearest(ents, inst, px, py)
			if d then hands[#hands + 1] = { wx, wy } end
			local e = self.log[qid]
			if e and not e.complete then
				for _, t in ipairs(self:ObjectiveTargets(qid)) do
					if t.ents then
						local od, _, _, _, ox, oy = self:Nearest(t.ents, inst, px, py)
						if od then works[#works + 1] = { ox, oy } break end
					end
				end
			end
		end
	end
	if #hands < 3 then return end
	local best, bn
	for _, inn in ipairs(Inns()) do
		if inn.inst == inst then
			local n = 0
			for _, h in ipairs(hands) do if (h[1] - inn.wx) ^ 2 + (h[2] - inn.wy) ^ 2 <= BUNCH * BUNCH then n = n + 1 end end
			if n >= 3 and (not bn or n > bn) then best, bn = inn, n end
		end
	end
	if not best or bn < #hands * 0.4 then return end
	if self:HearthAt(best.wx, best.wy, best.inst) then return end
	-- only worth it when the work takes you away from there
	local away = 0
	for _, w in ipairs(works) do if (w[1] - best.wx) ^ 2 + (w[2] - best.wy) ^ 2 > AWAY * AWAY then away = away + 1 end end
	if away < 2 and #works > 0 then return end
	adviceCache.inn, adviceCache.n, adviceCache.of = best, bn, #hands
	return best, bn, #hands
end

-- told once per zone; a step when your way passes the inn
function P:MaybeAddHearthStep()
	local r = self.route
	if not r or r.single or r.detour then return end
	local inn, n, of = self:HearthAdvice()
	if not inn then return end
	local key = "bind" .. inn.id
	local told = self.cdb.hearthTold or {}
	self.cdb.hearthTold = told
	local where = self:MapName(inn.map)
	if not told[key] then
		told[key] = true
		self:Notify({ key = "hearth-advice", kind = "info", icon = "Interface\\Icons\\INV_Misc_Rune_01",
			text = ("Set your hearthstone with %s in %s"):format(inn.name, where),
			sub = ("%d of your %d hand-ins are there: hearth back once your objectives are done. Pathway reminds you as you pass the inn."):format(n, of) })
		self:Toast(("Tip: set your hearthstone in %s, %d hand-ins are there"):format(where, n))
	end
	for _, s in ipairs(r.stops) do if s.key == key then return end end
	if r.skipped and r.skipped[key] then return end
	-- on your way: next to one of the guide's next stops, or a short detour on the
	-- way to the next one (close to you but the other way doesn't count)
	local inst, px, py = self:PlayerPos()
	local first = r.stops[1]
	if not self:OnTheWay(inn.inst, inn.wx, inn.wy, 150, 120) then return end
	local stop = { key = key, goal = "Set your hearthstone here", name = inn.name, ents = { { "N", inn.id } }, bind = true, reach = 6,
		tip = ("%d of your hand-ins are around here: with your hearthstone set, you hearth back once the objectives are done."):format(n) }
	if not self.PlaceStop(stop, inst, px, py, nil, true) then return end
	local at = (first and (first.travel or first.trip)) and 2 or 1
	table.insert(r.stops, at, stop)
	r.total = (r.total or 0) + 1
end
P:On("HEARTHSTONE_BOUND", function() C_Timer.After(1, function() if P.route then P:RefreshRoute() end end) end)

local hintCache = { key = nil, t = 0 }
function P:HearthHint(s)
	if not (P.db and S().hearthHints and s and s.wx and P:HearthKnown()) or s.travel then return end
	local now = GetTime()
	if hintCache.key == s.key and now - hintCache.t < 2 then return hintCache.v end
	hintCache.key, hintCache.t, hintCache.v = s.key, now, nil
	if P.Item.GetItemCount(HEARTH) == 0 then return end
	local getCd = C_Container and C_Container.GetItemCooldown or GetItemCooldown
	local start, dur = getCd(HEARTH)
	if start and dur and dur > 0 and start + dur - now > 15 then return end
	local h = P:HearthKnown()
	local hi, hx, hy = P:WorldPos(h.map, h.x, h.y)
	local t = P:MapXform(s.map)
	local inst, px, py = P:PlayerPos()
	if not (hi and t and inst) or hi ~= t[1] then return end
	local fromHearth = math.sqrt((hx - s.wx) ^ 2 + (hy - s.wy) ^ 2)
	local fromMe = inst == t[1] and math.sqrt((px - s.wx) ^ 2 + (py - s.wy) ^ 2) or math.huge
	local saves = fromMe / RUN - (10 + fromHearth / RUN)
	if fromMe ~= math.huge and saves < 120 then return end
	if fromHearth > 600 then return end
	hintCache.v = { item = HEARTH, saves = saves,
		text = ("Hearth to %s%s"):format(h.name, fromMe ~= math.huge and (": saves ~%d min"):format(floor(saves / 60 + 0.5)) or "") }
	return hintCache.v
end

---------------------------------------------------------------------------
-- Dungeons: walking in, which of its quests you have, and which you missed
---------------------------------------------------------------------------
local seenDungeon = {}
P:On("PLAYER_ENTERING_WORLD", function()
	C_Timer.After(3, function()
		if not (P.db and S().dungeonHelp and P.Cat) then return end
		local inInst, kind = IsInInstance()
		if not inInst or kind ~= "party" then return end
		local name = GetInstanceInfo()
		if not name or seenDungeon[name] then return end
		seenDungeon[name] = true
		P.Cat:Build()
		local d
		for _, b in ipairs(P.Cat.dungeonList) do if b.name:lower() == name:lower() then d = b break end end
		if not d then return end
		local have, missed = {}, {}
		for _, qid in ipairs(d.quests) do
			if P.log[qid] then have[#have + 1] = P.Q[qid][P.K.NAME]
			elseif P:Available(qid) then missed[#missed + 1] = P.Q[qid][P.K.NAME] end
		end
		if #have == 0 and #missed == 0 then return end
		local text = ("%d quest%s here in your log"):format(#have, #have == 1 and "" or "s")
		if #have > 0 then text = text .. ": |cffffffff" .. table.concat(have, ", ", 1, math.min(#have, 4)) .. "|r" end
		if #missed > 0 then
			text = text .. ("\n%d you could have brought: "):format(#missed) .. P.DIM .. table.concat(missed, ", ", 1, math.min(#missed, 4)) .. "|r"
		end
		P:Ask({ key = "dungeon", icon = "Interface\\Icons\\INV_Misc_Key_03", title = name, text = text,
			buttons = { { "Got it", function() end, true },
				#missed > 0 and { "Show in journal", function() P:ToggleJournal("dungeons"); P.Journal.group = d; P.Journal:Refresh() end } or nil } })
	end)
end)

---------------------------------------------------------------------------
-- Leaving town: anything left to do there? Enough food, water and ammo?
-- A town is wherever you're resting (inns, towns, cities).
---------------------------------------------------------------------------
local town                      -- { inst, x, y, n, name } while resting: the middle of where you've been
local lastLeave = -1e9

local function Sample()
	local inst, px, py = P:PlayerPos()
	if not inst then return end
	if not town or town.inst ~= inst then
		town = { inst = inst, x = px, y = py, n = 1, name = (GetSubZoneText and GetSubZoneText() ~= "" and GetSubZoneText()) or GetZoneText() }
	elseif town.n < 50 then
		town.n = town.n + 1
		town.x = town.x + (px - town.x) / town.n
		town.y = town.y + (py - town.y) / town.n
	end
end
-- only while one of the leaving-town checks is on
C_Timer.NewTicker(3, function() if P.db and (S().townCheck or S().supplyCheck) and IsResting() then Sample() end end)

local function TownStops()
	if not town then return end
	local list = P:Stops({ pickup = true, turnin = true })
	local quests, pick, turn, names = {}, 0, 0, {}
	for _, s in ipairs(list) do
		if s.wx and (s.wx - town.x) ^ 2 + (s.wy - town.y) ^ 2 < 260 * 260 then
			for _, qid in ipairs(s.turn or {}) do if not quests[qid] then quests[qid] = true; turn = turn + 1; names[#names + 1] = P.Q[qid][P.K.NAME] end end
			for _, qid in ipairs(s.pick or {}) do if not quests[qid] then quests[qid] = true; pick = pick + 1; names[#names + 1] = P.Q[qid][P.K.NAME] end end
		end
	end
	if pick + turn == 0 then return end
	return quests, pick, turn, names
end

local FOOD_CLASS, FOOD_SUB, PROJECTILE = 0, 5, 6
local function Supplies()
	local food = 0
	local info = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
	local C = P.Container
	for bag = 0, 4 do
		for slot = 1, (C.GetContainerNumSlots(bag) or 0) do
			local it = C.GetContainerItemInfo(bag, slot)
			if it and it.itemID then
				local _, _, _, _, _, classID, subID = info(it.itemID)
				if classID == FOOD_CLASS and subID == FOOD_SUB then food = food + (it.stackCount or 1) end
			end
		end
	end
	local ammo
	if select(2, UnitClass("player")) == "HUNTER" and GetInventoryItemID("player", 0) ~= nil then
		ammo = GetInventoryItemCount("player", 0) or 0
	elseif select(2, UnitClass("player")) == "HUNTER" and UnitLevel("player") >= 2 then
		ammo = 0
	end
	return food, ammo
end

local function LeftTown()
	if not P.db or not town then return end
	if UnitOnTaxi("player") or InCombatLockdown() or UnitIsDeadOrGhost("player") or IsInInstance() then return end
	if GetTime() - lastLeave < 120 then return end
	lastLeave = GetTime()
	local where = town.name or "town"
	-- things to do here
	if S().townCheck then
		local quests, pick, turn, names = TownStops()
		if quests then
			local parts = {}
			if turn > 0 then parts[#parts + 1] = turn .. " to turn in" end
			if pick > 0 then parts[#parts + 1] = pick .. " to pick up" end
			P:Ask({
				key = "town", icon = "Interface\\Icons\\INV_Misc_Map_01",
				title = "Leaving " .. where,
				text = table.concat(parts, " and ") .. " here:\n" .. P.DIM .. table.concat(names, ", ", 1, math.min(#names, 4)) .. "|r",
				buttons = {
					{ "Keep going", function() end },
					{ "Do them first", function()
						P:StartRoute("guide", { quests = quests, title = "Before leaving " .. where, detour = true })
					end, true },
				},
			})
		end
	end
	-- food, water, ammo
	if S().supplyCheck and UnitLevel("player") >= 6 then
		local food, ammo = Supplies()
		local lowAmmo = ammo and ammo < 200
		if food < 5 or lowAmmo then
			local kind = lowAmmo and "ammo" or "food"
			local id, row, yd = P.Find:Nearest(kind)
			local what = {}
			if food < 5 then what[#what + 1] = ("%d food and drink"):format(food) end
			if lowAmmo then what[#what + 1] = ("%d ammo"):format(ammo) end
			P:Ask({
				key = "supplies", icon = lowAmmo and "Interface\\Icons\\INV_Ammo_Arrow_02" or "Interface\\Icons\\INV_Misc_Food_15",
				title = "Running low",
				text = "You have " .. table.concat(what, " and ") .. "." ..
					(id and ("\nNearest: |cffffffff%s|r, %d yd."):format(row[1], math.floor(yd)) or ""),
				buttons = {
					{ "I'm fine", function() end },
					id and { "Stock up", function() P.Find:Go(kind) end, true } or nil,
				},
			})
		end
	end
end

local wasResting
P:On("PLAYER_UPDATE_RESTING", function()
	local now = IsResting()
	if now then Sample()
	elseif wasResting then C_Timer.After(1.5, function() if not IsResting() then LeftTown(); town = nil end end) end
	wasResting = now
end)
P:On("PLAYER_ENTERING_WORLD", function() wasResting = IsResting(); if wasResting then town = nil; Sample() end end)

---------------------------------------------------------------------------
-- Map pins: drop one (on the world map or the minimap) and Pathway takes you
-- there, by the fastest way, then back to where your guide left off
---------------------------------------------------------------------------
local pinRoute, pinPoint
local function Pin()
	local wp = C_Map and C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
	if not wp or not wp.uiMapID or not wp.position then return end
	local x, y = wp.position.x, wp.position.y
	if wp.position.GetXY then x, y = wp.position:GetXY() end
	return wp.uiMapID, x, y
end

P:On("USER_WAYPOINT_UPDATED", function()
	if not (P.db and S().followPins) then return end
	local map, x, y = Pin()
	if map then
		if pinPoint and pinPoint[1] == map and math.abs(pinPoint[2] - x) < 0.001 and math.abs(pinPoint[3] - y) < 0.001 then return end
		pinPoint = { map, x, y }
		local ok = P:StartRoute("next", { single = { key = "pin", goal = "Your map pin", name = P:MapName(map), point = pinPoint, far = true, reach = 20 },
			title = "Map pin", quiet = true })
		if ok then
			pinRoute = P.route
			P:Toast("Following your map pin" .. (P.route.paused and ": your guide picks up after" or ""))
		end
	elseif pinRoute then
		-- you removed the pin: back to the guide
		pinPoint = nil
		if P.route == pinRoute then P:StopRoute(true) end
		pinRoute = nil
	end
end)

-- arrived: the pin has done its job
P:Listen("ROUTE_CHANGED", function()
	if pinRoute and P.route ~= pinRoute then
		pinRoute, pinPoint = nil, nil
		if C_Map and C_Map.ClearUserWaypoint and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() then
			C_Map.ClearUserWaypoint()
		end
	end
end)
end part() end
-- ==================== Pace.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Level pace and your session
     · Experience per hour (from the last 20 minutes) and how long until you
       level, on the guide window's bottom line.
     · Hover that line for the session: time played, quests done, experience,
       gold and flight paths found.
     · A ding toast says how long the level took.
     · When a zone runs dry for you, Pathway offers the next one. ]]

local ADDON, P = __addon, __ns
local floor, max, min = math.floor, math.max, math.min

local function S() return P.db.settings end

local session = { start = GetTime(), xp = 0, quests = 0, flights = 0, levelAt = GetTime(), levelQuests = 0 }
P.session = session
local samples = {}             -- { time, total xp gained }
local lastXP, lastMax, lastLevel

local function Short(n)
	if n >= 10000 then return ("%.0fk"):format(n / 1000) end
	if n >= 1000 then return ("%.1fk"):format(n / 1000) end
	return tostring(floor(n))
end
local function Clock(secs)
	secs = floor(secs + 0.5)
	if secs >= 3600 then return ("%dh %02dm"):format(floor(secs / 3600), floor(secs % 3600 / 60)) end
	return ("%d min"):format(max(1, floor(secs / 60 + 0.5)))
end

local function XPUpdate()
	local cur, mx, lvl = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
	if lastXP then
		local gain
		if lvl == lastLevel then gain = cur - lastXP else gain = (lastMax - lastXP) + cur end
		if gain > 0 then
			session.xp = session.xp + gain
			samples[#samples + 1] = { GetTime(), session.xp }
		end
	end
	lastXP, lastMax, lastLevel = cur, mx, lvl
	-- forget samples older than 20 minutes (keep one as the window's start)
	local cut = GetTime() - 1200
	while #samples > 2 and samples[2][1] < cut do table.remove(samples, 1) end
end

-- experience per hour, or nil until there's enough to go on
function P:XPRate()
	if #samples < 2 then return end
	local a, b = samples[1], samples[#samples]
	local span = max(GetTime() - a[1], b[1] - a[1])
	if span < 120 then return end
	return (b[2] - a[2]) / span * 3600
end

function P:PaceLine()
	if not (P.db and S().levelPace) then return end
	local lvl = UnitLevel("player")
	if GetMaxPlayerLevel and lvl >= GetMaxPlayerLevel() then return end
	local cur, mx = UnitXP("player"), UnitXPMax("player")
	if not mx or mx == 0 then return end
	local pct = floor(cur / mx * 100)
	local rate = self:XPRate()
	local line = P.DIM .. ("Level %d  ·  %d%%"):format(lvl, pct)
	if rate and rate > 0 then
		line = line .. ("  ·  %s xp/h  ·  |r|cffffffff%s|r%s to %d"):format(Short(rate), Clock((mx - cur) / rate * 3600), P.DIM, lvl + 1)
	end
	local rested = GetXPExhaustion and GetXPExhaustion()
	if rested and rested > 0 then line = line .. "  ·  |cff6fa8ff" .. Short(rested) .. " rested" end
	return line .. "|r"
end

function P:SessionTooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	GameTooltip:SetText("This session", 1, 1, 1)
	local played = GetTime() - session.start
	local function row(l, r) GameTooltip:AddDoubleLine(l, r, 0.7, 0.75, 0.8, 1, 1, 1) end
	row("Played", Clock(played))
	row("Quests done", session.quests)
	row("Experience", Short(session.xp))
	local rate = self:XPRate()
	if rate then row("Pace, last 20 min", Short(rate) .. " xp/h") end
	local gold = GetMoney() - (session.money or GetMoney())
	row("Gold", (gold < 0 and "-" or "") .. GetMoneyString(math.abs(gold), true))
	if session.flights > 0 then row("Flight paths found", session.flights) end
	local lvlTime = GetTime() - session.levelAt
	row("This level so far", Clock(lvlTime))
	-- Fastest XP's score: experience an hour, set by set
	local log = self.FastLog and self:FastLog() or {}
	if log[1] then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Fastest XP sets", 1, 0.82, 0.3)
		for i = 1, math.min(3, #log) do
			local e = log[i]
			row((self:MapName(e.zone) or "Set") .. ("  |cff8a8f99%d min|r"):format(e.mins), Short(e.xph) .. " xp/h")
		end
	end
	GameTooltip:Show()
end

P:On("PLAYER_XP_UPDATE", XPUpdate)
P:On("PLAYER_ENTERING_WORLD", function()
	if not session.money then session.money = GetMoney() end
	if not lastXP then XPUpdate() end
end)
P:On("QUEST_TURNED_IN", function() session.quests = session.quests + 1; session.levelQuests = session.levelQuests + 1 end)
P:Listen("FLIGHTS_CHANGED", function() session.flights = session.flights + 1 end)
P:On("PLAYER_LEVEL_UP", function(_, level)
	local took = GetTime() - session.levelAt
	if took > 60 then
		P:Toast(("Level %d!  That one took %s and %d quest%s"):format(level, Clock(took), session.levelQuests,
			session.levelQuests == 1 and "" or "s"), true)
	end
	session.levelAt, session.levelQuests = GetTime(), 0
end)

---------------------------------------------------------------------------
-- When a zone's guide is done for you: on to the next zone
---------------------------------------------------------------------------
P:Listen("GUIDE_DONE", function(r)
	if not (P.db and S().nextZoneTip ~= false and P.Cat) or not r then return end
	local here = r.map or (r.guide and tonumber(r.guide:match(":(%d+)$")))
	if not here then return end
	for _, z in ipairs(P.Cat:ForYou(4)) do
		if z.map ~= here then
			local _, _, f = P.Cat:SetProgress(next(z.story) and z.story or {})
			P:Ask({
				key = "nextzone", icon = "Interface\\Icons\\INV_Misc_Map_01",
				title = "Next: " .. z.name,
				text = ("You're about done in %s for now.\n%s is levels %d-%d%s."):format(P:MapName(here), z.name, z.lo, z.hi,
					next(z.story) and (", main story " .. floor(f * 100 + 0.5) .. "% done") or ""),
				buttons = {
					{ "Not now", function() end },
					{ "Open journal", function() P:ShowZoneInJournal(z.map) end },
					{ "Load its story", function() if not P:LoadGuide("story:" .. z.map) then P:LoadGuide("zone:" .. z.map) end end, true },
				},
			})
			return
		end
	end
end)
end part() end
-- ==================== Group.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Playing together
     Group members running Pathway tell each other which quests they have, so
     the guide window and the journal say who's on the same quest. Optionally
     shares each quest you pick up with your group. ]]

local ADDON, P = __addon, __ns
local PREFIX = "PATHWAY1"

local function S() return P.db.settings end
local party = {}              -- [name] = { [questID] = true }

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
elseif RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end
local Send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

local function Channel()
	if IsInRaid() then return "RAID" end
	if IsInGroup() then return "PARTY" end
end

-- your quest log, in a few short messages
local function Broadcast()
	local ch = Channel()
	if not (ch and P.log and Send) then return end
	local ids = {}
	for qid in pairs(P.log) do ids[#ids + 1] = qid end
	table.sort(ids)
	local chunk, first = {}, true
	local function flush()
		Send(PREFIX, (first and "Q:" or "Q+:") .. table.concat(chunk, ","), ch)
		first, chunk = false, {}
	end
	for _, id in ipairs(ids) do
		chunk[#chunk + 1] = id
		if #chunk >= 30 then flush() end
	end
	if #chunk > 0 or first then flush() end
end

P:On("CHAT_MSG_ADDON", function(_, prefix, msg, _, sender)
	if prefix ~= PREFIX or not msg then return end
	local name = Ambiguate and Ambiguate(sender, "short") or sender:match("^[^-]+")
	if name == UnitName("player") then return end
	local kind, body = msg:match("^(Q%+?):(.*)$")
	if kind == "Q" then party[name] = {} elseif kind == "Q+" then party[name] = party[name] or {} else
		if msg == "HELLO" then P:Debounce("pwsync", 1, Broadcast) end
		return
	end
	for id in body:gmatch("%d+") do party[name][tonumber(id)] = true end
	P:Send("PARTY_CHANGED")
end)

P:On("GROUP_ROSTER_UPDATE", function()
	for name in pairs(party) do if not (UnitInParty(name) or UnitInRaid(name)) then party[name] = nil end end
	local ch = Channel()
	if ch and Send then
		Send(PREFIX, "HELLO", ch)
		P:Debounce("pwsync", 2, Broadcast)
	end
end)
P:Listen("QUESTS_CHANGED", function() if Channel() then P:Debounce("pwsync", 3, Broadcast) end end)

-- who else in your group has this quest: "Ana, Rook" or nil
function P:PartyOn(qid)
	local names = {}
	for name, set in pairs(party) do if set[qid] then names[#names + 1] = name end end
	if #names == 0 then return end
	table.sort(names)
	return table.concat(names, ", ")
end

-- share each quest you pick up
P:On("QUEST_ACCEPTED", function(_, a, b)
	if not (P.db and S().shareQuests and IsInGroup()) then return end
	local qid = b or a
	C_Timer.After(0.5, function()
		local index = C_QuestLog.GetLogIndexForQuestID(qid)
		if index and C_QuestLog.IsPushableQuest(qid) then QuestLogPushQuest(index) end
	end)
end)
end part() end
-- ==================== PvP.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Players
     · Hover a player: a card in their faction's colors (Alliance blue, Horde
       red) in place of the usual tooltip, with everything it said plus their
       gear level, spec, PvP rank and honor, and your odds in a fight. Move off
       and it stays a moment so you can read it, then fades away.
     · Enemy healers get a red cross over their heads, spotted from the heals
       they cast (or their talents), whether or not you've clicked them.
     · Target an enemy healer (or any enemy player, if you like) and you hear a ding.
     The odds are an estimate from level, gear, health, talents and class. ]]

local ADDON, P = __addon, __ns
local floor, max, min, abs, log = math.floor, math.max, math.min, math.abs, math.log
local WHITE = "Interface\\Buttons\\WHITE8x8"

local function S() return P.db.settings end
-- this client hides some details of players outside your group ("secret values"):
-- they can be shown, but not compared or added up. N() gives nil for those.
local isSecret = _G.issecretvalue or function() return false end
local function N(v) if v == nil or isSecret(v) then return nil end return v end
local function On() return P.db and S().pvpCard end

local FACTION = {
	Alliance = { 0.18, 0.42, 0.95, icon = "Interface\\TargetingFrame\\UI-PVP-Alliance", name = "Alliance" },
	Horde    = { 0.88, 0.16, 0.14, icon = "Interface\\TargetingFrame\\UI-PVP-Horde", name = "Horde" },
}

---------------------------------------------------------------------------
-- What we know about players, by GUID (inspect results, healers seen)
---------------------------------------------------------------------------
local info = {}                 -- [guid] = { ilvl, spec, points, healer, honor, at, seen }
local function Info(guid)
	local i = info[guid]
	if not i then i = {}; info[guid] = i end
	i.seen = GetTime()
	return i
end

local HEAL_SPECS = { Holy = true, Discipline = true, Restoration = true }
-- talent spells only a healer has, and the everyday heals of each healing class
local STRONG = { 20473, 18562, 16190, 10060, 724, 20216, 17116, 16188 }   -- Holy Shock, Swiftmend, Mana Tide, Power Infusion, Lightwell, Divine Favor, Nature's Swiftness (druid, shaman)
local HEALS = { 2054, 2060, 2061, 139, 596, 2050, 5185, 8936, 774, 740, 331, 8004, 1064, 635, 19750 }
local strongNames, healNames = {}, {}
local function Names()
	if next(healNames) then return end
	local get = C_Spell and C_Spell.GetSpellName or function(id) return (GetSpellInfo(id)) end
	for _, id in ipairs(STRONG) do local n = get(id); if n then strongNames[n] = true end end
	for _, id in ipairs(HEALS) do local n = get(id); if n then healNames[n] = true end end
end

---------------------------------------------------------------------------
-- Your gear level, and theirs after an inspect
---------------------------------------------------------------------------
local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local function ItemLevel(unit)
	local sum, n = 0, 0
	for _, slot in ipairs(SLOTS) do
		local link = GetInventoryItemLink(unit, slot)
		if link then
			local lvl = (C_Item and C_Item.GetDetailedItemLevelInfo and C_Item.GetDetailedItemLevelInfo(link))
				or (GetDetailedItemLevelInfo and GetDetailedItemLevelInfo(link)) or select(4, GetItemInfo(link))
			if lvl and lvl > 0 then sum, n = sum + lvl, n + 1 end
		end
	end
	if n < 5 then return end
	return floor(sum / n + 0.5)
end
local myIlvl, myIlvlAt = nil, 0
local function MyIlvl()
	if GetTime() - myIlvlAt > 10 then myIlvl, myIlvlAt = ItemLevel("player"), GetTime() end
	return myIlvl
end

-- their specialization trees and the points in each (Forever's C_SpecializationInfo)
local function TalentTabs(unit)
	local out, total = {}, 0
	local SI = C_SpecializationInfo
	local classID = select(3, UnitClass(unit))
	local n = (SI.GetNumSpecializationsForClassID and classID and SI.GetNumSpecializationsForClassID(classID)) or 3
	for i = 1, n do
		local ok, _, name, _, _, _, _, pts = pcall(SI.GetSpecializationInfo, i, true, false, unit, nil, nil, classID)
		if not (ok and type(pts) == "number") then pts = 0 end
		out[i] = { name = ok and name or "?", points = pts }
		total = total + pts
	end
	return out, total
end

-- ask the server about them (in inspect range only); answers come in INSPECT_READY.
-- Asking can fail quietly (too soon after the last one, their gear not loaded
-- yet, you looked away), so Pathway keeps trying for a few seconds.
local inspecting, lastInspect = nil, 0
local UNITS = { "mouseover", "target", "focus", "party1", "party2", "party3", "party4" }
local function UnitFor(guid, first)
	if first and N(UnitGUID(first)) == guid then return first end
	for _, u in ipairs(UNITS) do if N(UnitGUID(u)) == guid then return u end end
end
local Inspect
local function Again(guid, delay)
	C_Timer.After(delay, function()
		local i = info[guid]
		if i and i.ilvl then return end
		local unit = UnitFor(guid)
		if unit then pcall(Inspect, unit) end
	end)
end
function Inspect(unit)
	if not N(UnitIsPlayer(unit)) or UnitIsUnit(unit, "player") then return end
	if InCombatLockdown() or (InspectFrame and InspectFrame:IsShown()) then return end
	if InCombatLockdown() or not (CanInspect and N(CanInspect(unit))) or not N(CheckInteractDistance(unit, 1)) then return end
	local guid = N(UnitGUID(unit))
	if not guid then return end
	local i = Info(guid)
	if i.at and GetTime() - i.at < 300 then return end         -- we have their gear: good for five minutes
	if (i.tries or 0) >= 6 and GetTime() - (i.tried or 0) < 60 then return end   -- they aren't answering: rest a minute
	if (i.tries or 0) >= 6 then i.tries = 0 end
	local wait = 1.5 - (GetTime() - lastInspect)
	if wait > 0 then Again(guid, wait + 0.1) return end          -- too soon after the last one: ask when it's allowed
	lastInspect = GetTime()
	i.tries, i.tried = (i.tries or 0) + 1, GetTime()
	inspecting = { guid = guid, unit = unit }
	NotifyInspect(unit)
	Again(guid, 2.5)                                             -- no answer, or gear not loaded: once more
end

-- their gear, read now and again a moment later (item details can arrive late)
local function ReadGear(guid, pass)
	local i = Info(guid)
	local unit = UnitFor(guid, inspecting and inspecting.unit)
	local ilvl = unit and ItemLevel(unit)
	if ilvl then
		i.ilvl, i.at = ilvl, GetTime()
		P:Send("PLAYER_INFO", guid)
	elseif (pass or 1) < 4 then
		C_Timer.After(0.4, function() ReadGear(guid, (pass or 1) + 1) end)
	end
end

P:On("INSPECT_READY", function(_, guid)
	local q = inspecting
	guid = N(guid) or (q and q.guid)
	if not q or guid ~= q.guid then return end
	local unit = UnitFor(guid, q.unit)
	if not unit then return end                                  -- you looked away: the next look asks again
	local i = Info(guid)
	ReadGear(guid)
	local okT, tabs, total = pcall(TalentTabs, unit)
	if not okT then tabs, total = {}, 0 end
	if total > 0 then
		local best = tabs[1]
		for _, t in ipairs(tabs) do if t.points > best.points then best = t end end
		local pts = {}
		for _, t in ipairs(tabs) do pts[#pts + 1] = t.points end
		i.spec, i.points = best.name, table.concat(pts, "/")
		if HEAL_SPECS[best.name] and N(UnitIsEnemy("player", unit)) and best.points >= 21 then i.healer = true end
	end
	P:Send("PLAYER_INFO", guid)
end)

---------------------------------------------------------------------------
-- Healers: seen healing others, or with a healing talent
---------------------------------------------------------------------------
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x400
local heals = {}                -- [guid] = { count, since }
local healerNames = {}          -- [name] = time, for nameplates without a GUID handy

-- A city or a battleground shows you thousands of players in an evening: forget the ones
-- not seen for half an hour, so none of this grows for as long as you play.
local function Forget()
	local now = GetTime()
	for g, i in pairs(info) do if now - (i.seen or 0) > 1800 then info[g] = nil end end
	for g, h in pairs(heals) do if now - h.since > 120 then heals[g] = nil end end
	for n, t in pairs(healerNames) do if now - t > 1800 then healerNames[n] = nil end end
end
P:On("PLAYER_ENTERING_WORLD", Forget)
C_Timer.NewTicker(300, Forget)

local function MarkHealer(guid, name)
	local i = Info(guid)
	if i.healer then return end
	i.healer = true
	if name and not isSecret(name) then healerNames[name:match("^[^-]+")] = GetTime() end
	P:Send("HEALER_FOUND", guid)
end

local cleu = CreateFrame("Frame")
local function OnCombatLog()
	local _, ev, _, src, srcName, flags, _, dst, _, _, _, _, spell = CombatLogGetCurrentEventInfo()
	flags, src, spell = N(flags), N(src), N(spell)
	if not flags or not src or bit.band(flags, PLAYER) == 0 or bit.band(flags, HOSTILE) == 0 then return end
	if ev == "SPELL_HEAL" or ev == "SPELL_CAST_SUCCESS" or ev == "SPELL_AURA_APPLIED" then
		if strongNames[spell] then MarkHealer(src, srcName) return end
		if ev == "SPELL_HEAL" and healNames[spell] and dst ~= src then
			local h = heals[src]
			local now = GetTime()
			if not h or now - h.since > 60 then h = { count = 0, since = now }; heals[src] = h end
			h.count = h.count + 1
			if h.count >= 3 then MarkHealer(src, N(srcName)) end
		end
	end
end
cleu:SetScript("OnEvent", function() pcall(OnCombatLog) end)

-- casts seen on enemy nameplates count too (where the combat log isn't open to add-ons)
---------------------------------------------------------------------------
-- Specs, from what players cast and wear: talent spells and forms only one
-- tree has. No inspect needed, works at any range you can see them.
---------------------------------------------------------------------------
local SIGNS = {   -- spell → class tree; healer trees marked
	WARRIOR = { [12294] = "Arms", [12292] = "Arms", [23881] = "Fury", [12328] = "Fury", [23922] = "Protection", [12809] = "Protection", [12975] = "Protection" },
	PALADIN = { [20473] = "Holy", [20216] = "Holy", [20911] = "Protection", [20925] = "Protection", [20375] = "Retribution", [20066] = "Retribution" },
	HUNTER  = { [19574] = "Beast Mastery", [19577] = "Beast Mastery", [19434] = "Marksmanship", [19503] = "Marksmanship", [19506] = "Marksmanship",
		[19386] = "Survival", [19306] = "Survival", [19263] = "Survival" },
	ROGUE   = { [14177] = "Assassination", [13750] = "Combat", [13877] = "Combat", [14185] = "Subtlety", [14183] = "Subtlety", [16511] = "Subtlety" },
	PRIEST  = { [10060] = "Discipline", [14751] = "Discipline", [724] = "Holy", [20711] = "Holy", [15473] = "Shadow", [15286] = "Shadow",
		[15407] = "Shadow", [15487] = "Shadow" },
	SHAMAN  = { [16166] = "Elemental", [17364] = "Enhancement", [16190] = "Restoration", [16188] = "Restoration" },
	MAGE    = { [12043] = "Arcane", [12042] = "Arcane", [11129] = "Fire", [11113] = "Fire", [11426] = "Frost", [12472] = "Frost" },
	WARLOCK = { [18265] = "Affliction", [18220] = "Affliction", [18223] = "Affliction", [19028] = "Demonology", [18708] = "Demonology",
		[17962] = "Destruction", [17877] = "Destruction" },
	DRUID   = { [24858] = "Balance", [5570] = "Balance", [16979] = "Feral", [18562] = "Restoration", [17116] = "Restoration" },
}
local HEALER_TREE = { PRIEST = { Discipline = true, Holy = true }, PALADIN = { Holy = true }, SHAMAN = { Restoration = true }, DRUID = { Restoration = true } }
local signByName = {}           -- [spell name] = { class, tree }
local function Signs()
	if next(signByName) then return end
	local get = C_Spell and C_Spell.GetSpellName or function(x) return (GetSpellInfo(x)) end
	for class, list in pairs(SIGNS) do
		for id, tree in pairs(list) do
			local n = get(id)
			if n then signByName[n] = { class, tree } end
		end
	end
end

local function Saw(guid, unit, spellName)
	local sign = signByName[spellName]
	if not sign then return end
	local class = N(select(2, UnitClass(unit)))
	if class and class ~= sign[1] then return end
	local i = Info(guid)
	if i.points then return end                    -- talents from an inspect beat a guess
	if i.seen ~= sign[2] then
		i.seen, i.seenBy = sign[2], spellName
		if HEALER_TREE[sign[1]] and HEALER_TREE[sign[1]][sign[2]] and N(UnitIsEnemy("player", unit)) then MarkHealer(guid, N(UnitName(unit))) end
		P:Send("PLAYER_INFO", guid)
	end
end

-- buffs and forms on the player you're looking at
local function ReadAuras(unit, guid)
	Signs()
	for idx = 1, 40 do
		local name
		if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
			local a = C_UnitAuras.GetAuraDataByIndex(unit, idx, "HELPFUL")
			if not a then break end
			name = N(a.name)
		elseif UnitAura then
			name = N((UnitAura(unit, idx, "HELPFUL")))
			if name == nil and idx > 1 then break end
		end
		if name and signByName[name] then Saw(guid, unit, name) end
	end
end

local function NameplateCast(unit, spellID)
	if not P.db or type(unit) ~= "string" then return end
	if not (S().pvpCard or S().healerMarks) then return end      -- cards and healer marks both off: nothing to watch for
	if not (unit:find("^nameplate") or unit == "target" or unit == "mouseover" or unit == "focus") then return end
	if not N(UnitIsPlayer(unit)) or N(UnitIsUnit(unit, "player")) then return end
	local id = N(spellID)
	local guid = N(UnitGUID(unit))
	if not (id and guid) then return end
	local get = C_Spell and C_Spell.GetSpellName or function(x) return (GetSpellInfo(x)) end
	local name = get(id)
	if not name then return end
	Signs()
	Saw(guid, unit, name)
	if not (S().healerMarks and N(UnitIsEnemy("player", unit))) then return end
	if strongNames[name] then MarkHealer(guid, N(UnitName(unit))) return end
	if healNames[name] then
		local h = heals[guid]
		local now = GetTime()
		if not h or now - h.since > 60 then h = { count = 0, since = now }; heals[guid] = h end
		h.count = h.count + 1
		if h.count >= 3 then MarkHealer(guid, N(UnitName(unit))) end
	end
end
P:On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID) pcall(NameplateCast, unit, spellID) end)
-- The combat log is closed to add-ons on this client (registering for it is
-- blocked), so healers are spotted from nameplate casts and talents instead.
local function WatchCombatLog()
	Names()
end

function P:IsHealer(unit)
	local guid = N(UnitGUID(unit))
	if guid and info[guid] and info[guid].healer then return true end
	local name = N(UnitName(unit))
	return name and healerNames[name] and GetTime() - healerNames[name] < 1800 or false
end

---------------------------------------------------------------------------
-- The red cross over enemy healers' nameplates
---------------------------------------------------------------------------
local crosses = {}
local function Cross(plate)
	local c = crosses[plate]
	if c then return c end
	c = CreateFrame("Frame", nil, plate)
	c:SetSize(22, 22)
	c:SetPoint("BOTTOM", plate, "TOP", 0, 2)
	c:SetFrameStrata("HIGH")
	local glow = c:CreateTexture(nil, "BACKGROUND")
	glow:SetTexture(P.MEDIA .. "Glow"); glow:SetPoint("CENTER"); glow:SetSize(40, 40); glow:SetVertexColor(1, 0.15, 0.15, 0.55)
	local function bar(w, h, r, g, b, a, layer)
		local t = c:CreateTexture(nil, layer)
		t:SetTexture(WHITE); t:SetVertexColor(r, g, b, a); t:SetSize(w, h); t:SetPoint("CENTER")
	end
	bar(20, 8, 0, 0, 0, 0.85, "BORDER"); bar(8, 20, 0, 0, 0, 0.85, "BORDER")         -- a dark outline
	bar(16, 4, 1, 0.16, 0.16, 1, "ARTWORK"); bar(4, 16, 1, 0.16, 0.16, 1, "ARTWORK")  -- the cross
	bar(4, 4, 1, 0.55, 0.55, 1, "OVERLAY")                                          -- a bright heart
	crosses[plate] = c
	return c
end

local function UpdatePlate(unit)
	local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit(unit)
	if not plate then return end
	local show = P.db and S().healerMarks and N(UnitIsPlayer(unit)) and N(UnitIsEnemy("player", unit)) and P:IsHealer(unit)
	if show then Cross(plate):Show() elseif crosses[plate] then crosses[plate]:Hide() end
end
local function UpdatePlates()
	if not C_NamePlate then return end
	for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit then UpdatePlate(unit) end
	end
end
P:On("NAME_PLATE_UNIT_ADDED", function(_, unit) if P.db and S().healerMarks then UpdatePlate(unit) end end)
P:On("NAME_PLATE_UNIT_REMOVED", function(_, unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if plate and crosses[plate] then crosses[plate]:Hide() end
end)
P:Listen("HEALER_FOUND", UpdatePlates)
P:Listen("PLAYER_INFO", function() UpdatePlates() end)

---------------------------------------------------------------------------
-- Odds in a fight
---------------------------------------------------------------------------
-- rough class matchups at equal level and gear (how the first does against the second)
local EDGE = {
	MAGE = { WARRIOR = 8, ROGUE = -5, HUNTER = 2, PALADIN = 4 },
	WARLOCK = { WARRIOR = 6, ROGUE = 6, PALADIN = 4, MAGE = 2, PRIEST = -3 },
	ROGUE = { MAGE = 5, PRIEST = 4, HUNTER = 3, WARLOCK = -6, DRUID = 2 },
	HUNTER = { WARRIOR = 6, PALADIN = 3, MAGE = -2, ROGUE = -3, DRUID = 2 },
	PRIEST = { WARRIOR = 5, ROGUE = -4, WARLOCK = 3, PALADIN = 2 },
	DRUID = { WARRIOR = 4, ROGUE = -2, HUNTER = -2 },
	SHAMAN = { WARRIOR = 3, ROGUE = 2, PALADIN = 2 },
	PALADIN = { WARRIOR = 1, ROGUE = 2, MAGE = -4, PRIEST = -2, WARLOCK = -4, HUNTER = -3, SHAMAN = -2 },
	WARRIOR = { ROGUE = 2 },
}
local function Edge(a, b)
	local x = EDGE[a] and EDGE[a][b]
	if x then return x end
	x = EDGE[b] and EDGE[b][a]
	return x and -x or 0
end

function P:FightOdds(unit)
	local me, them = UnitLevel("player"), N(UnitLevel(unit)) or UnitLevel("player")
	if them == -1 then return 3, "Far above you" end                 -- skull: ?? level
	local odds = 50
	odds = odds + max(-40, min(40, (me - them) * 8))
	local i = info[N(UnitGUID(unit)) or ""]
	local mine = MyIlvl()
	if i and i.ilvl and mine then odds = odds + max(-15, min(15, (mine - i.ilvl) * 1.5)) end
	local hp, theirHP = UnitHealth("player"), N(UnitHealth(unit))
	local hpMax, theirMax = UnitHealthMax("player"), N(UnitHealthMax(unit))
	if not (theirHP and theirMax) then
		-- their health is hidden from add-ons here: leave it out
	elseif hp > 0 and theirHP > 0 and theirMax > 100 then
		odds = odds + max(-15, min(15, 12 * log(hp / theirHP) / log(2)))  -- health pools (when the server shares them)
	elseif hpMax > 0 and theirMax > 0 then
		odds = odds + ((hp / hpMax) - (theirHP / theirMax)) * 25            -- otherwise how hurt each of you is
	end
	odds = odds + Edge(select(2, UnitClass("player")), N(select(2, UnitClass(unit))) or "")
	if self:IsHealer(unit) then odds = odds - 4 end
	odds = max(3, min(97, floor(odds + 0.5)))
	local word = odds >= 70 and "Good odds" or odds >= 57 and "Slight edge" or odds >= 44 and "Even fight"
		or odds >= 30 and "Risky" or "Walk away"
	return odds, word
end

---------------------------------------------------------------------------
-- The card
---------------------------------------------------------------------------
local card
local function Build()
	card = CreateFrame("Frame", "PathwayPlayerCard", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	card:SetSize(256, 10)
	card:SetFrameStrata("TOOLTIP")
	card:SetClampedToScreen(true)
	P:TooltipSkin(card)
	card:Hide()
	-- faction band across the top: color fading into the card, the banner on the right
	card.band = card:CreateTexture(nil, "BORDER")
	card.band:SetPoint("TOPLEFT", 4, -4); card.band:SetPoint("TOPRIGHT", -4, -4); card.band:SetHeight(43)
	card.band:SetTexture(WHITE)
	card.emblem = card:CreateTexture(nil, "ARTWORK")
	card.emblem:SetSize(42, 42); card.emblem:SetPoint("TOPRIGHT", 0, -2); card.emblem:SetAlpha(0.9)
	card.accent = card:CreateTexture(nil, "ARTWORK")
	card.accent:SetPoint("TOPLEFT", card.band, "BOTTOMLEFT"); card.accent:SetPoint("TOPRIGHT", card.band, "BOTTOMRIGHT")
	card.accent:SetHeight(1); card.accent:SetTexture(WHITE)
	local function fs(font, parent)
		local f = (parent or card):CreateFontString(nil, "OVERLAY")
		f:SetFontObject(font); f:SetJustifyH("LEFT")
		return f
	end
	card.name = fs(P.tipFonts.head); card.name:SetPoint("TOPLEFT", 10, -9); card.name:SetPoint("RIGHT", -96, 0); card.name:SetWordWrap(false)
	-- item level: the headline, big, in the band
	card.ilvl = fs(P.fonts.big); card.ilvl:SetPoint("TOPRIGHT", -46, -6); card.ilvl:SetJustifyH("RIGHT")
	card.ilvlTag = fs(P.fonts.small); card.ilvlTag:SetPoint("TOPRIGHT", card.ilvl, "BOTTOMRIGHT", 0, -1); card.ilvlTag:SetJustifyH("RIGHT")
	card.sub = fs(P.tipFonts.small); card.sub:SetPoint("TOPLEFT", 10, -28); card.sub:SetTextColor(1, 1, 1)
	card.sub:SetPoint("RIGHT", -46, 0); card.sub:SetWordWrap(false)       -- a long race and class never runs off the card
	-- health along the bottom, like the bar under the game's tooltip
	card.hp = CreateFrame("StatusBar", nil, card)
	card.hp:SetPoint("BOTTOMLEFT", 5, 5); card.hp:SetPoint("BOTTOMRIGHT", -5, 5)
	card.hp:SetHeight(6)
	card.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	card.hp:SetStatusBarColor(0.35, 0.85, 0.45, 1)
	card.hp.bg = card.hp:CreateTexture(nil, "BACKGROUND"); card.hp.bg:SetAllPoints(); card.hp.bg:SetColorTexture(0, 0, 0, 0.5)
	card.healer = card:CreateTexture(nil, "OVERLAY")
	card.healer:SetSize(10, 10)
	card.rows = {}
	for i = 1, 8 do
		local l, r = fs(P.tipFonts.small), fs(P.tipFonts.small)
		l:SetTextColor(1, 0.82, 0); r:SetTextColor(1, 1, 1)             -- gold labels, white values: the tooltip's colors
		l:SetPoint("TOPLEFT", 10, -56 - (i - 1) * 16)
		r:SetPoint("TOPRIGHT", -10, -56 - (i - 1) * 16); r:SetJustifyH("RIGHT")
		card.rows[i] = { l, r }
	end
	-- the odds: a number and a bar
	card.odds = fs(P.fonts.big)
	card.oddsWord = fs(P.fonts.head)
	card.track = card:CreateTexture(nil, "ARTWORK"); card.track:SetTexture(WHITE); card.track:SetVertexColor(1, 1, 1, 0.08)
	card.track:SetHeight(4)
	card.fill = card:CreateTexture(nil, "OVERLAY"); card.fill:SetTexture(WHITE); card.fill:SetHeight(4)
	card.note = fs(P.fonts.head)
	-- still hovering: full. Moved off: it stays a moment so you can read it, then fades.
	card:SetScript("OnUpdate", function(self)
		-- placing it during setup: it stays put and fully shown
		if self.preview then self.leaving = nil; self:SetAlpha(1); return end
		-- shown for a row in the damage meter: it lasts while you're on that row
		if self.owner then
			if self.owner:IsVisible() and self.owner:IsMouseOver() then
				self.leaving = nil
				self:SetAlpha(math.min(1, self:GetAlpha() + 0.15))
				return
			end
			self.owner = nil
			self.leaving = GetTime() - (S().cardLinger or 1.5)     -- straight to the fade
		end
		local here = UnitExists("mouseover") and N(UnitIsPlayer("mouseover")) and not N(UnitIsUnit("mouseover", "player"))
		local g = here and N(UnitGUID("mouseover"))
		if here and g and self.guid and g ~= self.guid then
			-- straight on to the next player under the mouse (a crowd, sweeping across it)
			self.guid = g
			P:HoverPlayer()
			return
		end
		if here then
			self.leaving = nil
			self:SetAlpha(math.min(1, self:GetAlpha() + 0.15))
			return
		end
		local now = GetTime()
		self.leaving = self.leaving or now
		local t = now - self.leaving
		local hold, fade = S().cardLinger or 1.5, 1.2
		if t > hold + fade then self:Hide() return end
		self:SetAlpha(t <= hold and 1 or (1 - (t - hold) / fade))
	end)
	P.Perf.Hook(card, "Player cards", "OnUpdate")
	card:SetScript("OnHide", function(self) self.leaving = nil end)
	card.cls = card:CreateTexture(nil, "OVERLAY")
	card.cls:SetSize(16, 16)
	card.cls:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
end

-- The game's tooltip steps aside whenever it is about another player (the card
-- shows all of that), decided each time its content changes, so sweeping the
-- mouse across a crowd never lets the two overlap. Anything else (an NPC, an
-- item, yourself) shows as normal.
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function AboutAPlayer(tip)
	if not (On() and S().cardReplaces) then return false end
	local ok, _, unit = pcall(tip.GetUnit, tip)
	if not ok or not unit or Secret(unit) then
		unit = UnitExists("mouseover") and "mouseover" or nil
		if not unit then return false end
	end
	return N(UnitIsPlayer(unit)) and not N(UnitIsUnit(unit, "player")) and true or false
end
local function Decide(tip)
	if tip ~= GameTooltip then return end
	local want = AboutAPlayer(tip) and 0 or 1
	if (tonumber(tip:GetAlpha()) or 1) ~= want then tip:SetAlpha(want) end
end
function P:CoverTooltip() Decide(GameTooltip) end
if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and TooltipDataProcessor.AllTypes
	and pcall(TooltipDataProcessor.AddTooltipPostCall, TooltipDataProcessor.AllTypes, Decide)) then
	pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", Decide)
end
GameTooltip:HookScript("OnShow", Decide)
GameTooltip:HookScript("OnTooltipCleared", function(tip)
	if tip:GetAlpha() < 1 then tip:SetAlpha(1) end
	-- refreshed in place (a unit frame's tooltip redraws every moment): decide again once it's filled
	C_Timer.After(0, function() if tip:IsShown() then Decide(tip) end end)
end)
if GameTooltip.SetUnit then hooksecurefunc(GameTooltip, "SetUnit", Decide) end
GameTooltip:HookScript("OnHide", function(tip) if tip:GetAlpha() < 1 then tip:SetAlpha(1) end end)

local CLASS_ICON = "Interface\\WorldStateFrame\\Icons-Classes"
local function ClassColor(unit)
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[N(select(2, UnitClass(unit))) or ""]
	return c and ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255) or "|cffffffff"
end

local function Fill(unit)
	local guid = N(UnitGUID(unit))
	local fac = FACTION[N(UnitFactionGroup(unit)) or ""]
	if not fac then card:Hide() return end
	card.guid = guid
	local r, g, b = fac[1], fac[2], fac[3]
	card:SetBackdropBorderColor(r, g, b, 0.9)
	if card.band.SetGradient and CreateColor then
		card.band:SetGradient("VERTICAL", CreateColor(r * 0.25, g * 0.25, b * 0.25, 0.9), CreateColor(r * 0.7, g * 0.7, b * 0.7, 0.95))
	elseif card.band.SetGradientAlpha then
		card.band:SetGradientAlpha("VERTICAL", r * 0.25, g * 0.25, b * 0.25, 0.9, r * 0.7, g * 0.7, b * 0.7, 0.95)
	else
		card.band:SetVertexColor(r * 0.55, g * 0.55, b * 0.55, 0.95)
	end
	card.accent:SetVertexColor(r, g, b, 1)
	card.emblem:SetTexture(fac.icon)
	card.emblem:SetTexCoord(0, 0.62, 0, 0.62)

	-- their name. On Forever the part after the name is a surname, not a realm
	local first, last = UnitName(unit)
	local full = first
	if not isSecret(first) and not isSecret(last) then
		local title = UnitPVPName and N(UnitPVPName(unit))
		if title and title ~= "" and first and title ~= first then full = title end
		if last and last ~= "" and first then full = full .. " " .. last end
	end
	card.name:SetText(full)                           -- shown as is, even when it's a hidden value
	local cf = N(select(2, UnitClass(unit)))
	local cc = cf and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf]
	if cc then card.name:SetTextColor(cc.r, cc.g, cc.b) else card.name:SetTextColor(1, 1, 1) end
	local tc = cf and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cf]
	if tc then
		card.cls:SetTexCoord(tc[1], tc[2], tc[3], tc[4]); card.cls:Show()
		card.cls:ClearAllPoints(); card.cls:SetPoint("TOPLEFT", 10, -27)
		card.sub:ClearAllPoints(); card.sub:SetPoint("LEFT", card.cls, "RIGHT", 5, 0)
	else
		card.cls:Hide()
		card.sub:ClearAllPoints(); card.sub:SetPoint("TOPLEFT", 10, -28)
	end
	local lvl = N(UnitLevel(unit))
	local race = N(UnitRace(unit)) or ""
	local class = N(UnitClass(unit)) or ""
	card.sub:SetText(("Level %s  %s  %s%s|r"):format(not lvl and "?" or lvl == -1 and "??" or lvl, race, ClassColor(unit), class))
	-- health: a bar takes hidden values fine
	pcall(card.hp.SetMinMaxValues, card.hp, 0, UnitHealthMax(unit))
	pcall(card.hp.SetValue, card.hp, UnitHealth(unit))

	local i = info[guid or ""] or {}
	local rows, n = card.rows, 0
	local function row(l, v)
		if n >= #rows then return end
		n = n + 1
		rows[n][1]:SetText(l); rows[n][2]:SetText(v)
		rows[n][1]:Show(); rows[n][2]:Show()
	end
	local guild, gRank = N(GetGuildInfo(unit)), nil
	if guild then gRank = N(select(2, GetGuildInfo(unit))) end
	if guild then row("Guild", "|cffd8dde3<" .. guild .. ">|r" .. (gRank and (P.DIM .. "  " .. gRank .. "|r") or "")) end
	if guid then pcall(ReadAuras, unit, guid) end
	local healer = P:IsHealer(unit)
	local hc = healer and "|cffff5a5a" or "|cffffffff"
	if i.spec then
		row("Spec", hc .. i.spec .. "|r  " .. P.DIM .. i.points .. "|r")
	elseif i.seen then
		row("Spec", hc .. i.seen .. "|r" .. P.DIM .. "  seen: " .. i.seenBy .. "|r")
	elseif healer then
		row("Role", "|cffff5a5aHealer|r")
	end
	-- who they're after
	local tu = unit .. "target"
	if UnitExists(tu) then
		if N(UnitIsUnit(tu, "player")) then row("Targeting", "|cffff5a5aYou|r")
		else
			local tn = N(UnitName(tu))
			if tn then row("Targeting", "|cffd8dde3" .. tn .. "|r") end
		end
	end
	-- item level, up top: theirs, and how it compares with yours
	local mine = MyIlvl()
	if i.ilvl then
		local d = mine and (i.ilvl - mine) or 0
		local c = d >= 3 and "|cffff6a5a" or d <= -3 and "|cff5ad18a" or "|cffffffff"
		card.ilvl:SetText(c .. i.ilvl .. "|r")
		card.ilvlTag:SetText("|cffd8dde3ilvl|r" .. (mine and (d ~= 0 and ("  " .. c .. (d > 0 and "+" or "") .. d .. "|r") or "  =") or ""))
	else
		-- not known yet: no placeholder up top (it fills in by itself), the name gets the room
		card.ilvl:SetText(""); card.ilvlTag:SetText("")
		-- (a protected call in combat on this client: only asked outside a fight)
		local near = not InCombatLockdown() and CheckInteractDistance and N(CheckInteractDistance(unit, 1))
		if not N(UnitIsUnit(unit, "player")) then
			if not near then row("Item level", P.DIM .. "get closer to see|r")
			elseif InCombatLockdown() then row("Item level", P.DIM .. "after this fight|r")
			elseif (i.tries or 0) >= 6 then row("Item level", P.DIM .. "not shared|r") end
		end
	end
	card.name:SetPoint("RIGHT", i.ilvl and -96 or -46, 0)
	card.sub:SetPoint("RIGHT", i.ilvl and -104 or -46, 0)
	if N(UnitInParty and UnitInParty(unit)) or N(UnitInRaid and UnitInRaid(unit)) then row("Group", "|cff5ad18aWith you|r") end
	if n < #rows then
		local flags = {}
		if N(UnitIsPVP(unit)) then flags[#flags + 1] = "|cffff8c4dPvP flagged|r" end
		if N(UnitAffectingCombat(unit)) then flags[#flags + 1] = "|cffff5a5ain combat|r" end
		if UnitIsAFK and N(UnitIsAFK(unit)) then flags[#flags + 1] = "|cffd8dde3away|r" end
		if UnitIsDND and N(UnitIsDND(unit)) then flags[#flags + 1] = "|cffd8dde3busy|r" end
		if N(UnitIsDeadOrGhost(unit)) then flags[#flags + 1] = "|cff9aa3addead|r" end
		if #flags > 0 then row("Now", table.concat(flags, P.DIM .. "  ·  |r")) end
	end
	for k = n + 1, #rows do rows[k][1]:Hide(); rows[k][2]:Hide() end

	-- the odds
	local y = -56 - n * 16 - 6
	local odds, word = P:FightOdds(unit)
	local oc = odds >= 57 and { 0.4, 0.85, 0.45 } or odds >= 44 and { 1, 0.82, 0.3 } or { 1, 0.35, 0.3 }
	card.odds:ClearAllPoints(); card.odds:SetPoint("TOPLEFT", 10, y)
	card.odds:SetText(("|cff%02x%02x%02x%d%%|r"):format(oc[1] * 255, oc[2] * 255, oc[3] * 255, odds))
	card.oddsWord:ClearAllPoints(); card.oddsWord:SetPoint("LEFT", card.odds, "RIGHT", 8, 0)
	card.oddsWord:SetText((N(UnitIsEnemy("player", unit)) and "your odds in a fight  ·  " or "your odds in a duel  ·  ") .. word)
	card.track:ClearAllPoints(); card.track:SetPoint("TOPLEFT", 10, y - 22); card.track:SetPoint("TOPRIGHT", -10, y - 22)
	card.fill:ClearAllPoints(); card.fill:SetPoint("TOPLEFT", card.track, "TOPLEFT")
	card.fill:SetWidth(max(1, (card:GetWidth() - 20) * odds / 100)); card.fill:SetVertexColor(oc[1], oc[2], oc[3], 1)
	card:SetHeight(-(y - 22) + 22)

	-- where it goes: beside a damage meter row, your own spot, or where the tooltip would be
	card:ClearAllPoints()
	local p1, rel, p2, ox, oy = GameTooltip:GetPoint(1)
	local fixed = S().cardSpot == "fixed"
	if card.owner then
		local o = card.owner
		local roomLeft = (tonumber(o:GetLeft()) or 0) * (tonumber(o:GetEffectiveScale()) or 1) / (tonumber(card:GetEffectiveScale()) or 1)
		if roomLeft > (tonumber(card:GetWidth()) or 236) + 12 then card:SetPoint("TOPRIGHT", o, "TOPLEFT", -6, 0)
		else card:SetPoint("TOPLEFT", o, "TOPRIGHT", 6, 0) end
	elseif fixed then
		P:PlaceAt(card)
	elseif S().cardReplaces and GameTooltip:IsShown() and p1 and not isSecret(p1) then
		-- the corner the tooltip grows from stays put, so the card sits right where it would
		local corner = (p1:find("TOP") and "TOP" or p1:find("BOTTOM") and "BOTTOM" or "") .. (p1:find("LEFT") and "LEFT" or p1:find("RIGHT") and "RIGHT" or "")
		if corner == "" then corner = "CENTER" end
		local l, b = tonumber(GameTooltip:GetLeft()), tonumber(GameTooltip:GetBottom())
		local r, t = tonumber(GameTooltip:GetRight()), tonumber(GameTooltip:GetTop())
		local k = (tonumber(GameTooltip:GetEffectiveScale()) or 1) / (tonumber(card:GetEffectiveScale()) or 1)
		if l and b and r and t then
			l, b, r, t = l * k, b * k, r * k, t * k
			local x = corner:find("LEFT") and l or corner:find("RIGHT") and r or (l + r) / 2
			local y = corner:find("TOP") and t or corner:find("BOTTOM") and b or (t + b) / 2
			card:SetPoint(corner, UIParent, "BOTTOMLEFT", x, y)
		else
			card:SetPoint(p1, rel, p2, ox, oy)
		end
	elseif GameTooltip:IsShown() then
		local left = tonumber(GameTooltip:GetLeft()) or 0
		if left > (tonumber(card:GetWidth()) or 236) + 20 then card:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -4, 0)
		else card:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 4, 0) end
	else
		local x, yy = GetCursorPosition()
		local s = UIParent:GetEffectiveScale()
		card:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / s + 24, yy / s + 12)
	end
	if not card:IsShown() then card:SetAlpha(0) end
	card.leaving = nil
	card:Show()
	Decide(GameTooltip)
end

local reported
local function Hover(unit, owner)
	if not On() then return end
	unit = unit or "mouseover"
	if not UnitExists(unit) or not N(UnitIsPlayer(unit)) then return end
	if not owner and N(UnitIsUnit(unit, "player")) then return end
	if not card then Build() end
	if card.preview then return end
	card.owner = owner
	local ok, err = pcall(Fill, unit)
	if not ok then
		card:Hide()
		if not reported then reported = true; geterrorhandler()(err) end        -- once, not every hover
		return
	end
	pcall(Inspect, unit)
end
function P:HoverPlayer() Hover() end
-- the card for a group member, next to something you're pointing at (a meter row)
function P:ShowPlayerCard(unit, owner) Hover(unit, owner) end

-- setup: show a card where it will sit, so you can drag it into place
function P:PreviewCard(on)
	if not card then Build() end
	if not on then card.preview = nil; card:Hide(); return card end
	card.preview = nil
	card.owner = nil
	pcall(Fill, "player")
	P:PlaceAt(card)                                   -- its own spot while you place it
	card.preview = true
	card:SetAlpha(1)
	card:Show()
	return card
end
function P:PlayerCardFrame() if not card then Build() end return card end
P:On("UPDATE_MOUSEOVER_UNIT", function() Decide(GameTooltip); if On() then C_Timer.After(0, Hover) end end)
P:Listen("PLAYER_INFO", function(guid)
	if not (card and card:IsShown() and card.guid == guid) then return end
	local unit = UnitFor(guid)                                   -- still hovered, or your target
	if unit then pcall(Fill, unit) end
end)

---------------------------------------------------------------------------
-- A ding when you target an enemy healer (or any enemy player)
---------------------------------------------------------------------------
P:On("PLAYER_TARGET_CHANGED", function()
	if not P.db then return end
	local mode = S().pvpDing
	if not mode or mode == "off" then return end
	if not (UnitExists("target") and N(UnitIsPlayer("target")) and N(UnitIsEnemy("player", "target"))) then return end
	if mode ~= "enemies" and not P:IsHealer("target") then return end
	PlaySound(SOUNDKIT.TELL_MESSAGE or 3081, "Master")
	pcall(Inspect, "target")
end)

P:Listen("READY", WatchCombatLog)
P:Listen("SETTINGS_CHANGED", function() WatchCombatLog(); UpdatePlates() end)
end part() end
-- ==================== Meter.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Damage meter
     A small, fixed window with the game's own numbers: the server counts
     every hit (pets, absorbs and all) and works out damage per second over
     the time each player was actually fighting, so nothing is guessed.

       · Everyone in your party or raid, live, bars moving as the fight goes.
         Your row stands out and is always there, even past the top rows.
       · Your range: a bar from your worst to your best fight, a tick at your
         average over every fight, and this fight's number moving along it.
       · Average = all damage over all fighting time (a 2-minute boss counts
         more than a 5-second rabbit), from your last 50 fights.

     In combat the game only lets add-ons show its numbers, not read them,
     so live figures are drawn exactly as the game gives them; the history
     is written down the moment each fight ends. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local floor, max, min = math.floor, math.max, math.min

local function S() return P.db.settings end
local DM = setmetatable({}, { __index = function(_, k) return C_DamageMeter and C_DamageMeter[k] end })   -- read when used
local ROW_H, WIDTH, KEEP, MIN_FIGHT = 17, 240, 50, 6

local MODES = {
	{ key = "damage", label = "Damage", type = 0, rate = "DPS" },
	{ key = "healing", label = "Healing", type = 2, rate = "HPS" },
	{ key = "taken", label = "Taken", type = 7, rate = "DTPS" },
}
local SEG_CURRENT, SEG_OVERALL = 1, 0

local win, rows = nil, {}
local function Secret(v) return issecretvalue and issecretvalue(v) end

local function Short(n)
	if n >= 1e6 then return ("%.1fm"):format(n / 1e6) end
	if n >= 1e4 then return ("%.0fk"):format(n / 1e3) end
	if n >= 1e3 then return ("%.1fk"):format(n / 1e3) end
	return tostring(floor(n + 0.5))
end

-- a number the game may be keeping secret: shown as it comes, formatted when we may
local function SetNumber(fs, v)
	if v == nil then fs:SetText("") return end
	if not Secret(v) then fs:SetText(Short(v)) return end
	if AbbreviateNumbers and pcall(function() fs:SetText(AbbreviateNumbers(v)) end) then return end
	if not pcall(fs.SetText, fs, v) then fs:SetText("…") end
end

function P:MeterAvailable()
	if not (DM and DM.GetCombatSessionFromType) then return false end
	if DM.IsDamageMeterAvailable then
		local ok, yes = pcall(DM.IsDamageMeterAvailable)
		if ok and yes == false then return false end
	end
	return true
end

local function Mode()
	local k = S().meterMode or "damage"
	for _, m in ipairs(MODES) do if m.key == k then return m end end
	return MODES[1]
end

local function Session(seg, mtype)
	local ok, session = pcall(DM.GetCombatSessionFromType, seg, mtype)
	if ok and type(session) == "table" then return session end
end
local function Duration(seg)
	if not DM.GetSessionDurationSeconds then return end
	local ok, d = pcall(DM.GetSessionDurationSeconds, seg)
	if ok and type(d) == "number" and not Secret(d) then return d end
end

---------------------------------------------------------------------------
-- Your history: one line per fight, per mode (damage and healing apart)
---------------------------------------------------------------------------
local function History(key)
	P.cdb.meterHist = P.cdb.meterHist or {}
	P.cdb.meterHist[key] = P.cdb.meterHist[key] or {}
	return P.cdb.meterHist[key]
end

-- min, max, time-weighted average and how many fights
local function Stats(key)
	local h = History(key)
	if #h == 0 then return end
	local lo, hi, amount, time = math.huge, 0, 0, 0
	for _, f in ipairs(h) do
		lo, hi = min(lo, f[1]), max(hi, f[1])
		amount, time = amount + f[1] * f[2], time + f[2]
	end
	return lo, hi, time > 0 and amount / time or 0, #h
end

local function Record()
	if not P:MeterAvailable() then return end
	local dur = Duration(SEG_CURRENT)
	if not dur or dur < MIN_FIGHT then return end      -- a hit on a critter isn't a fight
	for _, m in ipairs(MODES) do
		if m.key ~= "taken" then
			local session = Session(SEG_CURRENT, m.type)
			for _, src in ipairs(session and session.combatSources or {}) do
				if src.isLocalPlayer then
					local rate = src.amountPerSecond
					if rate and not Secret(rate) and rate > 0 then
						local h = History(m.key)
						table.insert(h, { rate, dur, time() })
						while #h > KEEP do table.remove(h, 1) end
					end
					break
				end
			end
		end
	end
	P:UpdateMeter()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
local function Row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("StatusBar", nil, win)
	r:SetHeight(ROW_H - 2)
	r:SetPoint("TOPLEFT", 6, -26 - (i - 1) * ROW_H)
	r:SetPoint("RIGHT", -6, 0)
	r:SetStatusBarTexture(P.WHITE)
	r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetColorTexture(1, 1, 1, 0.03)
	r.rank = r:CreateFontString(nil, "OVERLAY"); r.rank:SetFontObject(P.fonts.head)
	r.rank:SetPoint("LEFT", 4, 0); r.rank:SetWidth(16); r.rank:SetJustifyH("LEFT")
	r.name = r:CreateFontString(nil, "OVERLAY"); r.name:SetFontObject(P.fonts.button)
	r.name:SetPoint("LEFT", r.rank, "RIGHT", 2, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
	r.rate = r:CreateFontString(nil, "OVERLAY"); r.rate:SetFontObject(P.fonts.button)
	r.rate:SetPoint("RIGHT", -4, 0); r.rate:SetJustifyH("RIGHT")
	r.total = r:CreateFontString(nil, "OVERLAY"); r.total:SetFontObject(P.fonts.head)
	r.total:SetPoint("RIGHT", r.rate, "LEFT", -6, 0); r.total:SetJustifyH("RIGHT")
	r.name:SetPoint("RIGHT", r.total, "LEFT", -6, 0)
	-- hover a row: that player's card. Drag a row: the window moves (when allowed)
	r:EnableMouse(true); r:RegisterForDrag("LeftButton")
	r:SetScript("OnDragStart", function() if P:CanDrag() then win:StartMoving(); win.moving = true end end)
	r:SetScript("OnDragStop", function() if win.moving then win.moving = nil; win:GetScript("OnDragStop")(win) end end)
	r:SetScript("OnEnter", function(self)
		if S().meterCards == false or not self.src then return end
		local unit = P:MeterUnit(self.src)
		if unit and P.ShowPlayerCard then P:ShowPlayerCard(unit, self) end
	end)
	rows[i] = r
	return r
end

-- which party or raid member a meter line is about
local function Plain(v) if v ~= nil and not Secret(v) then return v end end
function P:MeterUnit(src)
	if src.isLocalPlayer then return "player" end
	local guid = Plain(src.sourceGUID) or Plain(src.guid)
	local name = Plain(src.name)
	if not (guid or name) then return end
	local function match(u)
		if not UnitExists(u) then return false end
		if guid then return Plain(UnitGUID(u)) == guid end
		local n, realm = UnitName(u)
		n = Plain(n)
		return n and (n == name or (realm and Plain(realm) and (n .. "-" .. realm) == name))
	end
	if IsInRaid() then
		for i = 1, 40 do if match("raid" .. i) then return "raid" .. i end end
	else
		for i = 1, 4 do if match("party" .. i) then return "party" .. i end end
	end
end

local function FillRow(r, src, rank, maxAmount)
	local c = RAID_CLASS_COLORS and src.classFilename and RAID_CLASS_COLORS[src.classFilename]
	local cr, cg, cb = c and c.r or 0.6, c and c.g or 0.62, c and c.b or 0.66
	local me = src.isLocalPlayer
	r:SetStatusBarColor(cr, cg, cb, me and 0.9 or 0.5)
	r.bg:SetColorTexture(me and A[1] or 1, me and A[2] or 1, me and A[3] or 1, me and 0.10 or 0.03)
	if not pcall(function() r:SetMinMaxValues(0, maxAmount or 1); r:SetValue(src.totalAmount or 0) end) then
		r:SetMinMaxValues(0, 1); r:SetValue(0)
	end
	r.rank:SetText(P.DIM .. rank .. "|r")
	if not pcall(r.name.SetText, r.name, src.name) then r.name:SetText("?") end
	r.name:SetTextColor(1, 1, 1, me and 1 or 0.88)
	SetNumber(r.total, src.totalAmount)
	SetNumber(r.rate, src.amountPerSecond)
	r.src = src
	r:Show()
end

function P:UpdateMeter()
	if not (win and win:IsShown()) then return end
	local m = Mode()
	local seg = S().meterOverall and SEG_OVERALL or SEG_CURRENT
	win.modeText:SetText(m.label)
	win.segText:SetText(seg == SEG_OVERALL and "All fights" or "This fight")
	local session = Session(seg, m.type)
	local list = session and session.combatSources or {}
	local maxAmount = session and session.maxAmount
	local style = S().meterStyle or "detailed"
	local maxRows = style == "simple" and 1 or (S().meterRows or 8)

	-- everyone, with you always in view
	local myIndex
	for i, src in ipairs(list) do if src.isLocalPlayer then myIndex = i break end end
	-- simple: just you
	if style == "simple" then list = myIndex and { list[myIndex] } or {}; myIndex = myIndex and 1 end
	local shown = min(#list, maxRows)
	for i = 1, shown do
		local idx = i
		if i == shown and myIndex and myIndex > shown then idx = myIndex end
		FillRow(Row(i), list[idx], idx, maxAmount)
	end
	for i = shown + 1, #rows do rows[i]:Hide() end

	-- the group: total per second and how many are fighting (readable between fights)
	local groupRate, readable = 0, true
	for _, src in ipairs(list) do
		if Secret(src.amountPerSecond) then readable = false break end
		groupRate = groupRate + (src.amountPerSecond or 0)
	end
	local dur = Duration(seg)
	local head = {}
	if #list > 1 and readable and S().meterGroupLine ~= false then head[#head + 1] = ("Group %s %s"):format(Short(groupRate), m.rate) end
	if dur and dur > 0 then head[#head + 1] = ("%d:%02d"):format(floor(dur / 60), floor(dur % 60)) end
	if #list == 0 then head[#head + 1] = "Fight something and it shows here" end
	win.group:SetText(P.DIM .. table.concat(head, "  ·  ") .. "|r")

	-- you: this fight, moving along your range, with your average marked
	local panel = win.you
	local yTop = -26 - max(1, shown) * ROW_H - 18
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", 8, yTop); panel:SetPoint("RIGHT", -8, 0)
	local lo, hi, avg, n = Stats(m.key == "taken" and "damage" or m.key)
	local mine = myIndex and list[myIndex]
	local live = mine and mine.amountPerSecond
	if m.key == "taken" or style ~= "detailed" then
		panel:Hide()
		win:SetHeight(-yTop + 8)
		return
	end
	panel:Show()
	panel.label:SetText((seg == SEG_OVERALL and "You, all fights" or "You, this fight") .. "  " .. P.DIM .. m.rate .. "|r")
	SetNumber(panel.value, live)
	if not live then panel.value:SetText(P.DIM .. "–|r") end
	local barLo, barHi = lo or 0, hi or 1
	if not n or n < 2 then barLo, barHi = 0, max(avg or 0, (live and not Secret(live)) and live or 0, 1) * 1.5 end
	if barHi <= barLo then barHi = barLo + 1 end
	panel.bar:SetMinMaxValues(barLo, barHi)
	if not (live and pcall(panel.bar.SetValue, panel.bar, live)) then panel.bar:SetValue(barLo) end
	-- inside your range, better than average, or below it (only when we can read it)
	if live and not Secret(live) and avg then
		local c = live >= avg and { 0.30, 0.85, 0.45 } or { 0.95, 0.65, 0.25 }
		panel.bar:SetStatusBarColor(c[1], c[2], c[3], 0.95)
	else
		panel.bar:SetStatusBarColor(A[1], A[2], A[3], 0.95)
	end
	if avg and n and n >= 1 then
		local w = panel.bar:GetWidth()
		local f = (avg - barLo) / (barHi - barLo)
		panel.avgTick:ClearAllPoints()
		panel.avgTick:SetPoint("CENTER", panel.bar, "LEFT", max(0, min(1, f)) * w, 0)
		panel.avgTick:Show()
		panel.lo:SetText(n >= 2 and Short(lo) or "")
		panel.hi:SetText(n >= 2 and Short(hi) or "")
		panel.sub:SetText(P.DIM .. ("Average %s  ·  best %s  ·  %d fight%s"):format(Short(avg), Short(hi), n, n == 1 and "" or "s") .. "|r")
	else
		panel.avgTick:Hide()
		panel.lo:SetText(""); panel.hi:SetText("")
		panel.sub:SetText(P.DIM .. "Your range builds up as you fight|r")
	end
	win:SetHeight(-yTop + 64)
end

---------------------------------------------------------------------------
-- The window: fixed in place (Shift-drag to move it), never in the way
---------------------------------------------------------------------------
local function Build()
	win = CreateFrame("Frame", "PathwayMeter", UIParent, "BackdropTemplate")
	P.Flat(win, nil, nil, true)
	win:SetWidth(WIDTH)
	win:SetFrameStrata("LOW")
	win:SetClampedToScreen(true)
	win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", function(self) if P:CanDrag() then self:StartMoving() end end)
	win:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint()
		P.db.pos.PathwayMeter = { p, rp, x, y }
	end)
	P:PlaceAt(win)

	local accent = win:CreateTexture(nil, "ARTWORK"); accent:SetHeight(1)
	accent:SetPoint("TOPLEFT", 6, -22); accent:SetPoint("TOPRIGHT", -6, -22)
	P:OnPaint(function() accent:SetColorTexture(A[1], A[2], A[3], 0.5) end)
	accent:SetColorTexture(A[1], A[2], A[3], 0.5)

	-- header: click the mode to cycle Damage → Healing → Taken; click the fight to switch
	local function HeadButton(anchor, x, font)
		local b = CreateFrame("Button", nil, win)
		b:SetHeight(18); b:SetPoint(anchor, x, -3)
		b.t = b:CreateFontString(nil, "OVERLAY"); b.t:SetFontObject(font); b.t:SetPoint("CENTER")
		b:SetScript("OnEnter", function(s) s.t:SetTextColor(A[1], A[2], A[3]) end)
		b:SetScript("OnLeave", function(s) s.t:SetTextColor(0.95, 0.96, 0.97) end)
		hooksecurefunc(b.t, "SetText", function() b:SetWidth(b.t:GetStringWidth() + 4) end)
		return b
	end
	local mode = HeadButton("TOPLEFT", 8, P.fonts.title)
	win.modeText = mode.t
	mode:SetScript("OnClick", function()
		local cur = Mode()
		for i, m in ipairs(MODES) do if m == cur then S().meterMode = MODES[i % #MODES + 1].key break end end
		P:UpdateMeter()
	end)
	local seg = HeadButton("TOPRIGHT", -26, P.fonts.button)
	win.segText = seg.t
	seg:SetScript("OnClick", function() S().meterOverall = not S().meterOverall; P:UpdateMeter() end)
	local reset = P:CloseButton(win, function()
		if DM.ResetAllCombatSessions then pcall(DM.ResetAllCombatSessions) end
		P:UpdateMeter()
	end)
	reset.t:SetText(""); reset.tip = "Start over (your range is kept)"
	reset.icon = reset:CreateTexture(nil, "ARTWORK"); reset.icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
	reset.icon:SetSize(12, 12); reset.icon:SetPoint("CENTER"); reset.icon:SetVertexColor(0.6, 0.65, 0.7)
	reset:SetPoint("TOPRIGHT", -4, -2)

	-- the group line under the rows
	win.group = win:CreateFontString(nil, "OVERLAY"); win.group:SetFontObject(P.fonts.head)
	win.group:SetJustifyH("LEFT")

	-- your panel: this fight's number, moving along your range
	local y = CreateFrame("Frame", nil, win)
	y:SetHeight(54)
	win.you = y
	win.group:SetPoint("BOTTOMLEFT", y, "TOPLEFT", 0, 5)
	local line = y:CreateTexture(nil, "ARTWORK"); line:SetHeight(1)
	line:SetPoint("TOPLEFT", -2, 0); line:SetPoint("TOPRIGHT", 2, 0); line:SetColorTexture(1, 1, 1, 0.08)
	y.label = y:CreateFontString(nil, "OVERLAY"); y.label:SetFontObject(P.fonts.button); y.label:SetPoint("TOPLEFT", 0, -6)
	y.value = y:CreateFontString(nil, "OVERLAY"); y.value:SetFontObject(P.fonts.title); y.value:SetPoint("TOPRIGHT", 0, -4)
	y.bar = CreateFrame("StatusBar", nil, y)
	y.bar:SetHeight(8); y.bar:SetPoint("TOPLEFT", 26, -26); y.bar:SetPoint("TOPRIGHT", -26, -26)
	y.bar:SetStatusBarTexture(P.WHITE)
	y.bar.bg = y.bar:CreateTexture(nil, "BACKGROUND"); y.bar.bg:SetAllPoints(); y.bar.bg:SetColorTexture(1, 1, 1, 0.08)
	y.avgTick = y.bar:CreateTexture(nil, "OVERLAY"); y.avgTick:SetSize(2, 14); y.avgTick:SetColorTexture(1, 1, 1, 0.95)
	y.lo = y:CreateFontString(nil, "OVERLAY"); y.lo:SetFontObject(P.fonts.small); y.lo:SetPoint("RIGHT", y.bar, "LEFT", -4, 0)
	y.hi = y:CreateFontString(nil, "OVERLAY"); y.hi:SetFontObject(P.fonts.small); y.hi:SetPoint("LEFT", y.bar, "RIGHT", 4, 0)
	y.sub = y:CreateFontString(nil, "OVERLAY"); y.sub:SetFontObject(P.fonts.head); y.sub:SetPoint("TOPLEFT", 0, -40)
	y.sub:SetPoint("RIGHT", 0, 0); y.sub:SetJustifyH("LEFT")
	y.bar:SetScript("OnEnter", function(self)
		local m = Mode()
		local lo, hi, avg, n = Stats(m.key)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("Your " .. m.rate .. " range")
		if n then
			GameTooltip:AddDoubleLine("Worst fight", Short(lo), 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:AddDoubleLine("Average (by fighting time)", Short(avg), 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:AddDoubleLine("Best fight", Short(hi), 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:AddLine(("From your last %d fights of %d seconds or more."):format(n, MIN_FIGHT), 0.6, 0.62, 0.66, true)
		else
			GameTooltip:AddLine("Each fight of " .. MIN_FIGHT .. " seconds or more adds to it.", 0.6, 0.62, 0.66, true)
		end
		GameTooltip:AddLine("The colored bar is this fight; the white tick is your average.", 0.6, 0.62, 0.66, true)
		GameTooltip:Show()
	end)
	y.bar:SetScript("OnLeave", GameTooltip_Hide)

	-- live: a few times a second in a fight, now and then otherwise
	local t = 0
	win:SetScript("OnUpdate", function(_, dt)
		t = t + dt
		if t < (UnitAffectingCombat("player") and 0.3 or 2) then return end
		t = 0
		P:UpdateMeter()
	end)
	P.Perf.Hook(win, "Damage meter", "OnUpdate")
	if P.ApplySizes then P:ApplySizes() end
end

function P:RefreshMeter()
	local want = S().meter and self:MeterAvailable()
	if want and S().meterCombatOnly then
		want = UnitAffectingCombat("player") or (self.meterLinger and GetTime() < self.meterLinger)
	end
	if want then
		if not win then Build() end
		win:Show()
		self:UpdateMeter()
	elseif win then
		win:Hide()
	end
end

P:Listen("READY", function() P:RefreshMeter() end)
P:Listen("SETTINGS_CHANGED", function() P:RefreshMeter() end)
P:On("PLAYER_REGEN_DISABLED", function() P:RefreshMeter() end)
P:On("PLAYER_REGEN_ENABLED", function()
	P.meterLinger = GetTime() + 20                 -- the result stays a moment after the fight
	P:RefreshMeter()
	C_Timer.After(1.5, Record)                     -- the numbers can be read again a moment after
	C_Timer.After(20.5, function() P:RefreshMeter() end)
end)
for _, ev in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED", "DAMAGE_METER_RESET" }) do
	P:On(ev, function() if win and win:IsShown() then P:Debounce("meter", 0.25, function() P:UpdateMeter() end) end end)
end
end part() end
-- ==================== Buttons.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — minimap buttons
     One Pathway button: click it for everything (guide, journal, closest quests,
     find the nearest, parts on and off, the minimap's menu), right-click for
     settings. Journal, Next set, Find and Parts can be separate buttons too. With
     Pathway's minimap on they sit in its button bar with the calendar and the
     rest; with Blizzard's minimap they ring its edge (drag to move them). ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local cos, sin, rad, deg, atan2 = math.cos, math.sin, math.rad, math.deg, math.atan2

local function S() return P.db.settings end

local DEFS = {
	{ key = "Journal", icon = "Interface\\Icons\\INV_Misc_Book_09", angle = 200,
		tip = { "Quest journal", "Click: what suits you now, and every zone, chain and quest", "Right-click: this zone's guides" },
		click = function(b, button) if button == "RightButton" then P:ZoneMenu(b) else P:ToggleJournal("home") end end },
	{ key = "Next", icon = "Interface\\Icons\\INV_Misc_Map_01", angle = 222,
		tip = { "Next set", "Click: go to the closest quests for you", "Right-click: stop navigating" },
		click = function(_, button) if button == "RightButton" then P:StopRoute() else P:StartRoute("next") end end },
	{ key = "Find", icon = "Interface\\Icons\\INV_Misc_Spyglass_02", angle = 244,
		tip = { "Find the nearest", "Repair, food, innkeeper, trainers, bank, auction house" },
		click = function(b) P.Find:Menu(b) end },
	{ key = "Modes", icon = "Interface\\Icons\\INV_Misc_Gear_01", angle = 288,
		tip = { "Pathway parts", "Turn each part on or off in a click" },
		click = function(b) P:ModesMenu(b) end },
	{ key = "Pathway", icon = "Interface\\AddOns\\Pathway\\Media\\Icon", angle = 266, full = true, main = true,
		tip = { "Pathway", "Click: everything Pathway does", "Right-click: settings" },
		click = function(b, button) if button == "RightButton" then P:OpenSettings() else P:MainMenu(b) end end },
	{ key = "Guide", icon = "Interface\\Icons\\Ability_Hunter_Pathfinding", angle = 310, main = true, nav = true,
		tip = { "Guide and arrow", "Click: turn the guide and the arrow off (or back on) together" },
		click = function() P:ToggleNavigation() end },
	{ key = "Travel", icon = "Interface\\Icons\\INV_Misc_Map02", angle = 332, main = true,
		show = function() return S().travelButton ~= false end,
		tip = { "Go anywhere", "Click: pick a zone, and the fastest way there from here", "Flights, boats, zeppelins, the tram, your hearthstone, teleports" },
		click = function(b) P:ToggleGoTo(b) end },
	{ key = "Outfits", icon = "Interface\\Icons\\INV_Chest_Cloth_17", angle = 354, main = true,
		show = function() return S().outfitsButton ~= false and P.HasOutfits and P:HasOutfits() end,
		tip = { "Outfits", "Click: put on one of your saved outfits" },
		click = function(b) P:ToggleOutfits(b) end },
	-- the bell: beside the map (under the holiday button on Pathway's minimap), not in the bar
	{ key = "Notes", icon = "Interface\\AddOns\\Pathway\\Media\\Bell", angle = 200, main = true, badge = true, float = true,
		show = function() return P.notes and #P.notes > 0 end,
		tip = { "Notifications", "What Pathway told you lately", "Upgrades wait here with an Equip button" },
		click = function(b) P:ToggleNotes(b) end },
}

local buttons = {}

-- the guide and the arrow, on or off together (one click on the minimap bar)
function P:NavigationOn() return S().arrow ~= false or S().guideWindow ~= false end
function P:ToggleNavigation()
	local on = not self:NavigationOn()
	P.SetSetting("arrow", on)
	P.SetSetting("guideWindow", on)
	if on and self.SetGuideState then self:SetGuideState("open") end
	self:Toast(on and "Guide and arrow on" or "Guide, arrow and route off: the path button on the minimap bar brings them back")
	self:UpdateMinimapButtons()
end

-- every part, with a check when it's on (the last three need a quick reload)
local MODES = {
	{ "Guide" },
	{ "Arrow", "arrow" }, { "Step guide window", "guideWindow" }, { "Your quests in the guide", "tidyTracker" }, { "Quest bar", "questBar" }, { "Magic button", "magicButton" },
	{ "Paths on the minimap", "minimapPath" }, { "Quest spots on the minimap", "questLayer" }, { "Quest pins on the minimap", "gmPins" },
	{ "Auto accept and turn in", "autoAccept" },
	{ "Go anywhere button", "travelButton" }, { "Outfits button", "outfitsButton" },
	{ "Helpers" },
	{ "Gear upgrade prompts", "gearAlerts" }, { "Talent suggestions", "talentHints" },
	{ "Combat pulse on the minimap", "combatPulse" }, { "Nearby enemy alert", "aggroAlert" }, { "Town services on the minimap", "serviceZoom" },
	{ "Step tips", "stepHints" }, { "WoW-Pro tips", "wowproTips" },
	{ "Player cards", "pvpCard" }, { "Rare and elite cards", "mobCard" }, { "Damage meter", "meter" }, { "Performance meter", "fps" }, { "Level pace", "levelPace" },
	{ "Add-ons" },
	{ "Bags", "bags", true }, { "Minimap", "goodmap", true }, { "Fishing", "fishing", true },
}

function P:ModesMenu(owner)
	local menu = MenuUtil or P.MiniMenu
	menu.CreateContextMenu(owner, function(_, root)
		root:CreateTitle(P.TITLE or "Pathway")
		for i, m in ipairs(MODES) do
			if not m[2] then
				if i > 1 then root:CreateDivider() end
				root:CreateTitle(P.DIM .. m[1] .. "|r")
			else
				root:CreateCheckbox(m[1], function() return P.GetSetting(m[2]) and true or false end, function()
					P.SetSetting(m[2], not P.GetSetting(m[2]))
					if m[3] then StaticPopup_Show("PATHWAY_RELOAD") end
				end)
			end
		end
		root:CreateDivider()
		root:CreateButton("All settings", function() P:OpenSettings() end)
	end)
end

-- the one button: every part of Pathway, a click away
function P:MainMenu(owner)
	local menu = MenuUtil or P.MiniMenu
	menu.CreateContextMenu(owner, function(_, root)
		root:CreateTitle(P.TITLE or "Pathway")
		local guideOn = P:GuideState() == "open"
		root:CreateButton(guideOn and "Hide the guide" or "Show the guide", function() P:ToggleGuide() end)
		root:CreateButton("Closest quests for me", function() P:StartRoute("next") end)
		root:CreateButton("Quest journal", function() P:ToggleJournal("home") end)
		local zone = P:PlayerZone()
		local zg = root:CreateButton("This zone")
		zg:CreateButton("Storyline", function() P:PlayZone(zone, "story") end)
		zg:CreateButton("All quests, chain to chain", function() P:PlayZone(zone, "all") end)
		zg:CreateButton("Fastest XP", function() P:PlayZone(zone, "fast") end)
		zg:CreateButton("Open in the journal", function() P:ShowZoneInJournal(zone) end)
		local fd = root:CreateButton("Find the nearest")
		if P.Find and P.Find.FillMenu then P.Find:FillMenu(fd) end
		if P.route then
			root:CreateButton("Skip this step", function() P:SkipStop() end)
			root:CreateButton("Stop this guide", function() P:StopRoute() end)
		end
		root:CreateDivider()
		local parts = root:CreateButton("Turn parts on or off")
		for i, m in ipairs(MODES) do
			if not m[2] then
				if i > 1 then parts:CreateDivider() end
				parts:CreateTitle(m[1])
			else
				parts:CreateCheckbox(m[1], function() return P.GetSetting(m[2]) and true or false end, function()
					P.SetSetting(m[2], not P.GetSetting(m[2]))
					if m[3] then StaticPopup_Show("PATHWAY_RELOAD") end
				end)
			end
		end
		local E = P.GoodMap and P.GoodMap.E
		if P.GoodMap and P.GoodMap.ready and E and E.ShowMenu then
			root:CreateButton("Minimap menu", function() C_Timer.After(0, function() E.ShowMenu(owner) end) end)
		end
		root:CreateButton("Style the minimap", function() P:ShowMapLook(true) end)
		root:CreateButton("Setup: parts, size, color", function() P:ShowParts() end)
		root:CreateButton("All settings", function() P:OpenSettings() end)
	end)
end

local function Place(b)
	if b.float then
		local E = P.GoodMap and P.GoodMap.E
		if P.GoodMapShown and P:GoodMapShown() and E and E.PlaceNotes then E.PlaceNotes() return end
		-- a layer above the minimap's own frames, so nothing over it takes its clicks
		if b:GetParent() ~= Minimap then b:SetParent(Minimap) end
		b:SetFrameStrata("HIGH"); b:SetFrameLevel(50)
	end
	if b.docked then return end
	local a = rad((P.db.pos.mmAngles or {})[b.def.key] or b.def.angle)
	local r = (Minimap:GetWidth() / 2) + 8
	b:ClearAllPoints()
	b:SetPoint("CENTER", Minimap, "CENTER", cos(a) * r, sin(a) * r)
end

local function MakeFloat(def)
	-- named without "Minimap", so the minimap's bar leaves it alone
	local b = CreateFrame("Button", "PathwayNotesButton", Minimap)
	b.def, b.float = def, true
	b:SetSize(28, 28)
	b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask"); b.bg:SetAllPoints()
	b.bg:SetVertexColor(0, 0, 0, 0.8)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetTexture(def.icon); b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 0)
	b.icon:SetVertexColor(1, 0.80, 0.32)
	b.ring = b:CreateTexture(nil, "OVERLAY")
	b.ring:SetTexture(P.MEDIA .. "Ring"); b.ring:SetAllPoints(); b.ring:SetVertexColor(A[1], A[2], A[3], 0.55)
	P:OnPaint(function() b.ring:SetVertexColor(A[1], A[2], A[3], 0.55) end)
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
	return b
end

local function Make(def)
	local b = def.float and MakeFloat(def) or CreateFrame("Button", "PathwayMinimap" .. def.key, Minimap)
	b.def = def
	if def.float then
		b:SetScript("OnClick", function(self, button) def.click(self, button) end)
		if def.badge then
			b.badge = b:CreateTexture(nil, "OVERLAY", nil, 2); b.badge:SetTexture(P.MEDIA .. "Dot")
			b.badge:SetSize(14, 14); b.badge:SetPoint("TOPRIGHT", 3, 3); b.badge:SetVertexColor(A[1], A[2], A[3], 1)
			b.badgeText = b:CreateFontString(nil, "OVERLAY", nil, 3); b.badgeText:SetFontObject(P.fonts.small)
			b.badgeText:SetPoint("CENTER", b.badge, "CENTER", 0, 0)
			b.badge:Hide(); b.badgeText:SetText("")
			P:OnPaint(function() b.badge:SetVertexColor(A[1], A[2], A[3], 1) end)
		end
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText(def.tip[1], 1, 1, 1)
			for i = 2, #def.tip do GameTooltip:AddLine(def.tip[i], 0.7, 0.75, 0.8) end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		Place(b)
		return b
	end
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); b.bg:SetSize(24, 24); b.bg:SetPoint("CENTER")
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetTexture(def.icon); b.icon:SetSize(18, 18); b.icon:SetPoint("CENTER")
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.mask = b:CreateMaskTexture()
	b.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	b.mask:SetAllPoints(b.icon)
	b.icon:AddMaskTexture(b.mask)
	b.border = b:CreateTexture(nil, "OVERLAY")
	b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); b.border:SetSize(52, 52); b.border:SetPoint("TOPLEFT")
	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
	b:SetScript("OnClick", function(self, button) def.click(self, button) end)
	if def.badge then
		b.badge = b:CreateTexture(nil, "OVERLAY", nil, 2); b.badge:SetTexture(P.MEDIA .. "Dot")
		b.badge:SetSize(14, 14); b.badge:SetPoint("TOPRIGHT", 1, 1); b.badge:SetVertexColor(A[1], A[2], A[3], 1)
		b.badgeText = b:CreateFontString(nil, "OVERLAY", nil, 3); b.badgeText:SetFontObject(P.fonts.small)
		b.badgeText:SetPoint("CENTER", b.badge, "CENTER", 0, 0)
		b.badge:Hide(); b.badgeText:SetText("")
		P:OnPaint(function() b.badge:SetVertexColor(A[1], A[2], A[3], 1) end)
	end
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText(def.tip[1] .. (def.nav and (P:NavigationOn() and "  |cff66bf73on|r" or "  |cff8a929boff|r") or ""), 1, 1, 1)
		for i = 2, #def.tip do GameTooltip:AddLine(def.tip[i], 0.7, 0.75, 0.8) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	-- drag around the Blizzard minimap's edge
	b:SetScript("OnDragStart", function(self)
		if self.docked then return end
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local x, y = GetCursorPosition()
			local s = Minimap:GetEffectiveScale()
			local a = deg(atan2(y / s - my, x / s - mx))
			P.db.pos.mmAngles = P.db.pos.mmAngles or {}
			P.db.pos.mmAngles[def.key] = a
			Place(self)
		end)
	end)
	b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	Place(b)
	return b
end

function P:UpdateMinimapButtons()
	local on = S().minimapButtons ~= false
	for _, b in ipairs(buttons) do
		-- one button by default; the separate ones if you'd rather
		b:SetShown(on and (b.def.main or S().separateButtons == true) and (not b.def.show or b.def.show() and true or false))
		-- Pathway's minimap docks them in its bar; it moves them itself (the bell it places beside the map)
		b.docked = not b.float and b:GetParent() ~= Minimap
		if not b.docked then Place(b) end
		if b.def.nav then
			local on = P:NavigationOn()
			b.icon:SetDesaturated(not on); b.icon:SetAlpha(on and 1 or 0.5)
		end
	end
end

P:Listen("READY", function()
	if not Minimap then return end
	for _, def in ipairs(DEFS) do buttons[#buttons + 1] = Make(def) end
	P:UpdateMinimapButtons()
	-- ask the minimap's bar to take them in
	local E = P.GoodMap and P.GoodMap.E
	if E and E.QueueLooseScan then E.QueueLooseScan(1) end
	C_Timer.After(5, function()
		if E and E.QueueLooseScan then E.QueueLooseScan(0.1) end
		P:UpdateMinimapButtons()
	end)
end)
P:Listen("SETTINGS_CHANGED", function() if buttons[1] then P:UpdateMinimapButtons() end end)
-- the bell follows Pathway's minimap in and out
function P:PlaceNotesButton()
	local b = _G.PathwayNotesButton
	if b then Place(b) end
end
end part() end
-- ==================== Obtain.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — "How do I get that?"
     Ctrl+Alt-click any item (in chat, a tooltip link, your bags, a vendor, the
     auction house...) and Pathway tells you where it comes from and offers to
     take you there: the quest chain that rewards it, the nearest vendor that
     sells it, or where it drops. Pets, mounts and other curios included. ]]

local ADDON, P = __addon, __ns
local K = P.K
local floor = math.floor

local function S() return P.db.settings end

local function ItemID(link)
	if type(link) == "number" then return link end
	local id = type(link) == "string" and link:match("item:(%d+)")
	return id and tonumber(id)
end

local function ItemName(id)
	local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or (GetItemInfo and GetItemInfo(id))
	return name or (P.SRC[id] and P.SRC[id][1]) or ("item " .. id)
end

-- the nearest place an NPC (or object) stands, for "how far"
local function Where(kind, ids)
	local inst, px, py = P:PlayerPos()
	local best, bd, bmap
	for _, id in ipairs(ids or {}) do
		local d, m = P:Nearest({ { kind, id } }, inst, px, py)
		if d and (not bd or d < bd) then best, bd, bmap = id, d, m end
	end
	if not best then
		for _, id in ipairs(ids or {}) do
			local _, m = P:Nearest({ { kind, id } })
			if m then return id, nil, m end
		end
	end
	return best, bd, bmap
end

-- the best quest to follow for a reward: one you can do, or the start of its chain
local function RewardQuest(list)
	local best
	for _, qid in ipairs(list or {}) do
		if not P.done[qid] then
			if P.log[qid] or P:Available(qid) then return qid end
			best = best or qid
		end
	end
	return best
end

function P:Sources(id)
	local src = self.SRC and self.SRC[id]
	if not src then return end
	local out = {}
	local qid = RewardQuest(src[2])
	if qid then
		local ch
		if self.Cat then self.Cat:Build(); ch = self.Cat.chainOf[qid] end
		out[#out + 1] = { kind = "quest", qid = qid, chain = ch,
			label = ch and ("Quest chain: " .. ch.name) or ("Quest: " .. self.Q[qid][K.NAME]),
			text = ("A reward from |cffffffff%s|r%s"):format(self.Q[qid][K.NAME], ch and (P.DIM .. (" (step %d of a %d-quest chain)"):format(
				(function() for i, q in ipairs(ch.quests) do if q == qid then return i end end return 1 end)(), #ch.quests) .. "|r") or "") }
	end
	local v, vd, vm = Where("N", src[3])
	if v and vd and vd < 40 then
		-- you're standing at the vendor: nothing to go to
		out[#out + 1] = { kind = "here", text = ("Sold right here by |cffffffff%s|r"):format(self:EntityName("N", v)) }
		v = nil
	end
	if v then
		out[#out + 1] = { kind = "buy", npc = v, label = "Buy it", text = ("Sold by |cffffffff%s|r, %s%s"):format(self:EntityName("N", v),
			self:MapName(vm), vd and (P.DIM .. (" · %d yd|r"):format(floor(vd))) or "") }
	end
	local d, dd, dm = Where("N", src[4])
	if d then
		out[#out + 1] = { kind = "drop", npc = d, label = "Farm it", text = ("Drops from |cffffffff%s|r, %s%s"):format(self:EntityName("N", d),
			self:MapName(dm), dd and (P.DIM .. (" · %d yd|r"):format(floor(dd))) or "") }
	end
	local o, od, om = Where("O", src[5])
	if o then
		out[#out + 1] = { kind = "object", obj = o, label = "Find it", text = ("Found in |cffffffff%s|r, %s"):format(self:EntityName("O", o), self:MapName(om)) }
	end
	if #out == 0 then return end
	return out
end

-- one short line for tooltips: the best way to get it (cached a little: tooltips redraw often)
local lineCache = {}
function P:SourceLine(id)
	local c = lineCache[id]
	if c and GetTime() - c[2] < 30 then return c[1] end
	local list = self:Sources(id)
	local first = list and list[1]
	local text = first and first.text and first.text:gsub("%s*|cff6b7480 ·.-|r", "") or nil
	lineCache[id] = { text, GetTime() }
	return text
end

function P:GoGet(id, s)
	local name = ItemName(id)
	if s.kind == "quest" then
		if s.chain then return self:LoadGuide("chain:" .. s.chain.id) end
		return self:LoadGuide("quest:" .. s.qid)
	end
	local ent = s.kind == "object" and { "O", s.obj } or { "N", s.npc }
	local verb = s.kind == "buy" and "Buy " or s.kind == "drop" and "Farm " or "Get "
	return self:StartRoute("next", { single = { key = "get" .. id, goal = verb .. name, ents = { ent }, name = self:EntityName(ent[1], ent[2]), far = true },
		title = "Getting " .. name })
end

-- the card: where it comes from, and a button for each way
function P:ObtainPrompt(id)
	local list = self:Sources(id)
	local name = ItemName(id)
	local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)) or (GetItemIcon and GetItemIcon(id))
	if not list then
		self:Toast("Pathway doesn't know where " .. name .. " comes from")
		return
	end
	local lines, buttons = {}, { { "Not now", function() end } }
	for i, s in ipairs(list) do
		lines[#lines + 1] = s.text
		local label = s.kind == "quest" and (s.chain and "Follow the chain" or "Do the quest") or s.label
		if s.label and #buttons <= 3 then buttons[#buttons + 1] = { label, function() self:GoGet(id, s) end, #buttons == 1 } end
	end
	self:Ask({ key = "obtain", icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark", title = "Get " .. name .. "?",
		text = table.concat(lines, "\n"), buttons = buttons })
end

-- on sale at the vendor you have open?
local function AtMerchant(id)
	if not (MerchantFrame and MerchantFrame:IsShown()) or not GetMerchantNumItems then return false end
	for i = 1, GetMerchantNumItems() do
		local link = GetMerchantItemLink(i)
		if link and ItemID(link) == id then return true end
	end
	return false
end

-- Ctrl+Alt-click on any item link or item button
hooksecurefunc("HandleModifiedItemClick", function(link)
	if not (P.db and S().obtain) or not (IsControlKeyDown() and IsAltKeyDown()) then return end
	local id = ItemID(link)
	if not id then return end
	if AtMerchant(id) then P:Toast("It's right here: buy it from this vendor") return end
	P:ObtainPrompt(id)
end)

-- a line on tooltips of things Pathway can take you to
local function OnItem(tt)
	if not (P.db and S().obtain) or not tt.GetItem then return end
	local _, link = tt:GetItem()
	local id = ItemID(link)
	if id and P.SRC and P.SRC[id] and (P.Item.GetItemCount or GetItemCount)(id) == 0 and not AtMerchant(id) then
		-- where it comes from, in one line, then how to get a guide there
		local where = P:SourceLine(id)
		if where then tt:AddLine("|c" .. P.ACCENT_HEX .. "Pathway|r  " .. where, 0.85, 0.87, 0.9, true) end
		tt:AddLine(P.DIM .. "Ctrl+Alt-click for a guide to get it|r")
	end
end
P:Listen("READY", function()
	if TooltipDataProcessor and Enum.TooltipDataType and Enum.TooltipDataType.Item then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt) if tt == GameTooltip or tt == ItemRefTooltip then pcall(OnItem, tt) end end)
	else
		GameTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(OnItem, tt) end)
		if ItemRefTooltip then ItemRefTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(OnItem, tt) end) end
	end
end)

-- /pw get <item link or name>
function P:ObtainSlash(arg)
	local id = ItemID(arg)
	if not id and arg and arg ~= "" then
		local want = arg:lower()
		for iid, row in pairs(self.SRC) do if row[1]:lower() == want then id = iid break end end
		if not id then for iid, row in pairs(self.SRC) do if row[1]:lower():find(want, 1, true) then id = iid break end end end
	end
	if id then self:ObtainPrompt(id) else self:Print("Ctrl+Alt-click an item, or /pw get <item name>") end
end
end part() end
-- ==================== GearFinder.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Upgrades you can get
     A panel beside your character window: for each slot, the best upgrade
     you can get now (quest rewards from quests you're on or can start now), how much better it is for you, and
     where it comes from. "Go" puts it in your guide; without a guide, the
     item's tooltip says where it comes from anyway. ]]

local ADDON, P = __addon, __ns
local A = P.ACCENT
local floor, max, min = math.floor, math.max, math.min

local function S() return P.db.settings end
local function Instant(id) return (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(id) end
local function Info(id) return (C_Item and C_Item.GetItemInfo or GetItemInfo)(id) end

local SLOT_NAME = { [1] = "Head", [2] = "Neck", [3] = "Shoulders", [5] = "Chest", [6] = "Waist", [7] = "Legs", [8] = "Feet",
	[9] = "Wrists", [10] = "Hands", [11] = "Ring", [12] = "Ring", [13] = "Trinket", [14] = "Trinket", [15] = "Back",
	[16] = "Main hand", [17] = "Off hand", [18] = "Ranged" }

-- what each class can wear and wield (armor from level 40 where classes step up)
local CLOTH, LEATHER, MAIL, PLATE, SHIELD = 1, 2, 3, 4, 6
local ARMOR = {
	WARRIOR = { [CLOTH] = 1, [LEATHER] = 1, [MAIL] = 1, [PLATE] = 40, [SHIELD] = 1 },
	PALADIN = { [CLOTH] = 1, [LEATHER] = 1, [MAIL] = 1, [PLATE] = 40, [SHIELD] = 1 },
	HUNTER = { [CLOTH] = 1, [LEATHER] = 1, [MAIL] = 40 }, SHAMAN = { [CLOTH] = 1, [LEATHER] = 1, [MAIL] = 40, [SHIELD] = 1 },
	ROGUE = { [CLOTH] = 1, [LEATHER] = 1 }, DRUID = { [CLOTH] = 1, [LEATHER] = 1 },
	MAGE = { [CLOTH] = 1 }, PRIEST = { [CLOTH] = 1 }, WARLOCK = { [CLOTH] = 1 },
}
-- weapon subclasses: 0 1h axe, 1 2h axe, 2 bow, 3 gun, 4 1h mace, 5 2h mace, 6 polearm, 7 1h sword,
-- 8 2h sword, 10 staff, 13 fist, 15 dagger, 16 thrown, 18 crossbow, 19 wand
local WEAPON = {
	WARRIOR = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 }, PALADIN = { 0, 1, 4, 5, 6, 7, 8 },
	HUNTER = { 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18 }, ROGUE = { 2, 3, 4, 7, 13, 15, 16, 18 },
	SHAMAN = { 0, 1, 4, 5, 10, 13, 15 }, DRUID = { 4, 5, 6, 10, 13, 15 },
	MAGE = { 7, 10, 15, 19 }, PRIEST = { 4, 10, 15, 19 }, WARLOCK = { 7, 10, 15, 19 },
}
local SKIP_LOC = { [""] = true, INVTYPE_BAG = true, INVTYPE_TABARD = true, INVTYPE_BODY = true, INVTYPE_AMMO = true, INVTYPE_QUIVER = true }

local function CanUse(id, cls, lvl)
	local _, _, _, loc, _, classID, sub = Instant(id)
	if not loc or SKIP_LOC[loc] then return false end
	if classID == 4 then                              -- armor
		if sub == 0 then return true end              -- rings, necks, trinkets, cloaks...
		local need = ARMOR[cls] and ARMOR[cls][sub]
		return need ~= nil and lvl >= need
	elseif classID == 2 then
		for _, w in ipairs(WEAPON[cls] or {}) do if w == sub then return true end end
		return false
	end
	return false
end

-- a quest to get it from that you can do right now: one you're on, or one you
-- can start now. Soloable only: no dungeon quests (unless you've asked for them)
-- and no elites above your level unless you're in a group.
local function QuestFor(rewardOf)
	local start
	for _, qid in ipairs(rewardOf or {}) do
		if not P.done[qid] and (S().dungeonQuests or not P:DungeonQuest(qid)) and not P:TooHardSolo(qid) then
			if P.log[qid] then return qid, "on" end
			if not start and P:Available(qid) then start = qid end
		end
	end
	if start then return start, "now" end
end

---------------------------------------------------------------------------
-- Finding them (item details load from the server as needed, then it updates)
---------------------------------------------------------------------------
local best, pending, scanning = {}, {}, false
local function Scan()
	wipe(best); wipe(pending)
	local cls = P.me and P.me.classFile or select(2, UnitClass("player"))
	local lvl = UnitLevel("player") or 1
	for id, src in pairs(P.SRC or {}) do
		if src[2] then
			local qid, when = QuestFor(src[2])
			if qid and CanUse(id, cls, lvl) then
				local up = P:CompareToEquipped("item:" .. id)
				if up == "loading" then
					pending[id] = { qid, when }
					if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
				elseif type(up) == "table" then
					local req = select(5, Info(id)) or 0
					if req <= lvl + 2 then
						local cur = best[up.slot]
						local pct = up.gain
						local rank = when == "on" and 2 or 1
						if not cur or rank > cur.rank or (rank == cur.rank and pct > cur.pct) then
							best[up.slot] = { id = id, up = up, pct = pct, qid = qid, when = when, req = req, rank = rank }
						end
					end
				end
			end
		end
	end
	if P.RenderGearFinder then P:RenderGearFinder() end
	return best, pending
end
function P:ScanGearFinder() return Scan() end
-- can your class and level wear or wield it (armor type, weapon kind)?
function P:CanUseGear(id)
	return CanUse(id, P.me and P.me.classFile or select(2, UnitClass("player")), UnitLevel("player") or 1)
end

---------------------------------------------------------------------------
-- The panel
---------------------------------------------------------------------------
local panel, rows = nil, {}
local ORDER = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }

local function Row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, panel)
	r:SetHeight(50)
	r:SetPoint("TOPLEFT", 10, -54 - (i - 1) * 52); r:SetPoint("RIGHT", -10, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.04)
	r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(32, 32); r.icon:SetPoint("LEFT", 2, 0)
	r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	r.name = r:CreateFontString(nil, "OVERLAY"); r.name:SetFontObject(P.fonts.button)
	r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1); r.name:SetPoint("RIGHT", -52, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
	r.sub = r:CreateFontString(nil, "OVERLAY"); r.sub:SetFontObject(P.fonts.head)
	r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.sub:SetPoint("RIGHT", -52, 0); r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
	r.src = r:CreateFontString(nil, "OVERLAY"); r.src:SetFontObject(P.fonts.head)
	r.src:SetPoint("TOPLEFT", r.sub, "BOTTOMLEFT", 0, -3); r.src:SetPoint("RIGHT", -52, 0); r.src:SetJustifyH("LEFT"); r.src:SetWordWrap(false)
	r.go = P:FlatButton(r, "Go", true); r.go.minW = 40; r.go:SetLabel("Go")
	r.go:SetPoint("RIGHT", 0, 0)
	r:SetScript("OnEnter", function(self)
		if not self.id then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:" .. self.id)
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", GameTooltip_Hide)
	rows[i] = r
	return r
end

function P:RenderGearFinder()
	if not (panel and panel:IsShown()) then return end
	local n = 0
	local seen = {}
	for _, slot in ipairs(ORDER) do
		local b = best[slot]
		if b and not seen[b.id] then
			seen[b.id] = true
			n = n + 1
			local r = Row(n)
			r.id = b.id
			local name, _, quality, _, _, _, _, _, _, icon = Info(b.id)
			local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
			r.icon:SetTexture(icon or select(5, Instant(b.id)))
			r.name:SetText((c and c.hex or "|cffffffff") .. (name or ("item " .. b.id)) .. "|r")
			local q = P.Q[b.qid]
			local when = b.when == "on" and "|cff66bf73on your list|r" or "|cffffd27acan start now|r"
			-- what you gain: the stats, not a percentage (an empty slot has nothing to compare)
			local diff = P.GearDiff and P:GearDiff(b.up) or ""
			r.sub:SetText("|cffd8dde3" .. (SLOT_NAME[slot] or "") .. "|r  " .. (b.up.oldLink and diff or ("|cff7cf29cfills your empty slot|r  " .. diff)))
			r.src:SetText(P.DIM .. (q and q[P.K.NAME] or "?") .. "  ·  |r" .. when)
			r.go:Show()
			r.go.tip = b.when == "on" and "Your guide takes you through this quest" or "Your guide takes you to pick this quest up"
			r.go:SetScript("OnClick", function()
				P:FollowQuest(b.qid)
			end)
			r:Show()
		end
	end
	for i = n + 1, #rows do rows[i]:Hide() end
	local waiting = 0
	for _ in pairs(pending) do waiting = waiting + 1 end
	panel.status:SetText(P.DIM .. (n == 0 and (waiting > 0 and "Looking through quest rewards…" or "Nothing better from quests you can do right now.")
		or ("%d upgrade%s from quests you can do now"):format(n, n == 1 and "" or "s")) .. "|r")
	panel:SetHeight(max(120, 60 + n * 52 + 10))
end

local function Build()
	panel = CreateFrame("Frame", "PathwayGearFinder", CharacterFrame, "BackdropTemplate")
	P.Flat(panel, nil, nil, true)
	panel:SetWidth(320)
	-- clear of the character window's side tabs, and below the arrow at the top
	panel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 40, -36)
	panel:SetClampedToScreen(true)
	panel:EnableMouse(true)
	local t = panel:CreateFontString(nil, "OVERLAY"); t:SetFontObject(P.fonts.title); t:SetPoint("TOPLEFT", 12, -12)
	t:SetText("Upgrades you can get")
	panel.status = panel:CreateFontString(nil, "OVERLAY"); panel.status:SetFontObject(P.fonts.head)
	panel.status:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -4)
	local x = P:CloseButton(panel, function() P.db.gearFinderOpen = false; panel:Hide() end); x:SetPoint("TOPRIGHT", -6, -6)
	panel:SetScript("OnShow", function() C_Timer.After(0, Scan) end)
	panel:Hide()
	if P.ApplySizes then P:ApplySizes() end
end

function P:ToggleGearFinder()
	if not CharacterFrame then return end
	if not panel then Build() end
	local open = not panel:IsShown()
	P.db.gearFinderOpen = open
	panel:SetShown(open)
end

-- a small button on the character window
P:Listen("READY", function()
	if not CharacterFrame then return end
	local b = P:FlatButton(CharacterFrame, "Upgrades", true)
	b:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -28, -30)
	b:SetFrameLevel(CharacterFrame:GetFrameLevel() + 20)
	b.tip = "Better gear from quests you can do now"
	b:SetScript("OnClick", function() P:ToggleGearFinder() end)
	CharacterFrame:HookScript("OnShow", function()
		b:SetShown(S().gearAlerts ~= false)
		if P.db.gearFinderOpen and S().gearAlerts ~= false then
			if not panel then Build() end
			panel:Show()
		end
	end)
end)
P:On("GET_ITEM_INFO_RECEIVED", function(_, id)
	if panel and panel:IsShown() and pending[id] then P:Debounce("gearfinder", 0.4, Scan) end
end)
P:On("PLAYER_EQUIPMENT_CHANGED", function() if panel and panel:IsShown() then P:Debounce("gearfinder", 0.4, Scan) end end)
P:Listen("QUESTS_CHANGED", function() if panel and panel:IsShown() then P:Debounce("gearfinder", 1, Scan) end end)
end part() end
-- ==================== Creatures.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Rares, elites and bosses
     Hover one (or target it) and a card says what it is, how tough it is for
     you, which of your quests needs it, and what it drops: icons you can hover,
     link and look up. Anything that's an upgrade for you glows green; anything
     worth having (rare quality, a pet or mount, a recipe, good money) glows gold.

     Elite quests above your level stay out of your guide while you're on your
     own, until you meet one: target it or walk up to it (or its quest giver) and
     it joins the guide with a warning; Skip leaves it again. ]]

local ADDON, P = __addon, __ns
local floor, max, min, sqrt = math.floor, math.max, math.min, math.sqrt
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EMPTY = {}

local function S() return P.db.settings end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function N(v) if v == nil or Secret(v) then return nil end return v end
local function On() return P.db and S().mobCard ~= false end
local function Info(id) return (C_Item and C_Item.GetItemInfo or GetItemInfo)(id) end
local function Instant(id) return (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(id) end

local function NpcId(unit)
	local g = N(UnitGUID(unit))
	if not g then return end
	local kind, _, _, _, _, id = strsplit("-", g)
	if kind == "Creature" or kind == "Vehicle" then return tonumber(id), g end
end

-- what kind of creature: "worldboss" | "rareelite" | "elite" | "rare" | nil
local function Kind(unit)
	local c = N(UnitClassification(unit))
	if c == "worldboss" or c == "rareelite" or c == "elite" or c == "rare" then return c end
	local lvl = N(UnitLevel(unit))
	if lvl == -1 then return "worldboss" end
end
local KIND = {
	worldboss = { "Boss", { 0.92, 0.3, 0.28 } },
	rareelite = { "Rare elite", { 0.78, 0.84, 0.95 } },
	elite = { "Elite", { 1, 0.78, 0.3 } },
	rare = { "Rare", { 0.78, 0.84, 0.95 } },
}

---------------------------------------------------------------------------
-- Elite quests you've met: they join your guide
---------------------------------------------------------------------------
P.eliteOK = P.eliteOK or {}

-- the elites a quest needs (killed, or dropping what it needs)
local eliteOf = {}
local function QuestElites(qid)
	local c = eliteOf[qid]
	if c then return c end
	c = {}
	local q, K = P.Q[qid], P.K
	local function check(id)
		local e = P.N[id]
		if e and (e[5] == 1 or e[5] == 2 or e[5] == 3) then c[#c + 1] = id end
	end
	if q then
		for _, id in ipairs(q[K.ON] or EMPTY) do check(id) end
		for _, iid in ipairs(q[K.OI] or EMPTY) do
			local it = P.I[iid]
			if it and it[2] and #it[2] <= 3 then for _, id in ipairs(it[2]) do check(id) end end
		end
	end
	eliteOf[qid] = c
	return c
end
function P:QuestElites(qid) return QuestElites(qid) end

local function Offer(qid, why)
	if P.eliteOK[qid] then return end
	P.eliteOK[qid] = true
	local q = P.Q[qid]
	local lvl = P:QuestElite(qid)
	P:Toast(("%s (elite%s) is in your guide now%s. Skip it if you'd rather not."):format(
		q and q[P.K.NAME] or "That quest", lvl and (" " .. lvl) or "", why and (": " .. why) or ""), true)
	P:Send("QUESTS_CHANGED")
end

-- targeting an elite one of your quests needs
P:On("PLAYER_TARGET_CHANGED", function()
	if not P.db then return end
	local id = NpcId("target")
	if not id then return end
	for qid, e in pairs(P.log or EMPTY) do
		if not e.complete and P:TooHardSolo(qid) then
			for _, nid in ipairs(QuestElites(qid)) do
				if nid == id then Offer(qid, "you found it") return end
			end
		end
	end
end)

-- walking up to one (or to the quest giver of an elite quest)
local NEAR, GIVER = 120, 40
local function Near(ents, inst, px, py, yards)
	local d = P:Nearest(ents, inst, px, py)
	return d and d <= yards * yards
end
local eliteFor, eliteList
local function Look()
	if not (P.db and P.log) or UnitOnTaxi("player") then return end
	if not (P.route and P:RouteShown()) then return end   -- no guide showing: nothing to add an elite to
	if IsInGroup and IsInGroup() then return end           -- in a group nothing is held back anyway
	local inst, px, py = P:PlayerPos()
	if not inst then return end
	for qid, e in pairs(P.log) do
		if not e.complete and not P.eliteOK[qid] and P:TooHardSolo(qid) then
			local ents = {}
			for _, id in ipairs(QuestElites(qid)) do ents[#ents + 1] = { "N", id } end
			if #ents > 0 and Near(ents, inst, px, py, NEAR) then Offer(qid, "it's close by") return end
		end
	end
	local K = P.K
	-- the elite quests among what you can pick up (only worked out again when that changes)
	local list = P:AvailableList()
	if eliteFor ~= list then
		eliteFor, eliteList = list, {}
		for _, qid in ipairs(list) do if P:QuestElite(qid) then eliteList[#eliteList + 1] = qid end end
	end
	for _, qid in ipairs(eliteList) do
		if not P.eliteOK[qid] and P:TooHardSolo(qid) then
			local q = P.Q[qid]
			local ents = {}
			for _, id in ipairs(q[K.SN] or EMPTY) do ents[#ents + 1] = { "N", id } end
			if #ents > 0 and Near(ents, inst, px, py, GIVER) then Offer(qid, "its quest giver is right here") return end
		end
	end
end
C_Timer.NewTicker(3, function() if P.db and P:RouteShown() and not InCombatLockdown() then pcall(Look) end end)

---------------------------------------------------------------------------
-- What it drops: an upgrade for you, or worth having
---------------------------------------------------------------------------
local GOOD = { upgrade = { 0.3, 1, 0.45 }, worth = { 1, 0.8, 0.25 }, collect = { 0.75, 0.45, 1 } }
local function Worth(id)
	local name, link, quality, _, _, _, _, _, equipLoc, _, price, classID, _, bind = Info(id)
	if not name then return nil, true end                     -- still loading
	if (classID == 2 or classID == 4) and P.CanUseGear and P:CanUseGear(id) and P.CompareToEquipped then
		local up = P:CompareToEquipped(link or ("item:" .. id))
		if type(up) == "table" and (up.gain or 0) > 0 then return "upgrade" end
	end
	if classID == 15 then
		local _, _, _, _, _, _, sub = Instant(id)
		if sub == 2 or sub == 5 then return "collect" end      -- pets, mounts
	end
	if classID == 9 then return "worth" end                    -- recipes sell and teach
	if (quality or 0) >= 3 then return "worth" end
	if bind == 2 and (quality or 0) >= 2 then return "worth" end   -- green or better, sells on the auction house
	local lvl = UnitLevel("player") or 1
	if (price or 0) >= max(5000, lvl * lvl * 25) then return "worth" end
	return nil
end

---------------------------------------------------------------------------
-- The card
---------------------------------------------------------------------------
local card
local ICON, PER_ROW = 34, 6

local function IconButton(i)
	local b = card.icons[i]
	if b then return b end
	b = CreateFrame("Button", nil, card.drops)
	b:SetSize(ICON, ICON)
	b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetAllPoints(); b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.edge = b:CreateTexture(nil, "BORDER"); b.edge:SetPoint("TOPLEFT", -1, 1); b.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	b.edge:SetColorTexture(0, 0, 0, 1)
	-- the glow: a soft halo that breathes
	b.glow = b:CreateTexture(nil, "OVERLAY")
	b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	b.glow:SetBlendMode("ADD")
	b.glow:SetPoint("CENTER"); b.glow:SetSize(ICON * 1.9, ICON * 1.9)
	b.pulse = b.glow:CreateAnimationGroup()
	b.pulse:SetLooping("BOUNCE")
	local a = b.pulse:CreateAnimation("Alpha"); a:SetFromAlpha(0.35); a:SetToAlpha(1); a:SetDuration(0.8)
	b.glow:Hide()
	b:RegisterForClicks("LeftButtonUp")
	b:SetScript("OnEnter", function(self)
		if not self.id then return end
		card.hold = true
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:" .. self.id)
		if self.why == "upgrade" then GameTooltip:AddLine("An upgrade for you", 0.3, 1, 0.45)
		elseif self.why == "collect" then GameTooltip:AddLine("A collectible", 0.75, 0.45, 1)
		elseif self.why == "worth" then GameTooltip:AddLine("Worth keeping or selling", 1, 0.8, 0.25) end
		GameTooltip:AddLine("Shift-click to link it, Ctrl-click to try it on", 0.5, 0.55, 0.6)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() card.hold = nil; GameTooltip_Hide() end)
	b:SetScript("OnClick", function(self)
		if not self.id then return end
		local _, link = Info(self.id)
		if HandleModifiedItemClick and link then HandleModifiedItemClick(link) end
	end)
	card.icons[i] = b
	return b
end

local function Build()
	card = CreateFrame("Frame", "PathwayMobCard", UIParent, "BackdropTemplate")
	if P.ApplySizes then P:ApplySizes() end
	card:SetSize(248, 10)
	card:SetFrameStrata("TOOLTIP")
	card:SetClampedToScreen(true)
	card:EnableMouse(true)
	P:TooltipSkin(card)
	card.band = card:CreateTexture(nil, "BORDER")
	card.band:SetPoint("TOPLEFT", 4, -4); card.band:SetPoint("TOPRIGHT", -4, -4); card.band:SetHeight(41)
	card.band:SetTexture(WHITE)
	local function fs(font)
		local f = card:CreateFontString(nil, "OVERLAY"); f:SetFontObject(font); f:SetJustifyH("LEFT"); return f
	end
	card.name = fs(P.tipFonts.head); card.name:SetPoint("TOPLEFT", 10, -9); card.name:SetPoint("RIGHT", -54, 0); card.name:SetWordWrap(false)
	card.level = fs(P.fonts.big); card.level:SetPoint("TOPRIGHT", -10, -7); card.level:SetJustifyH("RIGHT")
	card.sub = fs(P.tipFonts.small); card.sub:SetPoint("TOPLEFT", 10, -28); card.sub:SetTextColor(1, 1, 1)
	card.hp = CreateFrame("StatusBar", nil, card)
	card.hp:SetPoint("BOTTOMLEFT", 5, 5); card.hp:SetPoint("BOTTOMRIGHT", -5, 5); card.hp:SetHeight(6)
	card.hp:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); card.hp:SetStatusBarColor(0.85, 0.3, 0.28, 1)
	card.hp.bg = card.hp:CreateTexture(nil, "BACKGROUND"); card.hp.bg:SetAllPoints(); card.hp.bg:SetColorTexture(0, 0, 0, 0.5)
	card.lines = {}
	for i = 1, 3 do
		local l = fs(P.tipFonts.small); l:SetTextColor(1, 1, 1); l:SetPoint("TOPLEFT", 10, -54 - (i - 1) * 16); l:SetPoint("RIGHT", -10, 0); l:SetWordWrap(false)
		card.lines[i] = l
	end
	card.dropHead = fs(P.tipFonts.small); card.dropHead:SetTextColor(1, 0.82, 0)
	card.drops = CreateFrame("Frame", nil, card)
	card.icons = {}
	card:SetScript("OnUpdate", function(self)
		-- still on it (hovering it, targeting it, or using the drop icons): fully shown
		local over = self:IsMouseOver() or self.hold
		local here = self.guid and ((N(UnitGUID("mouseover")) == self.guid) or (N(UnitGUID("target")) == self.guid))
		if over or here then self.leaving = nil; self:SetAlpha(min(1, self:GetAlpha() + 0.15)) return end
		local now = GetTime()
		self.leaving = self.leaving or now
		local t, hold, fade = now - self.leaving, S().cardLinger or 1.5, 1
		if t > hold + fade then self:Hide() return end
		self:SetAlpha(t <= hold and 1 or (1 - (t - hold) / fade))
	end)
	P.Perf.Hook(card, "Rare and elite cards", "OnUpdate")
	card:SetScript("OnHide", function(self) self.leaving, self.guid = nil, nil end)
	card:Hide()
end

local function Odds(unit, kind)
	local mine = UnitLevel("player") or 1
	local lvl = N(UnitLevel(unit)) or mine
	if lvl == -1 then return "|cffff5a4aA raid boss: bring a raid|r" end
	local d = lvl - mine
	local elite = kind == "elite" or kind == "rareelite" or kind == "worldboss"
	if elite and d >= 2 then return "|cffff5a4aToo tough alone: bring a group|r" end
	if elite and d >= -1 then return "|cffff8c4dTough: bring a friend or two|r" end
	if elite then return "|cffffd27aDoable alone if you're careful|r" end
	if d >= 3 then return "|cffff8c4dA few levels above you: careful|r" end
	return "|cff66bf73You can take it on|r"
end

local function QuestLine(id)
	for qid, e in pairs(P.log or EMPTY) do
		if not e.complete then
			for _, nid in ipairs(QuestElites(qid)) do
				if nid == id then return qid end
			end
			local q = P.Q[qid]
			for _, nid in ipairs(q and q[P.K.ON] or EMPTY) do if nid == id then return qid end end
		end
	end
end

local pendingItems = {}
local function Fill(unit)
	local id, guid = NpcId(unit)
	local kind = Kind(unit)
	if not (id and kind) then return false end
	if not card then Build() end
	card.guid, card.unit, card.npc = guid, unit, id
	local k = KIND[kind]
	local c = k[2]
	card:SetBackdropBorderColor(c[1], c[2], c[3], 0.9)
	card.band:SetVertexColor(c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 0.95)
	card.name:SetText(N(UnitName(unit)) or "")
	local lvl = N(UnitLevel(unit))
	card.level:SetText(lvl == -1 and "|cffff5a4a??|r" or tostring(lvl or ""))
	local ctype = N(UnitCreatureType(unit))
	card.sub:SetText(("|cff%02x%02x%02x%s|r"):format(c[1] * 255, c[2] * 255, c[3] * 255, k[1]) .. (ctype and ("  ·  " .. ctype) or ""))
	local hp, hpMax = N(UnitHealth(unit)), N(UnitHealthMax(unit))
	if hp and hpMax and hpMax > 0 then card.hp:SetMinMaxValues(0, hpMax); card.hp:SetValue(hp); card.hp:Show() else card.hp:Hide() end
	-- what it means for you
	local lines = { Odds(unit, kind) }
	local qid = QuestLine(id)
	if qid then
		local q = P.Q[qid]
		local inGuide = not P:TooHardSolo(qid)
		lines[#lines + 1] = "|cffffd200Your quest:|r " .. (q and q[P.K.NAME] or "") .. (inGuide and (P.DIM .. "  (in your guide)|r") or "")
	end
	local y = -54
	for i, l in ipairs(card.lines) do
		if lines[i] then l:SetText(lines[i]); l:Show(); y = -54 - i * 16 else l:Hide() end
	end
	-- what it drops
	local ids = P.LOOT and P.LOOT[id] or EMPTY
	local n, loading = 0, false
	for _, iid in ipairs(ids) do
		local why, wait = Worth(iid)
		if wait then
			loading = true
			pendingItems[iid] = true
			if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(iid) end
		end
		n = n + 1
		local b = IconButton(n)
		b.id, b.why = iid, why
		b.tex:SetTexture(select(5, Instant(iid)) or 134400)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", ((n - 1) % PER_ROW) * (ICON + 4), -floor((n - 1) / PER_ROW) * (ICON + 4))
		if why then
			local g = GOOD[why]
			b.glow:SetVertexColor(g[1], g[2], g[3], 1); b.glow:Show(); b.pulse:Play()
		else
			b.glow:Hide(); b.pulse:Stop()
		end
		b:Show()
	end
	for i = n + 1, #card.icons do card.icons[i]:Hide(); card.icons[i].id = nil end
	if n > 0 then
		local up, good = 0, 0
		for i = 1, n do local w = card.icons[i].why; if w == "upgrade" then up = up + 1 elseif w then good = good + 1 end end
		card.dropHead:ClearAllPoints(); card.dropHead:SetPoint("TOPLEFT", 10, y - 6)
		card.dropHead:SetText("DROPS" .. P.DIM .. "  ·  " .. (up > 0 and ("|cff4dff73" .. up .. " upgrade" .. (up == 1 and "" or "s") .. "|r  ") or "")
			.. (good > 0 and ("|cffffcc40" .. good .. " worth having|r") or (up == 0 and "nothing you need" or "")) .. "|r")
		card.dropHead:Show()
		card.drops:ClearAllPoints(); card.drops:SetPoint("TOPLEFT", 10, y - 22)
		local rows = math.ceil(n / PER_ROW)
		card.drops:SetSize(PER_ROW * (ICON + 4), rows * (ICON + 4)); card.drops:Show()
		y = y - 22 - rows * (ICON + 4)
	else
		card.dropHead:Hide(); card.drops:Hide()
	end
	card:SetHeight(-y + 18)
	card.loading = loading
	-- where it goes: the player card's spot, or beside the tooltip
	card:ClearAllPoints()
	if S().cardSpot == "fixed" then
		P:PlaceAt(card, "PathwayPlayerCard")
	elseif GameTooltip:IsShown() then
		local left = tonumber(GameTooltip:GetLeft()) or 0
		if left > (tonumber(card:GetWidth()) or 248) + 20 then card:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", -4, 0)
		else card:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 4, 0) end
	else
		P:PlaceAt(card, "PathwayPlayerCard")
	end
	if not card:IsShown() then card:SetAlpha(0) end
	card.leaving = nil
	card:Show()
	return true
end

local function Show(unit)
	if not On() or not UnitExists(unit) or N(UnitIsPlayer(unit)) then return end
	-- only what you could fight: a flight master or a city guard is elite, but no foe
	if not N(UnitCanAttack("player", unit)) then return end
	if card and card.hold then return end                     -- you're looking at its drops
	local ok = pcall(Fill, unit)
	if not ok and card then card:Hide() end
end
P:On("UPDATE_MOUSEOVER_UNIT", function() if On() then C_Timer.After(0, function() Show("mouseover") end) end end)
P:On("PLAYER_TARGET_CHANGED", function() if not InCombatLockdown() then Show("target") end end)
P:On("UNIT_HEALTH", function(_, unit)
	if card and card:IsShown() and unit == "target" and N(UnitGUID("target")) == card.guid then
		local hp = N(UnitHealth("target")); if hp then card.hp:SetValue(hp) end
	end
end)
P:On("GET_ITEM_INFO_RECEIVED", function(_, id)
	if card and card:IsShown() and card.loading and pendingItems[id] and card.unit and N(UnitGUID(card.unit)) == card.guid then
		P:Debounce("mobcard", 0.3, function() pcall(Fill, card.unit) end)
	end
end)
function P:MobCardFrame() if not card then Build() end return card end
end part() end
-- ==================== Danger.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Combat and danger
     Two things on the minimap that help you stay alive:

       · In combat its edge pulses red, so a fight you didn't notice starting
         (a pat from behind, a pet pulling) is hard to miss.
       · A hostile creature that isn't fighting you yet but is almost close
         enough to notice you gets called out: the edge pulses amber and a
         short line names it ("Defias Pillager (17) is close").

     How close is "close": a creature notices you from about 20 yards at your
     level, a yard more for each level it has on you and a yard less for each
     level you have on it. The game doesn't tell addons where creatures are, so
     Pathway asks, for each enemy nameplate on screen, which range bands it is
     inside. That needs enemy nameplates to be showing (the V key).

     Both can be turned off, and nothing runs while they are. ]]

local ADDON, P = __addon, __ns
local floor, max, min = math.floor, math.max, math.min
local EMPTY = {}

local function S() return P.db.settings end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function N(v) if v == nil or Secret(v) then return nil end return v end

local RED, AMBER = { 1, 0.16, 0.12 }, { 1, 0.66, 0.1 }

---------------------------------------------------------------------------
-- The pulse on the minimap's edge
---------------------------------------------------------------------------
local fx, fxFor
local function MapParts()
	local NS = P.GoodMap
	if not (NS and NS.ready and NS.S and NS.S.map and NS.S.sc) then return end
	return NS.S, NS.E
end

local function BuildFx(GS)
	fx = CreateFrame("Frame", nil, GS.map)
	fx:SetFrameLevel(9390)
	fx.ring = fx:CreateTexture(nil, "OVERLAY")
	fx.ring:SetBlendMode("ADD")
	fx.anim = fx:CreateAnimationGroup()
	fx.anim:SetLooping("BOUNCE")
	fx.a = fx.anim:CreateAnimation("Alpha")
	fx.a:SetFromAlpha(0.25); fx.a:SetToAlpha(1); fx.a:SetDuration(0.6); fx.a:SetSmoothing("IN_OUT")
	fx:Hide()
	fxFor = GS.map
end

local shown        -- "combat" | "near" | nil
local function Pulse(kind)
	if kind == shown then return end
	local GS, E = MapParts()
	if not GS or not GS.map:IsShown() then
		if fx then fx.anim:Stop(); fx:Hide() end
		shown = nil
		return
	end
	if not fx or fxFor ~= GS.map then BuildFx(GS) end
	shown = kind
	if not kind then fx.anim:Stop(); fx:Hide() return end
	local c = kind == "combat" and RED or AMBER
	fx:ClearAllPoints()
	fx.ring:ClearAllPoints()
	if GS.round then
		-- a halo whose bright band sits on the round map's edge
		local d = tonumber(E.Diameter()) or 220
		fx:SetPoint("CENTER", GS.sc, "CENTER")
		fx:SetSize(d * 1.25, d * 1.25)
		fx.ring:SetTexture("Interface\\AddOns\\Pathway\\GoodMap\\Textures\\Halo")
	else
		-- a square map: its edges glow inward
		fx:SetAllPoints(GS.sc)
		fx.ring:SetTexture("Interface\\AddOns\\Pathway\\GoodMap\\Textures\\Flight-Vignette")
	end
	fx.ring:SetAllPoints(fx)
	fx.ring:SetVertexColor(c[1], c[2], c[3], kind == "combat" and 0.9 or 0.8)
	fx.a:SetDuration(kind == "combat" and 0.55 or 0.9)
	fx.anim:Stop()
	fx:Show()
	fx.anim:Play()
end

---------------------------------------------------------------------------
-- The line that names what's close
---------------------------------------------------------------------------
local note
local function BuildNote()
	note = CreateFrame("Frame", "PathwayDanger", UIParent)
	note:SetSize(260, 18)
	note:SetFrameStrata("MEDIUM")
	note.text = note:CreateFontString(nil, "OVERLAY")
	note.text:SetFontObject(P.fonts.small)
	note.text:SetPoint("CENTER")
	note.fade = note:CreateAnimationGroup()
	local a = note.fade:CreateAnimation("Alpha")
	a:SetFromAlpha(1); a:SetToAlpha(0); a:SetStartDelay(2.5); a:SetDuration(0.8)
	note.fade:SetScript("OnFinished", function() note:Hide() end)
	note:Hide()
end
local function Say(text)
	if not note then BuildNote() end
	note:ClearAllPoints()
	local GS = MapParts()
	if GS and GS.map:IsShown() then note:SetPoint("TOP", GS.sc, "BOTTOM", 0, -30)
	else note:SetPoint("TOP", UIParent, "TOP", 0, -150) end
	note.text:SetText(text)
	note.fade:Stop()
	note:SetAlpha(1)
	note:Show()
	note.fade:Play()
end

---------------------------------------------------------------------------
-- How far is it? The smallest range band the creature is inside.
---------------------------------------------------------------------------
-- items whose use range the game will check against a unit, by yards
local ITEM_BANDS = { { 10, 32321 }, { 15, 33069 }, { 20, 10645 }, { 25, 24268 }, { 30, 835 }, { 35, 18904 }, { 40, 28767 } }
local ItemInRange = (C_Item and C_Item.IsItemInRange) or IsItemInRange
local function Within(unit, combat)
	-- interact distances first (out of combat only): about 10 and 28 yards
	if not combat and CheckInteractDistance then
		local ok, near = pcall(CheckInteractDistance, unit, 3)
		if ok and N(near) then return 10 end
	end
	if ItemInRange then
		for _, band in ipairs(ITEM_BANDS) do
			local ok, inside = pcall(ItemInRange, band[2], unit)
			inside = ok and N(inside)
			if inside == true or inside == 1 then return band[1] end
		end
	end
	if not combat and CheckInteractDistance then
		local ok, near = pcall(CheckInteractDistance, unit, 4)
		if ok and N(near) then return 28 end
	end
end

-- how far away a creature notices you
function P:AggroRange(unit)
	local mine = UnitLevel("player") or 1
	local lvl = N(UnitLevel(unit)) or mine
	if lvl == -1 then lvl = mine + 10 end
	return max(5, min(45, 20 + (lvl - mine)))
end

local function Threat(unit)
	if not N(UnitExists(unit)) or N(UnitIsDead(unit)) then return end
	if N(UnitIsPlayer(unit)) or (UnitPlayerControlled and N(UnitPlayerControlled(unit))) then return end
	if not N(UnitCanAttack("player", unit)) then return end
	local react = N(UnitReaction(unit, "player"))
	if not react or react > 3 then return end                 -- neutral creatures don't come for you
	if N(UnitAffectingCombat(unit)) then return end           -- already in a fight
	return true
end

local told, lastSound = {}, 0
local function Scan()
	if not P.db or S().aggroAlert == false then return nil end
	if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") or (IsResting and IsResting()) then return nil end
	if IsInInstance and IsInInstance() then return nil end    -- a dungeon pull is on purpose
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return nil end
	local combat = InCombatLockdown()
	local best, bestGap, bestBand
	for _, plate in ipairs(C_NamePlate.GetNamePlates() or EMPTY) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit and Threat(unit) then
			local band = Within(unit, combat)
			if band then
				local gap = band - P:AggroRange(unit)          -- yards left before it notices you, at most
				if gap <= 8 and (not bestGap or gap < bestGap) then best, bestGap, bestBand = unit, gap, band end
			end
		end
	end
	if not best then return nil end
	local guid = N(UnitGUID(best)) or best
	local now = GetTime()
	if (told[guid] or 0) < now - 12 then
		told[guid] = now
		local name, lvl = N(UnitName(best)) or "Something", N(UnitLevel(best))
		local kind = N(UnitClassification(best))
		local tag = (kind == "elite" or kind == "rareelite" or kind == "worldboss") and "|cffff5a4aelite|r " or ""
		Say(("|cffffb020%s%s%s|r %s"):format(tag, name, lvl and lvl > 0 and (" (" .. lvl .. ")") or "",
			bestGap <= 0 and "has almost noticed you" or "is close"))
		if S().aggroSound ~= false and now - lastSound > 6 then
			lastSound = now
			PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959)
		end
	end
	return true
end

---------------------------------------------------------------------------
-- Keeping it going: one slow ticker while either part is on
---------------------------------------------------------------------------
local ticker
local function Tick()
	if not P.db then return end
	local s = S()
	local combat = InCombatLockdown() and s.combatPulse ~= false
	local near = false
	if s.aggroAlert ~= false then
		local ok, r = pcall(Scan)
		near = ok and r or false
	end
	-- a creature closing in outranks the steady combat pulse: it's the news
	Pulse(near and "near" or combat and "combat" or nil)
	-- forget what was called out a while ago
	local now = GetTime()
	for g, t in pairs(told) do if now - t > 60 then told[g] = nil end end
end
local function Arm()
	if fx then shown = nil; fx.anim:Stop(); fx:Hide() end     -- the map's shape or size may have changed: draw it fresh
	local s = P.db and S()
	local on = s and (s.combatPulse ~= false or s.aggroAlert ~= false)
	if on and not ticker then
		ticker = C_Timer.NewTicker(0.5, P.Perf.W("Combat and danger alerts", Tick))
	elseif not on and ticker then
		ticker:Cancel(); ticker = nil
		Pulse(nil)
	end
end
P:Listen("READY", Arm)
P:Listen("SETTINGS_CHANGED", Arm)
P:On("PLAYER_REGEN_DISABLED", function() if P.db and S().combatPulse ~= false then Pulse("combat") end end)
P:On("PLAYER_REGEN_ENABLED", function() if shown == "combat" then Pulse(nil) end end)
function P:DangerTick() Tick() end
end part() end
-- ==================== Learn.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Learning what the data doesn't know yet
     When the game adds quests Pathway's data doesn't have (or has without a
     location), Pathway learns them as you play:
       · who gave it and where, when you accept it
       · where the objectives are: where you were, and what you'd just killed,
         each time the count goes up
       · who takes it back, when you turn it in
       · quests a giver offers that aren't in the data at all
     What it learns is shared by all your characters and works right away:
     pins, routes and guides use it like the rest of the data.
     /pw learned shows what it knows, ready to send us for the next update. ]]

local ADDON, P = __addon, __ns
local K = P.K
local floor = math.floor

local function S() return P.db.settings end
local function L() return P.db and P.db.learned end

local function NpcFromGUID(guid)
	if not guid or (issecretvalue and issecretvalue(guid)) then return end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind == "Creature" then return tonumber(id), "N" end
	if kind == "GameObject" then return tonumber(id), "O" end
end

local function Here()
	local map = C_Map.GetBestMapForUnit("player")
	local pos = map and C_Map.GetPlayerMapPosition(map, "player")
	if not pos then return end
	local x, y = pos.x, pos.y
	if pos.GetXY then x, y = pos:GetXY() end
	if not x then return end
	return map, x, y
end
-- which quests came with Pathway (the rest were learned)
P.base = P.base or {}
for qid in pairs(P.Q) do P.base[qid] = true end

local function Pack(x, y) return floor(x * 10000 + 0.5) * 10001 + floor(y * 10000 + 0.5) end

local function Q(qid)
	local l = L()
	local q = l.q[qid]
	if not q then q = { pts = {}, mobs = {} }; l.q[qid] = q end
	return q
end

-- remember where an NPC or object stands
local function Entity(id, kind, name, map, x, y)
	if not (id and map) then return end
	local l = L()
	local key = kind .. id
	local e = l.e[key]
	if not e then e = { name = name, spots = {} }; l.e[key] = e end
	if name and name ~= "" then e.name = name end
	e.spots[map] = e.spots[map] or {}
	local list = e.spots[map]
	for _, p in ipairs(list) do
		local px, py = P.Unpack(p)
		if (px - x) ^ 2 + (py - y) ^ 2 < 0.0004 then return end       -- already have this spot
	end
	if #list < 8 then list[#list + 1] = Pack(x, y) end
end

-- does the shipped data already cover this?
local function Known(qid)
	local q = P.base and P.base[qid]
	return q ~= nil
end

---------------------------------------------------------------------------
-- Put what we've learned into the data the rest of Pathway uses
---------------------------------------------------------------------------
local applied = {}

local function ApplyLearned(self)
	local l = L()
	if not l then return end
	-- entities first, so quests can point at them
	for key, e in pairs(l.e) do
		local kind, id = key:sub(1, 1), tonumber(key:sub(2))
		local t = kind == "N" and self.N or self.O
		if id and not t[id] then
			local spawns = {}
			for map, list in pairs(e.spots) do spawns[map] = list end
			t[id] = { e.name or "?", spawns }
		end
	end
	for qid, lq in pairs(l.q) do
		local q = self.Q[qid]
		if not q then
			q = { lq.name or ("Quest " .. qid), lq.req or 0, lq.lvl or 0 }
			self.Q[qid] = q
		end
		-- fill only what the data doesn't have
		if not q[K.SN] and not q[K.SO] and lq.sN then q[lq.sKind == "O" and K.SO or K.SN] = { lq.sN } end
		if not q[K.EN] and not q[K.EO] and lq.eN then q[lq.eKind == "O" and K.EO or K.EN] = { lq.eN } end
		if not q[K.ON] and not q[K.OO] and not q[K.OI] then
			local mobs = {}
			for _, list in pairs(lq.mobs) do for _, id in ipairs(list) do mobs[#mobs + 1] = id end end
			if #mobs > 0 then q[K.ON] = mobs
			elseif not q[K.TRIGMAP] then
				for _, pts in pairs(lq.pts) do
					if pts[1] then q[K.TRIGMAP], q[K.TRIGPT] = pts[1][1], pts[1][2]; break end
				end
			end
		end
		if not q[K.ZONE] and lq.zone then q[K.ZONE] = lq.zone; if P.questZones then P.questZones[lq.zone] = true end end
		self:IndexQuest(qid, q)
		applied[qid] = true
	end
	for qid in pairs(l.open or {}) do
		local q = self.Q[qid]
		if q then q[K.PRE], q[K.PREANY] = nil, nil end
	end
	if self.Cat then self.Cat:Reset() end
	if self.Invalidate then self:Invalidate() end
end
function P:ApplyLearned()
	ApplyLearned(self)
	if self.ResetCandidates then self:ResetCandidates() end
end

---------------------------------------------------------------------------
-- The data says a quest needs another one first, but the game offers it:
-- the game is right. Remember that, and stop holding it back.
---------------------------------------------------------------------------
local function Blocked(q)
	for _, id in ipairs(q[K.PRE] or {}) do if not P.done[id] then return true end end
	local pa = q[K.PREANY]
	if pa then
		for _, id in ipairs(pa) do if P.done[id] then return false end end
		return true
	end
	return false
end
function P:QuestOffered(qid)
	local q = qid and self.Q[qid]
	local l = L()
	if not (q and l) or not Blocked(q) then return end
	l.open = l.open or {}
	l.open[qid] = true
	q[K.PRE], q[K.PREANY] = nil, nil
	if self.Invalidate then self:Invalidate() end
	if self.Cat then self.Cat:Reset() end
end

---------------------------------------------------------------------------
-- Watching
---------------------------------------------------------------------------
local function Interesting(qid)
	local q = P.Q[qid]
	if not q or applied[qid] or not Known(qid) then return true end
	-- known, but with nowhere to send you
	return not (q[K.ON] or q[K.OO] or q[K.OI] or q[K.TRIGMAP]) or not (q[K.SN] or q[K.SO] or q[K.SI])
end

P:On("QUEST_DETAIL", function()
	if P.db and GetQuestID then P:QuestOffered(GetQuestID()) end
end)

P:On("QUEST_ACCEPTED", function(_, a, b)
	if not P.db then return end
	P:QuestOffered(b or a)
	if not S().learn then return end
	local qid = b or a
	if not qid or not Interesting(qid) then return end
	local q = Q(qid)
	local e = P.log[qid]
	q.name = q.name or (C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(qid)) or (e and e.title)
	local map, x, y = Here()
	q.zone = q.zone or (map and P:ZoneOf(map))
	local id, kind = NpcFromGUID(UnitGUID("npc"))
	if id and map then
		q.sN, q.sKind = id, kind
		Entity(id, kind, UnitName("npc"), map, x, y)
	end
	if C_QuestLog and C_QuestLog.GetQuestDifficultyLevel then q.lvl = q.lvl or C_QuestLog.GetQuestDifficultyLevel(qid) end
	q.seen = time()
	P:Debounce("learn", 1, function() P:ApplyLearned() end)
end)

P:On("QUEST_TURNED_IN", function(_, qid)
	if not (P.db and S().learn) or not qid or not L().q[qid] and not Interesting(qid) then return end
	local q = Q(qid)
	local map, x, y = Here()
	local id, kind = NpcFromGUID(UnitGUID("npc"))
	if id and map then
		q.eN, q.eKind = id, kind
		Entity(id, kind, UnitName("npc"), map, x, y)
	end
	P:Debounce("learn", 1, function() P:ApplyLearned() end)
end)

-- objective counts going up: where you were, and what you'd just dealt with
local counts = {}
local lastKill                       -- { id, name, t }
P:On("PLAYER_TARGET_CHANGED", function()
	local id, kind = NpcFromGUID(UnitGUID("target"))
	if id and kind == "N" then
		local n = UnitName("target")
		if issecretvalue and issecretvalue(n) then n = nil end
		lastKill = { id = id, name = n, t = GetTime(), target = true }
	end
end)
local function Counted()
	if not (P.db and S().learn) then return end
	for qid, e in pairs(P.log) do
		if Interesting(qid) and e.objectives then
			for j, o in ipairs(e.objectives) do
				local have = o.numFulfilled or tonumber((o.text or ""):match("(%d+)%s*/%s*%d+")) or (o.finished and 1 or 0)
				local key = qid * 100 + j
				local before = counts[key]
				counts[key] = have
				if before and have > before then
					local q = Q(qid)
					q.name = q.name or e.title
					local map, x, y = Here()
					if map then
						q.zone = q.zone or P:ZoneOf(map)
						q.pts[j] = q.pts[j] or {}
						local list = q.pts[j]
						local near
						for _, p in ipairs(list) do if p[1] == map then local px, py = P.Unpack(p[2]); if (px - x) ^ 2 + (py - y) ^ 2 < 0.0009 then near = true end end end
						if not near and #list < 12 then list[#list + 1] = { map, Pack(x, y) } end
						-- a kill objective: the mob you were fighting
						if o.type == "monster" and lastKill and GetTime() - lastKill.t < 20 then
							q.mobs[j] = q.mobs[j] or {}
							local dup
							for _, id in ipairs(q.mobs[j]) do if id == lastKill.id then dup = true end end
							if not dup and #q.mobs[j] < 4 then q.mobs[j][#q.mobs[j] + 1] = lastKill.id end
							Entity(lastKill.id, "N", lastKill.name, map, x, y)
						end
					end
					P:Debounce("learn", 2, function() P:ApplyLearned() end)
				end
			end
		end
	end
end
P:Listen("QUESTS_CHANGED", Counted)
P:Listen("QUEST_PROGRESS", Counted)

-- quests a giver offers that the data has never heard of
P:On("GOSSIP_SHOW", function()
	if not (P.db and S().learn) or not (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then return end
	local id, kind = NpcFromGUID(UnitGUID("npc"))
	local map, x, y = Here()
	if not (id and map) then return end
	local added
	for _, info in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
		local qid = info.questID
		if qid and P.Q[qid] then P:QuestOffered(qid) end
		if qid and not P.Q[qid] then
			local q = Q(qid)
			q.name, q.lvl = info.title, info.questLevel
			q.sN, q.sKind, q.zone = id, kind, P:ZoneOf(map)
			added = true
		end
	end
	if added then
		Entity(id, kind, UnitName("npc"), map, x, y)
		P:Debounce("learn", 1, function() P:ApplyLearned() end)
	end
end)

P:Listen("READY", function()
	P.db.learned = P.db.learned or { q = {}, e = {} }
	P.db.learned.q = P.db.learned.q or {}
	P.db.learned.e = P.db.learned.e or {}
	P:ApplyLearned()
	P:Send("QUESTS_CHANGED")
end)

---------------------------------------------------------------------------
-- /pw learned: what Pathway has picked up, as text to send us
---------------------------------------------------------------------------
local box
function P:ShowLearned()
	local l = L()
	local lines, nq = {}, 0
	for qid, q in pairs(l.q) do
		nq = nq + 1
		local parts = { ("q%d=%q lvl=%s"):format(qid, q.name or "?", tostring(q.lvl or "?")) }
		if q.sN then parts[#parts + 1] = ("start=%s%d"):format(q.sKind or "N", q.sN) end
		if q.eN then parts[#parts + 1] = ("end=%s%d"):format(q.eKind or "N", q.eN) end
		for j, pts in pairs(q.pts) do
			local s = {}
			for _, p in ipairs(pts) do local x, y = P.Unpack(p[2]); s[#s + 1] = ("%d:%.1f,%.1f"):format(p[1], x * 100, y * 100) end
			parts[#parts + 1] = ("o%d=%s"):format(j, table.concat(s, ";"))
		end
		for j, m in pairs(q.mobs) do parts[#parts + 1] = ("m%d=%s"):format(j, table.concat(m, ",")) end
		lines[#lines + 1] = table.concat(parts, " ")
	end
	for key, e in pairs(l.e) do
		local s = {}
		for map, list in pairs(e.spots) do for _, p in ipairs(list) do local x, y = P.Unpack(p); s[#s + 1] = ("%d:%.1f,%.1f"):format(map, x * 100, y * 100) end end
		lines[#lines + 1] = ("%s=%q %s"):format(key, e.name or "?", table.concat(s, ";"))
	end
	if nq == 0 then self:Print("Nothing new learned yet: every quest so far is in Pathway's data.") return end
	if not box then
		box = CreateFrame("Frame", "PathwayLearned", UIParent, "BackdropTemplate")
		P.Flat(box, nil, nil, true)
		box:SetSize(560, 340); box:SetPoint("CENTER"); box:SetFrameStrata("DIALOG")
		box:EnableMouse(true); box:SetMovable(true); box:RegisterForDrag("LeftButton")
		box:SetScript("OnDragStart", box.StartMoving); box:SetScript("OnDragStop", box.StopMovingOrSizing)
		local title = box:CreateFontString(nil, "OVERLAY"); title:SetFontObject(P.fonts.title); title:SetPoint("TOPLEFT", 14, -12)
		title:SetText(P.TITLE .. P.DIM .. "  learned while you played|r")
		local hint = box:CreateFontString(nil, "OVERLAY"); hint:SetFontObject(P.fonts.head); hint:SetPoint("TOPLEFT", 14, -30)
		hint:SetText("Ctrl+A, Ctrl+C, and send it to us: it goes into the next update for everyone.")
		local close = P:CloseButton(box, function() box:Hide() end); close:SetPoint("TOPRIGHT", -6, -6)
		local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
		sf:SetPoint("TOPLEFT", 14, -50); sf:SetPoint("BOTTOMRIGHT", -32, 14)
		local eb = CreateFrame("EditBox", nil, sf)
		eb:SetMultiLine(true); eb:SetFontObject(P.fonts.button); eb:SetWidth(500); eb:SetAutoFocus(false)
		eb:SetScript("OnEscapePressed", function() box:Hide() end)
		sf:SetScrollChild(eb)
		box.eb = eb
		tinsert(UISpecialFrames, "PathwayLearned")
	end
	box.eb:SetText(table.concat(lines, "\n"))
	box:Show()
	box.eb:SetFocus(); box.eb:HighlightText()
end
end part() end
-- ==================== Places.lua
do local __addon, __ns = ... local function part()
-- Copyright (C) 2026 SoFinSicc. Part of Pathway (curseforge.com/wow/addons/pathway): free software under the GPLv3 or later, with additional terms that require keeping this credit. See LICENSE.md.
--[[ Pathway — Where exactly?
     "Head east, 230 yd" gets you close. These say the rest:
       · the place it's in: "inside Lion's Pride Inn", "in Fargodeep Mine (a cave)"
         learned as you play: each time you talk to someone, loot something or
         finish an objective, Pathway notes the subzone and whether you're indoors
         (shared by all your characters)
       · a landmark next to it: "by the inn", "next to the flight master",
         "near Smith Argus <Weaponsmith>"
       · what the quest itself says: "in the Fargodeep Mine", "at the top of the tower"
     It only ever says what it knows. ]]

local ADDON, P = __addon, __ns
local K = P.K
local floor, sqrt = math.floor, math.sqrt

local function S() return P.db.settings end
local function Places() return P.db and P.db.places end
local function Secret(v) return issecretvalue and issecretvalue(v) end

---------------------------------------------------------------------------
-- What a place is: a cave, a building, a tower...
---------------------------------------------------------------------------
local KINDS = {
	{ "mine", "cave" }, { "cave", "cave" }, { "cavern", "cave" }, { "grotto", "cave" }, { "den", "cave" },
	{ "burrow", "cave" }, { "barrow", "cave" }, { "tunnel", "cave" }, { "lair", "cave" }, { "hollow", "cave" },
	{ "crypt", "crypt" }, { "tomb", "crypt" }, { "catacomb", "crypt" },
	{ "tower", "tower" }, { "spire", "tower" }, { "lighthouse", "tower" },
	{ "inn", "building" }, { "tavern", "building" }, { "house", "building" }, { "hall", "building" },
	{ "keep", "building" }, { "chapel", "building" }, { "abbey", "building" }, { "cathedral", "building" },
	{ "barracks", "building" }, { "farm", "farm" }, { "mill", "building" }, { "smithy", "building" },
}
local KIND_WORD = { cave = "a cave", crypt = "a crypt", tower = "a tower", building = "a building", farm = "a farm" }

local function KindOf(name)
	local n = " " .. name:lower() .. " "
	for _, k in ipairs(KINDS) do
		if n:find("[%s%p]" .. k[1] .. "[s%s%p]") then return k[2] end
	end
end

---------------------------------------------------------------------------
-- Learning places
---------------------------------------------------------------------------
local function IdOf(guid)
	if not guid or Secret(guid) then return end
	local kind, _, _, _, _, id = strsplit("-", guid)
	if kind == "Creature" then return "N" .. id end
	if kind == "GameObject" then return "O" .. id end
end

-- the floor you're on: buildings with floors have a map per floor (the game's own)
local function FloorMap()
	local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if m and C_Map.GetMapGroupID and C_Map.GetMapGroupID(m) then return m end
end

local added = 0
local function Note(key)
	local pl = Places()
	if not (key and pl) then return end
	local sub = GetSubZoneText and GetSubZoneText() or ""
	if Secret(sub) then sub = "" end
	local inside = IsIndoors and IsIndoors() and 1 or nil
	if sub == "" and not inside then return end
	local new = pl[key] == nil
	pl[key] = { s = sub ~= "" and sub or nil, i = inside, f = inside and FloorMap() or nil, t = time and time() or nil }
	-- at most 2000 steps remembered: past that, the ones you haven't been to longest go
	if new then
		added = added + 1
		if added % 50 == 0 then
			local list = {}
			for k, v in pairs(pl) do list[#list + 1] = { k, v.t or 0 } end
			if #list > 2000 then
				table.sort(list, function(a, b) return a[2] < b[2] end)
				for i = 1, #list - 1800 do pl[list[i][1]] = nil end
			end
		end
	end
end

---------------------------------------------------------------------------
-- Doorways: each time you step from outdoors to indoors, the spot you came
-- in by is remembered (per zone map). Later, a step that's indoors gets its
-- way in: the arrow takes you to the door first, then inside.
---------------------------------------------------------------------------
local function Doors(map)
	local d = P.db and P.db.doors
	if not d then return end
	d[map] = d[map] or {}
	return d[map]
end
local lastOut, wasIn
local doorWatch = CreateFrame("Frame")
local doorT = 0
doorWatch:SetScript("OnUpdate", function(_, dt)
	doorT = doorT + dt
	if doorT < 0.5 or not P.db then return end
	doorT = 0
	if not P:RouteShown() then return end                 -- no guide showing: no doorways to point out
	local inside = IsIndoors and IsIndoors() or false
	local map = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local zone = map and P:ZoneOf(map)
	local pos = zone and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(zone, "player")
	local x, y = pos and pos.x, pos and pos.y
	if Secret(x) then x, y = nil, nil end
	if not inside then
		if x then
			lastOut = lastOut or {}
			lastOut[1], lastOut[2], lastOut[3], lastOut[4] = zone, x, y, GetTime()
		end
	elseif wasIn == false and lastOut and GetTime() - lastOut[4] < 3 and lastOut[1] == zone then
		-- just went in: the last spot outside is the door
		local list = Doors(zone)
		if list then
			local fx, fy = lastOut[2], lastOut[3]
			local near
			for _, d in ipairs(list) do
				if math.abs(d[1] - fx) < 0.004 and math.abs(d[2] - fy) < 0.004 then near = d break end
			end
			if not near and #list < 150 then
				local sub = GetSubZoneText and GetSubZoneText() or ""
				list[#list + 1] = { fx, fy, (not Secret(sub) and sub ~= "") and sub or nil }
			end
		end
	end
	wasIn = inside
end)
P.Perf.Hook(doorWatch, "Quest routes", "OnUpdate")

-- the door to use for an indoor stop: a learned doorway close to it (same place name when known)
function P:DoorFor(s)
	if not (s and s.map and s.x and P.db and P.db.doors) then return end
	local key = s.at and (s.at[1] .. s.at[2]) or (s.key and s.key:match("^[NO]%d+$") and s.key)
	local pl = key and Places() and Places()[key]
	if not (pl and pl.i) then return end
	local zone = P:ZoneOf(s.map)
	local list = P.db.doors[zone]
	if not list then return end
	local inst, tx, ty = P:WorldPos(s.map, s.x, s.y)
	if not inst then return end
	local best, bd
	for _, d in ipairs(list) do
		if not pl.s or not d[3] or d[3] == pl.s then
			local i, dx, dy = P:WorldPos(zone, d[1], d[2])
			if i == inst then
				local dd = (dx - tx) ^ 2 + (dy - ty) ^ 2
				if dd < 70 * 70 and (not bd or dd < bd) then best, bd = d, dd end
			end
		end
	end
	if best then return zone, best[1], best[2] end
end

-- which floor, compared to where you are: "upstairs", "downstairs", "two floors up"
function P:FloorHint(s)
	local key = s.at and (s.at[1] .. s.at[2]) or (s.key and s.key:match("^[NO]%d+$") and s.key)
	local pl = key and Places() and Places()[key]
	if not (pl and pl.f and C_Map.GetMapGroupID and C_Map.GetMapGroupMembersInfo) then return end
	local here = FloorMap()
	if not here or here == pl.f then return end
	local g = C_Map.GetMapGroupID(pl.f)
	if not g or g ~= C_Map.GetMapGroupID(here) then return end
	local hi, ti
	for _, m in ipairs(C_Map.GetMapGroupMembersInfo(g) or {}) do
		if m.mapID == here then hi = m.relativeHeightIndex end
		if m.mapID == pl.f then ti = m.relativeHeightIndex end
	end
	if not (hi and ti) or hi == ti then return end
	local d = ti - hi
	if d == 1 then return "upstairs" elseif d == -1 then return "downstairs"
	elseif d > 1 then return d .. " floors up" else return (-d) .. " floors down" end
end

local function NoteUnit(unit) Note(IdOf(UnitGUID(unit))) end
for _, ev in ipairs({ "GOSSIP_SHOW", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_GREETING", "MERCHANT_SHOW", "TAXIMAP_OPENED" }) do
	P:On(ev, function() if P.db then NoteUnit("npc") end end)
end
-- you loot what you just killed, or the chest or plant you just opened
P:On("LOOT_OPENED", function()
	if not (P.db and GetLootSourceInfo) then return end
	local guid = GetLootSourceInfo(1)
	Note(IdOf(guid))
end)

P:Listen("READY", function() P.db.places = P.db.places or {}; P.db.doors = P.db.doors or {} end)

---------------------------------------------------------------------------
-- Landmarks: services standing right next to it
---------------------------------------------------------------------------
local INN, BANK, AUCTION, TRAINER = 128, 256, 4096, 16
local band = bit and bit.band or function(a, b) return (a % (b + b) >= b) and b or 0 end

local function Landmark(map, x, y, selfKey)
	local best, bd
	local inst, wx, wy = P:WorldPos(map, x, y)
	if not inst then return end
	local function try(d2, text)
		if d2 < 22 * 22 and (not bd or d2 < bd) then best, bd = text, d2 end
	end
	for id, row in pairs(P.SV or {}) do
		if selfKey ~= "N" .. id then
			local pts = row[4]
			for i = 1, #pts, 2 do
				if pts[i] == map then
					local ii, ax, ay = P:WorldPos(map, P.Unpack(pts[i + 1]))
					if ii == inst then
						local d2 = (ax - wx) ^ 2 + (ay - wy) ^ 2
						if d2 < 22 * 22 then
							local fl = row[3]
							if band(fl, INN) ~= 0 then try(d2, "by the inn")
							elseif band(fl, BANK) ~= 0 then try(d2, "by the bank")
							elseif band(fl, AUCTION) ~= 0 then try(d2, "by the auction house")
							elseif row[2] and row[2] ~= "" then try(d2 + 25, "near " .. row[1] .. " <" .. row[2] .. ">") end
						end
					end
				end
			end
		end
	end
	for id, row in pairs(P.FM or {}) do
		if row[2] == map and selfKey ~= "N" .. id then
			local ii, ax, ay = P:WorldPos(map, P.Unpack(row[3]))
			if ii == inst then try((ax - wx) ^ 2 + (ay - wy) ^ 2, "by the flight master") end
		end
	end
	local mb = P.MB or {}
	for i = 1, #mb, 2 do
		if mb[i] == map then
			local ii, ax, ay = P:WorldPos(map, P.Unpack(mb[i + 1]))
			if ii == inst then
				local d2 = (ax - wx) ^ 2 + (ay - wy) ^ 2
				if d2 < 12 * 12 then try(d2 + 50, "by the mailbox") end
			end
		end
	end
	return best
end

---------------------------------------------------------------------------
-- What the quest says about where: "in the Fargodeep Mine", "atop the tower"
---------------------------------------------------------------------------
local PREP = { "at the top of", "on top of", "at the bottom of", "deep in", "upstairs in", "inside", "atop", "beneath", "under", "below", "within", "in" }
local LINK = { ["of"] = true, ["the"] = true, ["'s"] = true }

-- the capitalised name after a word like "in": "in the Fargodeep Mine." -> "the Fargodeep Mine"
local function NameAfter(text, i)
	local rest = text:sub(i)
	local words, out, caps = {}, {}, 0
	for w in rest:gmatch("[%w'%-]+[%.,;!:]?") do words[#words + 1] = w; if #words > 8 then break end end
	for idx, w in ipairs(words) do
		local bare, stop = w:gsub("[%.,;!:]$", "")
		if bare:match("^%u") then
			out[#out + 1] = bare; caps = caps + 1
		elseif (bare == "the" and idx == 1) or (LINK[bare] and caps > 0) then
			out[#out + 1] = bare
		else
			break
		end
		if stop > 0 then break end
	end
	while #out > 0 and LINK[out[#out]] do out[#out] = nil end
	if caps == 0 then return end
	return table.concat(out, " ")
end

local function FromText(text)
	if not text or text == "" then return end
	for _, p in ipairs(PREP) do
		local init = 1
		while true do
			local a, b = text:find("[%s,]" .. p .. " ", init)
			if not a then break end
			local name = NameAfter(text, b + 1)
			if name then
				local kind = KindOf(name)
				-- "in Elwynn Forest" says nothing new; "in the Fargodeep Mine" does
				if kind or p ~= "in" then return p .. " " .. name, kind end
			end
			init = b + 1
		end
	end
	local low = " " .. text:lower() .. " "
	if low:find(" upstairs") then return "upstairs" end
	if low:find(" cellar") or low:find(" basement") then return "down in the cellar" end
	if low:find(" cave[%s%p]") then return "in a cave", "cave" end
	if low:find(" mine[%s%p]") then return "in the mine", "cave" end
end
P.PlaceFromText = FromText

---------------------------------------------------------------------------
-- The whole picture for a stop
---------------------------------------------------------------------------
-- the entity a stop is about right now
local function KeyOf(s)
	if s.at then return s.at[1] .. s.at[2] end
	if s.key and s.key:match("^[NO]%d+$") then return s.key end
	local e = s.ents and s.ents[1]
	if e then return e[1] .. e[2] end
end

-- returns: a short phrase ("inside Lion's Pride Inn · by the inn"), and the kind of place
local cache = {}
function P:Whereabouts(s)
	if not (s and P.db) or s.travel or s.trip or s.flight then return end
	local key = KeyOf(s)
	local ck = (key or s.key or "") .. ":" .. tostring(s.quest or "") .. ":" .. floor((s.x or 0) * 1000) .. floor((s.y or 0) * 1000)
	local c = cache[ck]
	local text, kind
	if c and GetTime() - c.t < 20 then text, kind = c.text, c.kind
	else
		text, kind = self:FindWhereabouts(s, key)
		cache[ck] = { text = text, kind = kind, t = GetTime() }
	end
	-- the floor changes as you climb, so it's worked out fresh
	local floor = self:FloorHint(s)
	if floor then text = text and (floor .. "  ·  " .. text) or floor end
	return text, kind
end

function P:FindWhereabouts(s, key)
	local parts, kind = {}, nil
	local pl = key and Places() and Places()[key]
	if pl then
		local k = pl.s and KindOf(pl.s)
		kind = k
		if pl.s and pl.i then parts[#parts + 1] = "inside " .. pl.s
		elseif pl.s then parts[#parts + 1] = "in " .. pl.s
		elseif pl.i then parts[#parts + 1] = "indoors" end
		if pl.i and not k then kind = "building" end
	end
	-- the quest's own words
	if #parts == 0 and s.quest then
		local q = P.Q[s.quest]
		local phrase, k = FromText(q and q[K.TEXT])
		if phrase then parts[#parts + 1] = phrase; kind = kind or k end
	end
	-- the zone's explored areas at that spot (only places you've already been)
	if #parts == 0 and s.map and s.x and C_MapExplorationInfo and C_MapExplorationInfo.GetExploredAreaIDsAtPosition and CreateVector2D then
		local ok, ids = pcall(C_MapExplorationInfo.GetExploredAreaIDsAtPosition, s.map, CreateVector2D(s.x, s.y))
		if ok and ids and ids[#ids] and C_Map.GetAreaInfo then
			local name = C_Map.GetAreaInfo(ids[#ids])
			if type(name) == "string" and name ~= "" and not Secret(name) then
				parts[#parts + 1] = "in " .. name
				kind = kind or KindOf(name)
			end
		end
	end
	if s.map and s.x then
		local lm = Landmark(s.map, s.x, s.y, key)
		if lm then parts[#parts + 1] = lm end
	end
	if #parts == 0 then return end
	return table.concat(parts, "  ·  "), kind
end

-- a hint for the kind of place: what to look for when you get there
local HINT = {
	cave = "It's in a cave: find the entrance first, the arrow points through the rock.",
	crypt = "It's down in a crypt: look for the way in.",
	tower = "It's in a tower: go in and up.",
	building = "It's indoors: go inside.",
}
function P:PlaceHint(kind) return kind and HINT[kind] end

---------------------------------------------------------------------------
-- Step hints: "upstairs in the inn", "enter the cave" for the step you're on.
-- They come from RestedXP Guides (Hints/Hints.lua, CC BY-NC-SA 4.0) and are
-- only used when they were written for this quest at this very spot.
---------------------------------------------------------------------------
local hintPos = setmetatable({}, { __mode = "k" })
local function HintPos(row)
	local c = hintPos[row]
	if c ~= nil then return c end
	c = false
	local w = row[3]
	if w[1] == false then c = { w[2], w[3], w[4] }
	else
		local inst, wx, wy = P:WorldPos(w[1], w[2], w[3])
		if inst then c = { inst, wx, wy } end
	end
	hintPos[row] = c
	return c
end

local REACH = { p = 60, t = 60, o = 150 }
local hintCache = setmetatable({}, { __mode = "k" })
function P:StepHint(s)
	if not (P.HINTS and P.db and s and s.wx) or S().stepHints == false then return end
	if s.travel or s.trip or s.flight or s.goal then return end
	local c = hintCache[s]
	if c and c.wx == s.wx and c.wy == s.wy and GetTime() - c.t < 5 then return c.text or nil end
	local want = {}
	if s.quest then want[#want + 1] = { s.quest, "o", s.index }
	elseif s.key then
		local pick, turn = self:EntityWork(s.key)
		for _, q in ipairs(turn) do want[#want + 1] = { q, "t" } end
		for _, q in ipairs(pick) do want[#want + 1] = { q, "p" } end
	end
	local best, bestD
	for _, w in ipairs(want) do
		for _, row in ipairs(P.HINTS[w[1]] or {}) do
			if row[1] == w[2] then
				local pos = HintPos(row)
				if pos and (not s.inst or pos[1] == s.inst) then
					local d = sqrt((pos[2] - s.wx) ^ 2 + (pos[3] - s.wy) ^ 2)
					-- the objective it was written for counts double
					if w[3] and row[2] ~= 0 and row[2] ~= w[3] then d = d * 2 end
					if d <= REACH[row[1]] and (not bestD or d < bestD) then best, bestD = row[4], d end
				end
			end
		end
	end
	hintCache[s] = { wx = s.wx, wy = s.wy, t = GetTime(), text = best or false }
	return best
end

-- how to do an objective, in a guide writer's words ("Kill Defias Thugs. Loot
-- them for Bandanas"). The one written for that objective, else for the quest.
function P:HowHint(qid, index)
	if not (P.HINTS and qid) or (P.db and S().stepHints == false) then return end
	local any
	for _, row in ipairs(P.HINTS[qid] or {}) do
		if row[1] == "h" then
			if row[2] == index then return row[4] end
			if row[2] == 0 then any = any or row[4] end
		end
	end
	return any
end
end part() end
-- ==================== WoWProLoad.lua
do local __addon, __ns = ... local function part()
--[[ Pathway — loading the bundled WoW-Pro guides
     The WoW-Pro Community's Forever leveling guides ship unchanged in WoWPro/
     (CC BY-NC-ND 3.0, see WoWPro/License.md). They expect the WoW-Pro add-on;
     for the moment they load, a small stand-in records each guide and its steps.
     WoWProTips.lua puts the real WoW-Pro (if any) back right after. ]]

local ADDON, P = __addon, __ns
P.WoWProGuides = {}
P._wowproWas = _G.WoWPro
local guides = P.WoWProGuides
local stand = {}
function stand:RegisterGuide(id, kind, zone, author, faction, ...)
	local g = { id = id, kind = kind, zone = zone, author = author, faction = faction }
	guides[#guides + 1] = g
	return g
end
function stand:GuideSteps(g, fn) if type(g) == "table" then g.steps = fn end end
function stand:GuideName(g, name) if type(g) == "table" then g.name = name end end
function stand:GuideLevels(g, lo, hi) if type(g) == "table" then g.lo, g.hi = lo, hi end end
-- anything else a guide asks for is fine to ignore
setmetatable(stand, { __index = function() return function() end end })
_G.WoWPro = stand
end part() end
