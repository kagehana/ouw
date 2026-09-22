-- ESP. (boss) (plr) (mob) (obj) markers with a name and distance.
-- genv.esp = { config, tuning, tracked, add, remove, rescan, destroy }

-- getgenv() does not return a stable table identity here: two calls can hand
-- back views that do not compare equal, so a value written through one is not
-- reliably readable through another. Capture it once and use only this.
local genv = getgenv()

pcall(function() (genv.project):Destroy() end)
pcall(function() genv.projectCleanup() end)
pcall(function() (genv.seoul):Destroy() end)

-- ...and the same thing again, through the DataModel rather than through
-- getgenv(), because the above CANNOT BE RELIED ON. Two executions do not
-- necessarily share a getgenv view - that is written down here already - so a
-- re-execute can read `projectCleanup` as nil, skip the teardown entirely and
-- leave the previous run's farm, raid and loot threads driving the character
-- alongside the new ones. Two farms pinning the same body to two different
-- targets is the symptom.
--
-- An attribute on a service is shared by every execution on this client
-- whatever their environments, so it is the one channel both runs can see.
-- Each run stamps its own token and watches for it changing; the old run tears
-- itself down within `GEN.poll` of the new one starting, without either
-- needing a reference to the other.
local GEN = {
    host  = game:GetService('CoreGui'),
    key   = 'ProjectSlayerGen',
    id    = tostring(os.clock()) .. '/' .. tostring(math.random(1, 1e9)),
    poll  = 0.25,
}
pcall(function() GEN.host:SetAttribute(GEN.key, GEN.id) end)
function GEN.stale()
    local ok, v = pcall(function() return GEN.host:GetAttribute(GEN.key) end)
    return ok and v ~= nil and v ~= GEN.id
end

local Run   = game:GetService('RunService')
local Plrs  = game:GetService('Players')
local Input = game:GetService('UserInputService')
local RepS  = game:GetService('ReplicatedStorage')
local Http  = game:GetService('HttpService')
local Me    = Plrs.LocalPlayer

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

-- Every flag ships false: a Seoul toggle always starts off and cannot be seeded,
-- so an on default would invert its pill for the whole session.
-- Markers fade IN with distance, so anything close stays out of the way. One
-- band for every category; a category may still override it.
-- One table rather than twenty locals: the top level sits at Luau's
-- 200-local ceiling, and an executor compiling without optimisation (Volt)
-- does not fold constant locals away, so it hit that ceiling where Real did not.
local K = {}
K.FADE_IN  = 120
K.FADE_OUT = 350

local CFG = {
    Boss = {
        on = false, showName = false, showDist = false,
        tag = '(boss)', px = 14, color = WHITE, z = 40, weight = 0.2,
        fadeIn = K.FADE_IN, fadeOut = K.FADE_OUT,
    },
    -- interactable NPCs: shopkeepers, trainers, quest givers
    Npc = {
        on = false, showName = false, showDist = false,
        tag = '(npc)', px = 13, color = WHITE, z = 35, weight = 0.4,
        fadeIn = K.FADE_IN, fadeOut = K.FADE_OUT,
    },
    Player = {
        on = false, showName = false, showDist = false,
        tag = '(plr)', px = 13, color = WHITE, z = 30, weight = 0.5,
        fadeIn = K.FADE_IN, fadeOut = K.FADE_OUT,
    },
    Mob = {
        on = false, showName = false, showDist = false,
        tag = '(mob)', px = 13, color = WHITE, z = 20, weight = 1,
        fadeIn = K.FADE_IN, fadeOut = K.FADE_OUT,
    },
    -- Places are static points, not instances, and they sit kilometres apart,
    -- so they get their own much wider fade band.
    Place = {
        on = false, showName = false, showDist = false,
        tag = '(area)', px = 13, color = WHITE, z = 5, weight = 0.1,
        fadeIn = 200, fadeOut = 1500,
    },
    Object = {
        on = false, showName = false, showDist = false,
        tag = '(obj)', px = 13, color = WHITE, z = 10, weight = 1.5,
        fadeIn = K.FADE_IN, fadeOut = K.FADE_OUT,
    },
}
local ORDER  = { 'Boss', 'Npc', 'Player', 'Mob', 'Object', 'Place' }
-- A target can match two rules at once. Rank them so the answer does not depend
-- on which signal arrived last: only a stronger claim may take an existing
-- target, and an explicit esp.add always wins.
local PRIORITY = { Boss = 5, Npc = 4, Player = 3, Mob = 2, Object = 1, Place = 0 }
local LABELS = { Npc = 'NPC' }   -- menu titles where the key is not the wording
local TUNING = { maxVisible = 90 }

-- A ProximityPrompt is the engine's own "you can interact with this" marker, so
-- it finds every interactable without knowing anything about the game. What the
-- prompt is attached to decides the category: something built like a person is
-- an NPC, anything else is an object. That beats matching on ActionText, which
-- is per-game prose - Ouwland alone uses Chat, Purchase, Train, Dig, Set Spawn
-- and Unlock Shrine, and "Train" turned out to be a boulder, not a trainer.
local PROMPT_ROUTES = {}   -- optional ActionText -> category override

-- FontFace beats Enum.Font here: it reaches families and weights the enum
-- cannot express (a condensed face at Bold), and the legacy Arial the enum
-- gives renders 218x24 for a name that RobotoCondensed Bold draws in 123x16 at
-- the same TextSize, which is what made long names collide.
K.FONT_FAMILY = 'RobotoCondensed'
K.FONT_WEIGHT = Enum.FontWeight.Bold
K.FONT_LEGACY = Enum.Font.GothamBold   -- if FontFace is unavailable
K.T_REF    = 19      -- name size at T_DIST studs, scaled by distance
K.T_DIST   = 100
K.T_MIN    = 15
K.T_MAX    = 34
K.GAP      = 3       -- name gap above the tag
K.Y_OFF    = 4
K.STROKE_T = 0.7     -- outline on name and tag: 1 = off, 0 = solid
K.D_COLOR  = '#9A9A9A'
K.D_SCALE  = 0.72    -- distance size relative to the name
K.D_SEP    = '  '
K.CULL     = 160     -- off-screen slack before a marker is hidden
K.RELEASE  = 3       -- seconds hidden before a widget returns to the pool
K.SWEEP    = 1
K.UI_KEY   = Enum.KeyCode.RightShift
K.SEOUL    = 'https://github.com/kagehana/seoul/blob/main/seoul.lua?raw=true'

local floor, clamp, max, min, abs = math.floor, math.clamp, math.max, math.min, math.abs
local fmt, fromOffset, clock = string.format, UDim2.fromOffset, os.clock
local sort, clear, vec3 = table.sort, table.clear, Vector3.new
local concat = table.concat

local gui = Instance.new('ScreenGui')
gui.Name           = 'BossHighlights'
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = (gethui and gethui()) or game:GetService('CoreGui')
genv.project  = gui

local tracked, conns, pool, np = {}, {}, {}, 0
-- keyed by player so a leaver's connection can be dropped: appending to conns
-- meant every join added one that only cleanup() ever released
local PLACE_NAMES = {}   -- location names, filled as places are added
-- Claimable prompts, found by the same single workspace listener that does
-- discovery. A boss chest does NOT always land in Workspace.Chests, so keying
-- on the folder alone misses the ones that matter; the action text is what the
-- game shows the player and is the same wherever the thing is parented. Weak
-- keys, because opening a chest destroys its prompt.
local LOOT_ACTIONS = { Open = true, Claim = true, Loot = true,
                       Collect = true, Take = true, Pickup = true }
local lootSeen = setmetatable({}, { __mode = 'k' })
local playerConns = {}
local function unhook(p)
    local x = playerConns[p]
    if x then
        x:Disconnect()
        playerConns[p] = nil
    end
end
local uiGui, alive = nil, true
local cam = workspace.CurrentCamera

local ESC = { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;' }
local function esc(s) return (s:gsub('[&<>]', ESC)) end

-- An error inside a `while alive do ... end` body kills the thread, and the only
-- symptom is that the feature silently stops: no swings, no rescans, no respawn
-- pickup, with the toggle still sitting on green. Every loop body runs through
-- this, so one bad frame costs one frame. The warn is rate limited because the
-- cause is usually per-frame and a wall of identical lines hides it.
local lastWarn = 0
local function guard(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local now = clock()
        if now - lastWarn > 5 then
            lastWarn = now
            warn('[project] ' .. tostring(err))
        end
    end
    return ok, err   -- on success `err` is the call's first return value
end

-- AABB centre and top in the anchor's object space, so a frame costs one CFrame
-- multiply instead of a GetPivot plus a bounding-box rebuild
local function measure(parts, cf)
    local inf = math.huge
    local aX, aY, aZ = inf, inf, inf
    local bX, bY, bZ = -inf, -inf, -inf
    local found = false
    for _, p in parts do
        if p.Parent then
            local rel, h = cf:ToObjectSpace(p.CFrame), p.Size * 0.5
            local r, u, l = rel.RightVector, rel.UpVector, rel.LookVector
            local eX = abs(r.X) * h.X + abs(u.X) * h.Y + abs(l.X) * h.Z
            local eY = abs(r.Y) * h.X + abs(u.Y) * h.Y + abs(l.Y) * h.Z
            local eZ = abs(r.Z) * h.X + abs(u.Z) * h.Y + abs(l.Z) * h.Z
            local q = rel.Position
            found = true
            aX, aY, aZ = min(aX, q.X - eX), min(aY, q.Y - eY), min(aZ, q.Z - eZ)
            bX, bY, bZ = max(bX, q.X + eX), max(bY, q.Y + eY), max(bZ, q.Z + eZ)
        end
    end
    if not found then return end
    local cX, cZ = (aX + bX) * 0.5, (aZ + bZ) * 0.5
    return vec3(cX, (aY + bY) * 0.5, cZ), vec3(cX, bY, cZ)
end

local function refresh(c, d)
    local parts, model, root = {}, c:IsA('Model') and c or nil, nil
    if c:IsA('BasePart') then parts[1] = c end
    for _, x in c:GetDescendants() do
        if x:IsA('BasePart') then
            parts[#parts + 1] = x
            if not root and x.Name == 'HumanoidRootPart' then root = x end
        elseif not model and x:IsA('Model') then
            model = x
        end
    end
    -- anchor to something that tracks the whole rig, not a random limb
    d.parts  = parts
    d.anchor = (model and model.PrimaryPart) or root or parts[1]
    d.center, d.top = nil, nil
    if d.anchor then d.center, d.top = measure(parts, d.anchor.CFrame) end
    d.dirty = false
end

-- ── widgets ─────────────────────────────────────────────────────────────────
local function newWidget()
    local root = Instance.new('Frame')
    root.Name                   = 'M'
    root.AnchorPoint            = Vector2.new(0.5, 0.5)
    root.Size                   = fromOffset(0, 0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel        = 0
    root.Visible                = false
    root.Parent                 = gui

    local function text(ay, yAlign)
        local t = Instance.new('TextLabel')
        t.AnchorPoint            = Vector2.new(0.5, ay)
        t.Size                   = fromOffset(0, 0)
        t.AutomaticSize          = Enum.AutomaticSize.XY
        t.BackgroundTransparency = 1
        t.TextScaled             = false   -- must stay off for <font size> to work
        t.Text                   = ''
        t.TextStrokeColor3       = BLACK
        t.TextXAlignment         = Enum.TextXAlignment.Center
        t.TextYAlignment         = yAlign
        -- fall back to the enum on any client without FontFace
        if not pcall(function()
            t.FontFace = Font.new(
                'rbxasset://fonts/families/' .. K.FONT_FAMILY .. '.json', K.FONT_WEIGHT)
        end) then
            t.Font = K.FONT_LEGACY
        end
        t.Parent                 = root
        return t
    end

    local w = {
        root  = root,
        tag   = text(0.5, Enum.TextYAlignment.Center),
        label = text(1, Enum.TextYAlignment.Bottom),
    }
    w.tag.Name, w.label.Name = 'Tag', 'Label'
    w.label.RichText = true
    w.vis, w.labelOn = false, true
    return w
end

-- Shadowed property state: an instance is written only when a value changes,
-- which is what makes a still frame cost zero writes. Quantise before comparing
-- or the shadow never matches.
local function acquire()
    local w
    if np > 0 then
        w, pool[np], np = pool[np], nil, np - 1
    else
        w = newWidget()
    end
    w.x, w.y, w.px, w.tagText, w.color, w.alpha, w.size,
        w.d, w.dpx, w.nm, w.z, w.sn, w.sd = nil
    return w
end

local function release(w)
    w.root.Visible, w.label.Visible = false, true
    w.vis, w.labelOn = false, true
    np = np + 1
    pool[np] = w
end

local function hide(d)
    local w = d.w
    if not w then return end
    if w.vis then w.vis, w.root.Visible = false, false end
    if not d.since then d.since = clock() end
end

-- ── tracking ────────────────────────────────────────────────────────────────
local function untrack(c)
    local d = tracked[c]
    if not d then return end
    for _, x in d.conns do x:Disconnect() end
    if d.w then release(d.w) end
    tracked[c] = nil
end

local function claimed(x)
    x = x.Parent
    while x do
        if tracked[x] then return true end
        x = x.Parent
    end
    return false
end

local function classify(c)
    if c:FindFirstChild('BossInfo', true) then return 'Boss' end
    if c:FindFirstChildOfClass('Humanoid') then
        local p = Plrs:GetPlayerFromCharacter(c)
        if p then return p ~= Me and 'Player' or nil end
        return 'Mob'
    end
    return nil
end

-- A boss is usually Container > BossInfo + Model(rig with Humanoid), so the rig
-- would be found separately and drawn again as a Mob. One node owns its subtree.
local function track(c, cat, forced)
    if not c or not c:IsDescendantOf(game) or c == gui or c:IsDescendantOf(gui) then return end
    local d = tracked[c]
    if d then
        if cat and cat ~= d.cat
            and (forced or (PRIORITY[cat] or 0) > (PRIORITY[d.cat] or 0)) then
            d.cat = cat
            if d.w then d.w.tagText, d.w.color = nil, nil end
        end
        return d
    end
    if not forced and claimed(c) then return end
    cat = cat or classify(c)
    if not cat or not CFG[cat] then return end
    for _, x in c:GetDescendants() do
        if tracked[x] then untrack(x) end
    end

    -- `raw` is the same string before RichText escaping: a menu row wants the
    -- name the player reads, not the markup the label needs.
    d = { cat = cat, name = esc(c.Name), raw = c.Name, parts = {}, dirty = false,
          since = clock(), conns = {} }
    tracked[c] = d
    refresh(c, d)

    local function dirty(x)
        if x:IsA('BasePart') or x:IsA('Model') then d.dirty = true end
    end
    d.conns[1] = c.DescendantAdded:Connect(dirty)
    d.conns[2] = c.DescendantRemoving:Connect(dirty)
    d.conns[3] = c:GetPropertyChangedSignal('Name'):Connect(function()
        if d.fixedName then return end     -- a prompt's display name wins
        d.name, d.raw = esc(c.Name), c.Name
        if d.w then d.w.nm = nil end
    end)
    return d
end

-- A marker at a fixed world point, with no instance behind it. Everything else
-- here tracks an Instance and reads geometry off its parts; a place has neither,
-- so it carries its position directly and skips refresh entirely.
local function addPoint(name, pos, cat)
    if typeof(pos) ~= 'Vector3' then return end
    cat = cat or 'Place'
    if not CFG[cat] then return end
    if cat == 'Place' then PLACE_NAMES[tostring(name)] = true end
    local key = { point = true, name = name }   -- synthetic key: not an Instance
    local d = {
        cat = cat, name = esc(tostring(name)), raw = tostring(name),
        parts = {}, dirty = false,
        since = clock(), conns = {}, point = pos, fixedName = true,
    }
    tracked[key] = d
    return d
end

-- instance names are written for code, not for reading
local function humanize(n)
    return (n:gsub('(%l)(%u)', '%1 %2'):gsub('_', ' '))
end

-- the prompt hangs off a part; the thing worth drawing is the model above it
local function promptOwner(prompt)
    local x = prompt.Parent
    while x and x ~= workspace do
        if x:IsA('Model') then return x end
        x = x.Parent
    end
    return prompt.Parent
end

-- a person is built like one: a rig has a Humanoid or a HumanoidRootPart, and
-- Ouwland's stationary NPCs have the root without the Humanoid
local function looksLikePerson(owner)
    return owner:FindFirstChildOfClass('Humanoid') ~= nil
        or owner:FindFirstChild('HumanoidRootPart') ~= nil
end

local function consider(x)
    local p = x.Parent
    if not p then return end
    if x.Name == 'BossInfo' then
        track(p, 'Boss')
    elseif x:IsA('Humanoid') then
        track(p)
    elseif x:IsA('ProximityPrompt') then
        if LOOT_ACTIONS[x.ActionText] then lootSeen[x] = true end
        -- interactables have no Humanoid, so nothing else would ever find them
        local owner = promptOwner(x)
        if not owner then return end
        local cat = PROMPT_ROUTES[x.ActionText]
            or (looksLikePerson(owner) and 'Npc' or 'Object')
        local d = track(owner, cat)
        -- the prompt carries the name the game shows the player, which beats the
        -- instance name (MuzanLairModel -> Muzan, SpawnCrystal -> Windy Peak)
        if d and x.ObjectText and x.ObjectText ~= '' then
            local text = x.ObjectText
            -- When the prompt's text is a place name it is saying WHERE this is,
            -- not what it is: a spawn crystal labelled "Windy Peak" reads as the
            -- region itself. Qualify it instead: "[Windy Peak] Spawn Crystal".
            if PLACE_NAMES[text] and owner.Name ~= text then
                text = '[' .. text .. '] ' .. humanize(owner.Name)
            end
            d.name, d.raw, d.fixedName = esc(text), text, true
            if d.w then d.w.nm = nil end
        end
    end
end

local function rescan()
    for _, x in workspace:GetDescendants() do consider(x) end
    for _, p in Plrs:GetPlayers() do
        if p ~= Me and p.Character then track(p.Character, 'Player') end
    end
end

-- ── draw ────────────────────────────────────────────────────────────────────
local function draw(d, c, minX, maxX, minY, maxY)
    local sp, on = cam:WorldToViewportPoint(d.point or (d.cf * d.top))
    local x, y = sp.X, sp.Y
    if sp.Z <= 0 or (not on and (x < minX or x > maxX or y < minY or y > maxY)) then
        hide(d)
        return
    end

    local w = d.w
    if not w then w = acquire(); d.w = w end
    d.since = nil
    if not w.vis then w.vis, w.root.Visible = true, true end

    local px = c.px or 6
    if px ~= w.px then
        w.px = px
        w.tag.TextSize   = px
        w.label.Position = fromOffset(0, -K.GAP - floor(px * 0.5))
    end
    if c.tag ~= w.tagText then w.tagText, w.tag.Text = c.tag, c.tag end
    -- equal ZIndex falls back to child order, which is arbitrary with a pool
    if c.z ~= w.z then w.z, w.root.ZIndex = c.z, c.z end

    local ix, iy = floor(x + 0.5), floor(y + 0.5) + K.Y_OFF
    if ix ~= w.x or iy ~= w.y then
        w.x, w.y = ix, iy
        w.root.Position = fromOffset(ix, iy)
    end

    if c.color ~= w.color then
        w.color = c.color
        w.tag.TextColor3, w.label.TextColor3 = c.color, c.color
    end

    -- floored: the camera can sit on a target, and 0 would divide below
    local dist = d.dist < 0.05 and 0.05 or d.dist
    local a = 1
    if c.fadeIn and c.fadeOut and c.fadeOut > c.fadeIn then
        a = floor(clamp((dist - c.fadeIn) / (c.fadeOut - c.fadeIn), 0, 1) * 255 + 0.5) / 255
    end
    if a ~= w.alpha then
        w.alpha = a
        local t, st = 1 - a, 1 - a * (1 - K.STROKE_T)
        w.tag.TextTransparency,       w.label.TextTransparency       = t, t
        w.tag.TextStrokeTransparency, w.label.TextStrokeTransparency = st, st
    end

    local size = floor(clamp(K.T_REF * K.T_DIST / dist, K.T_MIN, K.T_MAX))
    if size ~= w.size then w.size, w.label.TextSize = size, size end

    local sn, sd = c.showName == true, c.showDist == true
    if sn or sd then
        local m, dpx = floor(dist), max(1, floor(size * K.D_SCALE))
        if m ~= w.d or dpx ~= w.dpx or d.name ~= w.nm or sn ~= w.sn or sd ~= w.sd then
            w.d, w.dpx, w.nm, w.sn, w.sd = m, dpx, d.name, sn, sd
            local head = sn and d.name or ''
            w.label.Text = sd
                and fmt('%s<font color="%s" size="%d">%s%d</font>',
                        head, K.D_COLOR, dpx, head ~= '' and K.D_SEP or '', m)
                or head
        end
        if not w.labelOn then w.labelOn, w.label.Visible = true, true end
    elseif w.labelOn then
        w.labelOn, w.label.Visible = false, false
    end
    return
end

-- ── farm ────────────────────────────────────────────────────────────────────
-- Damage is resolved server-side from our own position: the combat payload
-- names no target, and a combo fired 46 studs away registers on the server but
-- deals nothing. So farming is a positioning problem - lie under the target and
-- replay the client's own combo. Everything here no-ops in a game that does not
-- publish the signal remote, like the places adapter below.
-- The raid controller drives the farm and the loot run, but it must NEVER
-- write their toggles: a Seoul pill cannot be resynced, so a flag written from
-- outside the menu leaves the switch showing the opposite for the session.
-- Both features therefore read `FARM.on or RAID.on` rather than their own flag.
local RAID = {
    on     = false,   -- ships false: a Seoul toggle cannot be seeded
    -- Wave mode, for places that never let you leave (the Minigames dungeon /
    -- infinite mode): every Temporary rig is fought, bosses included, at any
    -- range, and a cleared room is WAITED in rather than toured away from -
    -- the only Place there is Ouwigahara, and travelling to it mid-run is
    -- exactly wrong. The farm parks the body underground at the last kill,
    -- so the wait is out of sight. Outranks the tour when both are on.
    wave   = false,   -- ships false: a Seoul toggle cannot be seeded
    radius = 600,     -- a camp this close counts as "here". NPC rigs replicate
                      -- out to about 1000 studs here - bosses read their health
                      -- fine at 975 - so this does not have to be tight.
    -- Both waits below are CAPS, not durations. Each one ends the moment the
    -- thing it is waiting for has actually happened, which is the difference
    -- between a lap that takes a minute and one that takes two and a half.
    --
    -- Arriving: what the stop waits for is the region's NPCs replicating, and
    -- the presence of any rig in `radius` says so directly - no need to guess
    -- at a streaming time. Measured live: rigs are visible out to ~1300 studs
    -- and gone by 1330, so this test is only true once we are really there.
    ready  = 1.5,     -- minimum stop, once any rig has appeared
    dwell  = 4,       -- cap, for a region where nothing ever shows up
    -- After the last kill: the seal breaks, the chest prompt enables and the
    -- drop is claimed. The loot run reports what it claimed, so wait for that
    -- rather than for the clock, and keep a grace for the drop that spawns as
    -- the chest opens.
    -- Measured from the LAST claim, not from the kill. From the kill, the
    -- chest's own claim usually ended the stop on the spot, and the drop it
    -- spawns a moment later - or a second drop - was left behind. Reported as
    -- "raid farming sometimes leaves without claiming all the loot".
    after  = 3,       -- grace after the most recent claim
    settle = 10,      -- cap, if nothing is ever claimed; each claim re-arms it
    tick   = 0.5,     -- seconds between passes
    -- The camp's loot is claimed before the tour moves on - requested: "raid
    -- loot always needs to be claimed before it moves onto the next one". The
    -- waits above end on evidence but still had caps, so a seal that broke
    -- late or a claim that kept missing let the tour leave a chest behind.
    -- Now it stays while any cache within `cacheNear` of the camp is unopened
    -- or any drop there is unclaimed. `lootCap` is only the last resort, for a
    -- cache that can never open (another player took it mid-claim, a seal
    -- that never breaks); the status says when it fires.
    cacheNear = 80,
    lootCap   = 90,
}
local RAID_STATE = { phase = 'off', area = nil, camp = 0, cleared = 0 }
-- when the current stop began, and what the loot run had claimed when the camp
-- died - both on the table rather than as locals, for the 200-local ceiling
RAID.since, RAID.loot = 0, 0
-- the claim count last seen, and when it last went up
RAID.seen, RAID.claimAt = 0, 0
-- Either mode drives the farm and the loot run the same way.
function RAID.active()
    return RAID.on or RAID.wave
end

local FARM = {
    on    = false,   -- ships false: a Seoul toggle cannot be seeded
    -- Studs from the target's root, held for the WHOLE engagement. One number
    -- for everything: it does not key on the target (a mob and a boss sit at
    -- the same distance) and it no longer keys on the weapon either.
    --
    -- Out of reach does not present as a range problem from the inside: the
    -- opener connects and the rest of the chain quietly does not, which reads
    -- as "it only hits once". Measured by hand with a Cutlass, 7 studs landed
    -- 4 of the 5 combo steps and 6 landed all five - so if that symptom comes
    -- back, this is the number to drop.
    --
    -- For reference, fists were measured separately: damage per 5s was 44 at
    -- 4.5 studs, 33 at 8, 15 at 12 and zero from 16 up, and over a full 300 HP
    -- boss 8 took no damage at all where 4.5 cost 51 HP.
    -- 7: tried at 6 and at 8 on request, back to 7 both times. The Cutlass
    -- numbers above say a katana lands fewer combo steps the further out.
    under = 7,
    -- `under` is a STARTING offset now, not a constant. Reach is per rig and
    -- the difference is a cliff, not a slope: measured damage per swing at
    -- under = 7 was 3.17 on Sumari, 2.69 on a Hoyuzo Subordinate, 2.58 on
    -- Yahari - and exactly 0.00 on both Mother Bear and Bear Cub. Drop the
    -- cub to 6 and it goes straight to 3.24. Bears are 13-part custom rigs
    -- rather than 27-46 part humanoid ones and their vertical reach ends
    -- between 6 and 7, where a humanoid boss reaches 12-16.
    --
    -- So the farm probes down, but ONLY on the rigs that are known to need
    -- it: if a full `probe` seconds of swinging lands nothing, come in a stud
    -- and try again, down to `underMin`. The working distance is remembered
    -- per rig name, so it is paid once per kind of enemy and never again.
    -- 4 is the floor because it is measured: Bear Cub took 2.82 a swing there
    -- and Mother Bear 3.04, so it clears both bear cliffs, and it is as close
    -- as the probe is ever allowed to walk.
    underMin = 4,
    -- Rig names (case-insensitive substrings) the probe is allowed to touch.
    -- Everything else holds `under` for the whole engagement.
    --
    -- The probe exists for one measured species. 7 is right for every
    -- humanoid rig measured here - Sumari, Hoyuzo Subordinate, Yahari all
    -- land 2.5-3.2 a swing at 7 - and the only thing it is wrong for is a
    -- bear. A probe that can fire on anything is therefore almost always
    -- wrong when it fires: a stall, a knockback or a bad window steps a mob
    -- that 7 suits perfectly in to 6, banks 6 against its name, and the farm
    -- spends the rest of the session crowding a target it had right. The
    -- swing gate makes that rare but cannot make it impossible, and the cost
    -- of not probing a bear is visible in two seconds while the cost of
    -- probing a Bandit is invisible forever. So the list is the safety, and
    -- adding to it should need the same evidence bears had: a measured 0.00
    -- damage per swing at `under` that goes non-zero a stud closer.
    probeNames = { 'bear' },
    -- Swings that must actually have gone out before a barren window is read
    -- as "out of reach". Without this the probe RATCHETS: engaging costs a
    -- teleport plus `settle` plus the first swing, the 2s window expires
    -- before anything could possibly have landed, so it steps 7 -> 6, the
    -- first hit then lands at 6 and 6 is what gets cached - and the next
    -- engagement starts at 6 and walks down again, to 5, to 4. Reported as
    -- "the smart distance is failing for regular mobs, i'm too close". 7 is
    -- right for nearly everything, so stepping in has to need real evidence.
    probeSwings = 6,
    probe    = 2.0,   -- seconds of fruitless swinging before stepping in
    -- 'under', 'above' or 'behind'. Under by default. Above was tried - the
    -- theory being that a target knocked into the air falls back down through
    -- the space beneath it and can clip us on the way - and it measured clearly
    -- worse in play, so it stays as an option and not as the default. Same
    -- distance either way; only the sign changes.
    place  = 'under',
    behind = 4,      -- studs off its back when place is 'behind'
    evade      = true, -- leave the hitbox while a boss skill is live; the
                       -- menu's `Never dodge` is the inverse, since a toggle
                       -- has to ship false
    evadeDrop  = 30,   -- EXTRA studs to sink while a skill is live, added on
                       -- top of `under`, so the real dodge distance is ~37.
                       -- Straight down, not up, so we stay under the target and
                       -- come back the same way.
                       --
                       -- Raised from 10 after Zentaro: 10 was not enough and
                       -- his skills landed through it. He is the reason the
                       -- number is what it is - M1Damage 49.8 with skills
                       -- scaling 4.7x (Godspeed), 5.7x (Rice Spirit) and 6.0x
                       -- (Thunder Clap and Flash), so one connecting skill is
                       -- ~250-300 against a 262 pool. A 90s farm of him at
                       -- evadeDrop 200 took ZERO damage, so the safe distance
                       -- is somewhere in 10 < d <= 200 and 30 is a first cut,
                       -- not a measured floor. The `Dodge drop` slider is there
                       -- to push it further if skills still land.
    evadeMin   = 2.0,  -- never bob back in faster than this
    -- Movers by name that are NOT skills. Logged live over 60s on Mizunoto:
    -- 12 dodges, 9 of them on `dash_thang_123asd` - the rig's own dash, 0.46s
    -- to 8.88s after any skill of ours, so not ours - each costing the full
    -- `evadeMin`, and a 90s run with dodging off took zero damage from under.
    -- The real skills that fired (whirlpool_plant, water_wheel_drift) still
    -- dodge. Our own skills never triggered one.
    evadeIgnore = { dash_thang_123asd = true },
    evadeGrace = 0.6,  -- a skill's damage hitbox outlives the wind-up marker
                       -- we can see, so hold this long after the last one dies.
                       -- Watching the workspace for the hitbox itself was tried
                       -- and reverted: streamed-in map geometry near the boss is
                       -- indistinguishable from a hitbox, and teleporting out
                       -- and back streams more of it, so the dodge never ended.
    evadeMax   = 8.0,  -- ceiling, in case a marker leaks and never dies
    bury       = 3,    -- studs the root keeps under the ground: head below it
    groundEvery = 0.25, -- seconds between ground casts under a fight target
    stayFloor  = 50,   -- wave farm stays underground from this tower floor on
    evadePart  = 4,    -- a new part this big is a skill hitbox, not the 1-2
                       -- stud markers an M1 leaves behind
    -- Absolute HP, not a fraction, so the sliders read in the same units the
    -- health bar does. Both adjustable from the Farm folder.
    bail   = 100,    -- retreat at or below this many HP; 0 disables. A flat
                     -- number rather than a share of MaxHealth: what kills you
                     -- is a skill landing for 250-300, and that does not get
                     -- smaller because your pool is smaller.
    resume = 0,      -- go back in at or above this many HP. Seeded at 90% of
                     -- MaxHealth at load, because "healed up" genuinely is
                     -- relative, and clamped to sit above `bail`.
    -- A FLOOR on the wait between swings, not the wait itself. The real gap
    -- comes from the equipped preset's own `default` (0.26 fists, 0.25 katana,
    -- 0.3 claws), because the server refuses to bank a step that arrives early
    -- - at a zero gap a five-step chain registers as one swing. Raise this only
    -- to swing deliberately slower than the game does.
    gap   = 0,
    -- Take the camera and fly it around the target. `under` puts the body
    -- inside the ground, where the default camera has a wall of terrain to
    -- show and nothing else - and noclip does not help, because it is a
    -- property of our parts and the camera collides with the world on its own.
    -- While this is on the camera is ours: the mouse does not move it, it
    -- holds its height and its distance, and it circles at its own pace.
    -- Ships false: a Seoul toggle cannot be seeded.
    cam     = false,
    camUp   = 15,    -- studs above the target's root
    camOut  = 28,    -- studs back from it, which is what makes the shot an
                     -- angled one rather than a map view straight down
    camSpin = 10,    -- degrees a second around it; 0 holds one fixed angle
    -- Skill keys, pressed in order after every M1 chain: 'Z,X,C'. Empty means
    -- M1s only. Keys are sent through VirtualInputManager, so the game's own
    -- skill client does the casting exactly as if they were typed - cooldowns
    -- included, which is why a key on cooldown only costs `skillGap`.
    skills   = '',
    skillKeys = {},  -- parsed from `skills`; KeyCode names
    skillHold = 0.1, -- seconds each key is held down
    skillGap  = 0.4, -- seconds between one skill and the next
    range = 400,     -- how far to list mobs
    scan  = 1.5,     -- seconds between respawn and candidate scans
    cap   = 50,      -- dropdown entries; all 33 boss folders must fit
}
-- The health thresholds are seeded from the character we actually have, once,
-- at load. This has to happen BEFORE the saved config is applied: it used to
-- run while the menu was being built, which is after, and it overwrote a saved
-- `resume` of 0 with 90% of MaxHealth every single run - so "no healing gate",
-- which is a real choice, was the one setting that could never be saved.
local function farmMaxHp()
    local ch  = Me.Character
    local hum = ch and ch:FindFirstChildOfClass('Humanoid')
    return (hum and hum.MaxHealth > 0) and floor(hum.MaxHealth + 0.5) or 100
end

do
    local maxHp = farmMaxHp()
    -- A bail at or above MaxHealth would mean "never engage", so clamp it
    -- rather than let the default lock the farm out on a small pool.
    if FARM.bail >= maxHp then FARM.bail = floor(maxHp * 0.45 + 0.5) end
    if FARM.resume == 0 then
        FARM.resume = max(floor(maxHp * 0.90 + 0.5), FARM.bail)
    end
end

-- 'z, x c' -> { 'Z', 'X', 'C' }. Letters and digits only, checked against an
-- explicit set rather than by indexing Enum.KeyCode, which throws on a bad name
-- in Roblox. Returns nil plus the offending token so the box can say which.
-- On the FARM table rather than a local: the top level is at the 200 ceiling.
do
    local DIGIT_KEYS = { ['0'] = 'Zero', ['1'] = 'One', ['2'] = 'Two', ['3'] = 'Three',
        ['4'] = 'Four', ['5'] = 'Five', ['6'] = 'Six', ['7'] = 'Seven',
        ['8'] = 'Eight', ['9'] = 'Nine' }
    function FARM.parseSkills(text)
        local keys, n = {}, 0
        for tok in tostring(text or ''):gmatch('[^,%s]+') do
            local up = tok:upper()
            local name = DIGIT_KEYS[up] or (up:match('^%a$') and up)
            if not name then return nil, tok end
            n += 1
            keys[n] = name
        end
        return keys
    end
end

local FARM_CATS   = { Boss = true, Mob = true }
local SIGNAL_PATH = { 'Communication', 'ServerAndClient', 'Signals', 'SignalEvent', 'Event' }
local BACK, ZERO, UP = vec3(0, 0, 1), vec3(0, 0, 0), vec3(0, 1, 0)

-- The target is a NAME, not an instance. `Bear Cub` is a kind of enemy, not
-- one particular cub: there are four of them and they die constantly, so
-- pinning the selection to one instance meant the farm stopped the moment that
-- body despawned and the list carried `Bear Cub #2`, `#3`, `#4` rows that all
-- meant the same thing. `farmWant` is what the user chose and it persists
-- until they change it; `farmKey` is merely whichever body currently answers
-- to it, re-picked every tick.
local farmWant                      -- selected NAME, or nil
local farmKey                       -- tracked key currently answering to it
local farmRig, farmRoot, farmHum    -- the resolved live rig
local farmChar, farmHrp, farmMe     -- our own character
local farmParts     = {}
local farmHome                      -- CFrame to return to, or nil
local farmStateConn = nil
local farmEngaged   = false
-- Readable engagement state. PlatformStand looked like the natural signal but
-- this game's character scripts clear it within a frame, so it reported false
-- for a whole engagement; the pose survives on the per-frame CFrame write.
local FARM_STATE    = { engaged = false, target = nil, retreated = false,
                        evading = false, looting = false, looted = 0,
                        preset = nil, why = 'off', key = nil, reach = nil,
                        want = nil, probing = false, skill = nil,
                        -- what set off the last dodge, and frames engaged /
                        -- frames dodging since the last engage: the one number
                        -- that says whether the dodge is eating the fight
                        dodge = nil, frames = 0, dodgeFrames = 0 }
-- Probe and dodge state on one table, not eight locals: the top level is at
-- Luau's 200-local ceiling when compiled without optimisation (Volt).
local FP = { evadeUntil = 0, hardStop = 0, reach = nil, probeAt = 0, lastHp = nil,
    probeSwings = 0, probing = false, base = nil }
-- Adaptive reach. `farmReach` is the offset in use for the CURRENT target;
-- REACH_CACHE remembers, per rig name, the one that was seen to connect.
-- `farmProbing` is whether THIS target is one the probe may move at all -
-- see FARM.probeNames. A rig that is not on that list sits at FARM.under for
-- the whole engagement and never banks anything.
local REACH_CACHE = {}
-- FP.base: the FARM.under the current reach was seeded from, so that
                 -- moving the slider mid-fight re-seeds instead of being
                 -- silently overridden by a probe that already stepped down
-- Last frame the Heartbeat actually pinned us. The watchdog in the scan loop
-- reads it, so anything that wedges an engagement without tripping one of the
-- specific guards still gets torn down and rebuilt within a second.
local farmBeat = 0
-- Where the target last was. The chest spawns on the corpse, but a kill sends
-- us home immediately, so by the time the loot sweep runs we can be hundreds of
-- studs away and measuring range from ourselves finds nothing.
local lootAnchor, lootAnchorAt = nil, 0
local farmEvadeConns = {}
-- weak keys: a marker destroyed mid-skill must not be pinned alive by this
local farmMarkers    = setmetatable({}, { __mode = 'k' })
--   FARM.dd, FARM.btn: menu elements, nil until the ui builds
FARM.labels   = {}                  -- label -> tracked key
FARM.sig      = ''                  -- signature of the list last written
-- Resolved root per candidate, revalidated by Parent and re-resolved only when
-- it dies. Weak keys so an untracked target does not pin its rig here.
local farmRoots     = setmetatable({}, { __mode = 'k' })
local farmRemoteCache

local function farmRemote()
    if farmRemoteCache and farmRemoteCache.Parent then return farmRemoteCache end
    local x = RepS
    for _, name in SIGNAL_PATH do
        x = x and x:FindFirstChild(name)
    end
    farmRemoteCache = x
    return x
end

-- Rebuilt only when the character changes: a GetDescendants walk every tick is
-- the kind of repeated work the rest of this file exists to avoid.
local function farmBind()
    local char = Me.Character
    if char == farmChar and farmHrp and farmHrp.Parent then return true end
    farmChar = char
    farmHrp  = char and char:FindFirstChild('HumanoidRootPart')
    farmMe   = char and char:FindFirstChildOfClass('Humanoid')
    clear(farmParts)
    if char then
        local n = 0
        for _, x in char:GetDescendants() do
            if x:IsA('BasePart') then
                n += 1
                farmParts[n] = x
            end
        end
    end
    return farmHrp ~= nil
end

-- Written on engage and on every Humanoid state change rather than per frame:
-- the state machine is the only thing that turns collision back on, so there is
-- nothing to catch in between.
local function farmPhase()
    for _, x in farmParts do
        if x.Parent and x.CanCollide then x.CanCollide = false end
    end
end

local function farmUnder()
    return FP.reach or FARM.under
end

-- Aim where a RUNNING target will be, not where it is. Reported: "when an
-- enemy is running, our m1s miss, until they stop running, or we skill and
-- they're stunned". The server resolves a hit from our REPLICATED position,
-- which reaches it late, against where the target is by then - so a box
-- placed under a target we see running lands behind it. Every form of farming
-- goes through this (farmStep: target, raid, wave, quest, all three
-- placements).
-- Velocity is measured from the root's own positions, horizontal only,
-- smoothed over `leadSmooth`; a jump faster than `leadJump` (a dash, a
-- teleport, a respawn) or a gap in sampling says nothing about running and
-- reads as standing; the speed used is capped at `leadMaxSpeed`; under 1 stud
-- a second is the idle bob, not running.
-- HOW FAR ahead is computed, not set: lead time = round trip + the swing's
-- WIND-UP (the equipped preset's `default_before_hit`) + `leadInterp`.
-- The target we see is half a round trip old and our position reaches the
-- server half a round trip late; and the server judges the hit when the
-- swing LANDS, a wind-up later, against where the runner is by then.
-- The wind-up term was first reasoned away and then measured back in, live
-- on tower floors 30-37 with claws (wind-up 0.22) at a 56ms round trip - M1s
-- landed on runners over 12 studs/s:
--   lead 0.105s (round trip + 0.05)  50% of 22 swings
--   lead 0.27s                       88% of 8
--   lead 0.41s                       61% of 18   (overshoots)
-- and round trip + wind-up = 0.276s is the best row. `leadInterp` is left as
-- a trim at 0. Round trip from Stats' Data Ping (includes the server frame:
-- 55ms against GetNetworkPing's 38ms network-only), smoothed, with
-- GetNetworkPing x2 as the fallback.
FARM.leadInterp   = 0
FARM.leadMax      = 0.6
FARM.leadSmooth   = 0.15
FARM.leadJump     = 80
FARM.leadMaxSpeed = 40
FARM.leadTrack    = setmetatable({}, { __mode = 'k' })

function FARM.leadOffset(root)
    if not root then return ZERO end
    local now, p = clock(), root.Position
    local tr = FARM.leadTrack[root]
    if not tr then
        FARM.leadTrack[root] = { pos = p, t = now, vel = ZERO }
        return ZERO
    end
    local dt = now - tr.t
    if dt > 0 then
        local d = p - tr.pos
        local v = vec3(d.X, 0, d.Z) * (1 / dt)
        if dt > 0.5 or v.Magnitude > FARM.leadJump then v = ZERO end
        tr.vel = tr.vel + (v - tr.vel) * min(1, dt / FARM.leadSmooth)
        tr.pos, tr.t = p, now
    end
    local lead = FARM.leadTime()
    if lead <= 0 then return ZERO end
    local v, speed = tr.vel, tr.vel.Magnitude
    if speed < 1 then return ZERO end
    if speed > FARM.leadMaxSpeed then v = v * (FARM.leadMaxSpeed / speed) end
    return v * lead
end

-- Seconds of lead for this client's connection, updated at most twice a
-- second (Stats reads are not free and ping does not move per frame).
function FARM.leadTime()
    local now = clock()
    if FARM.rttAt and now - FARM.rttAt < 0.5 then
        return min(FARM.leadMax, (FARM.rtt or 0) + FARM.hitDelay() + FARM.leadInterp)
    end
    FARM.rttAt = now
    local ok, ms = pcall(function()
        return game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    end)
    local rtt = ok and type(ms) == 'number' and ms > 0 and ms / 1000 or nil
    if not rtt then
        local ok2, one = pcall(function() return Me:GetNetworkPing() end)
        rtt = ok2 and type(one) == 'number' and one * 2 or nil
    end
    if rtt then
        FARM.rtt = FARM.rtt and (FARM.rtt + (rtt - FARM.rtt) * 0.3) or rtt
    end
    return min(FARM.leadMax, (FARM.rtt or 0) + FARM.hitDelay() + FARM.leadInterp)
end

-- Is this rig one the reach probe is allowed to move? Name match, because the
-- thing that actually differs is the species and the name is the only handle
-- on it that survives a respawn.
local function farmProbable(name)
    name = (name or ''):lower()
    for _, pat in FARM.probeNames do
        if name:find(pat:lower(), 1, true) then return true end
    end
    return false
end

-- A boss is Folder > BossInfo + Model(rig), and the rig exists only while the
-- boss is up, so the tracked key is not the thing we can stand under.
local function farmResolve(key)
    if typeof(key) ~= 'Instance' or not key.Parent then return end
    local hum = key:IsA('Humanoid') and key or key:FindFirstChildWhichIsA('Humanoid', true)
    if not hum or hum.Health <= 0 then return end
    local rig = hum.Parent
    if not rig or not rig.Parent then return end
    local root = rig:FindFirstChild('HumanoidRootPart')
        or (rig:IsA('Model') and rig.PrimaryPart)
    if not root then return end
    return rig, root, hum
end

-- Two signals, both generic, so this is not tuned to one boss:
--   * a physics mover on the rig - every dash, lunge and slam uses one
--   * a big part - a skill hitbox or its VFX; an M1 only ever spawns 1-2 stud
--     markers, so the size threshold separates them cleanly
-- Deliberately NOT keyed on sound names. The obvious rule was "any Sound not
-- called Punched*", but Punched* is this game's FIST hit sound: equip a katana,
-- or fight a boss with different audio, and that inverts into dodging
-- constantly. The mover appears in the same frame as the sound anyway, so
-- nothing is lost. LinearVelocity and AlignOrientation are excluded for the
-- same reason - they are the knockback our own M1 puts on the rig.
local farmIsMover
local function farmTrigger(x)
    -- Our own air combo holds the target up with an AlignPosition inside an
    -- `air_combo_bp`: measured live, the farm dodged its own combo for 3s.
    if x.Name == 'air_combo_bp' or x:FindFirstAncestor('air_combo_bp') then
        return false
    end
    if FARM.evadeIgnore[x.Name] then return false end
    if x:IsA('BasePart') then
        return x.Size.Magnitude > FARM.evadePart
    end
    return farmIsMover(x)
end

-- Movers cover dashes and lunges; big parts cover telegraphed AoEs, whose
-- indicator lives for the whole wind-up. Sounds are excluded from both roles: a
-- looping one outlives its move by seconds (PS2reaperBLITZloop lingers 10.6s
-- against a 3.3s dash) and would strand us.
farmIsMover = function(x)
    return x:IsA('BodyVelocity') or x:IsA('BodyGyro') or x:IsA('BodyPosition')
        or x:IsA('AlignPosition') or x:IsA('AngularVelocity')
end

-- The first solid surface at or below `from`, ignoring every character and rig
-- (our own included) so a cast from a target's root finds the ground under it,
-- not its own legs. nil when there is nothing within `span` studs.
function FARM.groundBelow(from, span)
    local p = FARM.rayParams
    if not p then
        p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.IgnoreWater = true
        FARM.rayParams = p
    end
    -- every character, ours and other players', plus the NPC folder; rebuilt
    -- at most once a second rather than allocated every frame
    if clock() >= (FARM.rayAt or 0) then
        FARM.rayAt = clock() + 1
        local ex = {}
        for _, pl in Plrs:GetPlayers() do
            if pl.Character then ex[#ex + 1] = pl.Character end
        end
        local rigs = workspace:FindFirstChild('Humanoids')
        if rigs then ex[#ex + 1] = rigs end
        p.FilterDescendantsInstances = ex
    end
    local hit = workspace:Raycast(from, vec3(0, -(span or 300), 0), p)
    return hit and hit.Position.Y or nil
end

-- `cf`, moved down if need be so the body is at least FARM.bury studs under
-- the ground at its X/Z - for parking. A spot with anything overhead is left
-- alone; a spot in open air drops below the surface under it. Measured before
-- this: parking on the exact frame of a kill surfaced us whenever the target
-- died airborne, 516 frames in 100s.
function FARM.buried(cf)
    local pos = cf.Position
    local top = FARM.groundBelow(pos + vec3(0, 200, 0), 400)
    if top and top < pos.Y + 2.5 then
        return CFrame.new(vec3(pos.X, top - FARM.bury, pos.Z)) * cf.Rotation
    end
    return cf
end

local function farmWatchSkills(rig)
    -- Every rig is watched. `SkillBrain = 0` looks like "cannot cast" and is
    -- not: a Mizunoto carrying it was caught with PS2WBwaterwheelSTART on its
    -- root - Water Breathing's Water Wheel - so gating on it would stop us
    -- dodging a real skill.
    farmEvadeConns[#farmEvadeConns + 1] = rig.DescendantAdded:Connect(function(x)
        local ok, is = pcall(farmTrigger, x)
        if not (ok and is) then return end
        local now = clock()
        if now > FP.evadeUntil then FP.hardStop = now + FARM.evadeMax end
        -- Both kinds hold the dodge, not just movers. A telegraphed AoE puts a
        -- big indicator part down showing where it will land and only resolves
        -- when that part goes away, so treating the part as a mere trigger
        -- brought us back mid-wind-up, straight into the hit.
        farmMarkers[x] = true
        FP.evadeUntil = max(FP.evadeUntil, now + FARM.evadeMin)
        -- Named, because a dodge that never ends looks exactly like a farm
        -- that never goes to the target. Printed once per name to the console
        -- (F9), so a user on another machine can read off what triggers it.
        local what = x.ClassName .. ' ' .. x.Name
            .. (x:IsA('BasePart') and fmt(' (%.1f studs)', x.Size.Magnitude) or '')
        FARM_STATE.dodge = what
        FARM.dodgeSeen = FARM.dodgeSeen or {}
        if not FARM.dodgeSeen[x.Name] then
            FARM.dodgeSeen[x.Name] = true
            print('[project] dodge trigger: ' .. what .. ' on ' .. rig.Name)
        end
    end)
    farmEvadeConns[#farmEvadeConns + 1] = rig.DescendantRemoving:Connect(function(x)
        farmMarkers[x] = nil
    end)

end

local function farmEngage(rig, root, hum)
    if not farmBind() then return end
    farmRig, farmRoot, farmHum = rig, root, hum
    -- the state machine is the only thing that turns collision back on
    if farmMe then farmStateConn = farmMe.StateChanged:Connect(farmPhase) end
    farmWatchSkills(rig)
    farmPhase()
    -- Start from whatever worked on this kind of enemy last time, else the
    -- configured offset. Clamped, because the slider can move under us.
    -- Only a probable rig gets either: everything else holds the slider.
    FP.probing = farmProbable(rig.Name)
    FARM_STATE.probing = FP.probing
    local want  = (FP.probing and REACH_CACHE[rig.Name]) or FARM.under
    FP.reach   = max(min(want, FARM.under), FARM.underMin)
    FP.base    = FARM.under
    FP.probeAt, FP.probeSwings = clock(), 0
    FP.lastHp  = hum and hum.Health or nil
    FP.ground  = nil
    farmEngaged        = true
    farmBeat           = clock()
    FARM_STATE.engaged = true
    FARM_STATE.target  = rig
    FARM_STATE.frames, FARM_STATE.dodgeFrames = 0, 0
end

-- Never writes FARM.on: the toggle owns that value and a pill cannot be
-- resynced, so a kill has to leave the switch exactly where the user put it.
local function farmDisengage(goHome)
    -- The return point is the plain farm's. The raid and wave farm decide
    -- where the body goes themselves: with a return point set, every WAVE kill
    -- teleported us home - somewhere off the current dungeon map - once wave
    -- farm stopped claiming loot (the loot hold used to cancel the trip), and
    -- the camp raid went home after each camp's loot.
    if RAID.active() then goHome = false end
    farmEngaged        = false
    FARM_STATE.engaged = false
    FARM_STATE.target  = nil
    if farmStateConn then
        farmStateConn:Disconnect()
        farmStateConn = nil
    end
    for _, c in farmEvadeConns do pcall(function() c:Disconnect() end) end
    clear(farmEvadeConns)
    clear(farmMarkers)
    FP.evadeUntil, FP.hardStop = 0, 0
    FARM_STATE.evading = false
    -- A kill with loot wanted hands the body to the loot hold instead of
    -- going home: the chest spawns here, after the kill. A retreat, a switch-
    -- off or the watchdog leaves a living target and goes home as before.
    local died = farmHum and (farmHum.Health <= 0 or not (farmRig and farmRig.Parent))
    -- A kill parks us where the fight left us - under the corpse, in the
    -- ground - until something else takes the body, instead of letting the
    -- ground eject us into view between engagements (see FARM.parked). Only a
    -- kill: a retreat must not hold us under the boss we are running from.
    FARM.park = died and farmHrp and farmHrp.Parent and FARM.buried(farmHrp.CFrame) or nil
    if died and FARM.lootArm and FARM.lootArm(goHome) then goHome = false end
    if goHome and farmHome and farmHrp and farmHrp.Parent then
        FARM.park = nil
        farmHrp.CFrame                 = farmHome
        farmHrp.AssemblyLinearVelocity = ZERO
    end
    farmRig, farmRoot, farmHum = nil, nil, nil
    FP.reach, FP.lastHp, FP.base = nil, nil, nil
    FP.probing, FARM_STATE.probing = false, false
end

-- Argument 2 is the SWING PRESET, not the constant it looks like. Unarmed it is
-- 'Combat' (ReplicatedStorage.Effects.Swings.Combat_Swings); with a weapon it is
-- that weapon's preset - and the preset is NOT the item's name. A Cutlass ships
-- 'Regular Katana', because its item module carries
-- `CombatPreset = 'Regular Katana'`. Traced live: every swing with a Cutlass
-- equipped sent 'Regular Katana'.
--
-- Getting this wrong is the quiet kind of wrong. The server accepts the call
-- either way, so nothing errors and nothing in the log looks off - the combo
-- just does not do what a combo should. The farm hardcoded 'Combat', so it was
-- throwing fists while holding a sword.
-- Everything that decides the payload lives in one block: a concatenated test
-- chunk shares this file's top-level scope, and Luau allows 200 locals in it.
local farmPayload   -- (step, opener) -> preset, delay
local farmGap       -- () -> seconds to wait before the next step
do
    local FISTS = 'Combat'
    local presetOf = {}   -- item name -> preset, resolved once per item

    -- The game's own two tables, which beat anything hardcoded here:
    --   Presets  - the 27 names the server actually knows. Anything not in it
    --              is not a swing preset, whatever it is called.
    --   Items    - `CombatPreset` and `Category` per item.
    -- Both are plain requireable modules, so this is a read, not a guess.
    local function modTable(...)
        local n = RepS
        for _, seg in { ... } do
            n = n and n:FindFirstChild(seg)
            if not n then return end
        end
        if not (n and n:IsA('ModuleScript')) then return end
        local ok, t = pcall(require, n)
        if ok and type(t) == 'table' then return t end
        return nil
    end

    local cpCache, presetsCache, itemsCache
    local function COMBAT()
        if cpCache == nil then
            cpCache = modTable('CAM', 'Global', 'Combat_presets') or false
        end
        return cpCache or nil
    end
    local function PRESETS()
        if presetsCache == nil then
            local cp = COMBAT()
            presetsCache = (cp and type(cp.Presets) == 'table' and cp.Presets)
                or false
        end
        return presetsCache or nil
    end
    local function ITEMS()
        if itemsCache == nil then
            itemsCache = modTable('CAM', 'Global', 'Collectibles', 'Items')
                or false
        end
        return itemsCache or nil
    end

    -- The equipped item. Two traps, both hit live:
    --
    --  * `Tool_Accessories` holds NON-weapons too. An Iguro character carries
    --    `Kaburamaru` there, flagged `_ClanAccessory`, and the old
    --    FindFirstChildOfClass('Model') fallback picked it - so every swing
    --    shipped `preset = 'Kaburamaru'`, which is not one of the 27 presets
    --    the server knows. The sheathe models (`Basic Katana 1 Sheathe`) are
    --    siblings of the blade and are the same trap wearing a scabbard.
    --  * the `Value` attribute genuinely ends in `Unequipped` when the weapon
    --    is put away, and unequipped means FISTS. Matching that suffix and
    --    then returning the name was backwards.
    --
    -- Hence: the attribute is authoritative when present, a Model is accepted
    -- only if it resolves to a real preset, and the whole thing is validated
    -- against `Presets` before it goes out. NPC rigs also show the attribute
    -- can carry a `Combat-` prefix (`Combat-Obi ManipulationEquipped`).
    local function farmItem()
        local ch = Me.Character
        local ta = ch and ch:FindFirstChild('Tool_Accessories')
        if not ta then return end
        local v = ta:GetAttribute('Value')
        if type(v) == 'string' then
            local name = v:match('^(.+)Unequipped$') or v:match('^(.+)Equipped$')
            if name and name ~= '' then
                return (name:gsub('^Combat%-', ''))
            end
        end
        return ta   -- no attribute: let the caller sift the Models
    end

    -- item name -> a name the server knows, or nil.
    local function resolve(item)
        if type(item) ~= 'string' or item == '' then return end
        local cached = presetOf[item]
        if cached ~= nil then
            if cached == false then return nil end
            return cached
        end

        local P, I = PRESETS(), ITEMS()
        local entry = I and I[item]
        local preset = item        -- a weapon with no override IS its own
        if type(entry) == 'table' and type(entry.CombatPreset) == 'string' then
            preset = entry.CombatPreset
        else
            -- The same field also lives on the per-item ModuleScript at
            -- Items.<Category>.<Item>. Both are real; whichever answers wins.
            local items = RepS:FindFirstChild('Items')
            for _, cat in (items and items:GetChildren() or {}) do
                local mod = cat:FindFirstChild(item)
                if mod and mod:IsA('ModuleScript') then
                    local ok, t = pcall(require, mod)
                    if ok and type(t) == 'table'
                        and type(t.CombatPreset) == 'string' then
                        preset = t.CombatPreset
                    end
                    if type(entry) ~= 'table' then entry = ok and t or nil end
                    break
                end
            end
        end
        if P and not P[preset] then
            -- 18 of the 25 Category='Katana' items carry no CombatPreset and
            -- are not preset names themselves; they all swing as the base
            -- katana. Every other combat Category resolves directly.
            if type(entry) == 'table' and entry.Category == 'Katana'
                and P['Regular Katana'] then
                preset = 'Regular Katana'
            else
                preset = nil
            end
        end
        presetOf[item] = preset or false
        return preset
    end

    -- Is this toolbar item a WEAPON? It has to resolve to a swing preset the
    -- server knows, and not be fists or a fighting style: `Combat` (fists) is
    -- itself a preset, and styles carry Category 'Style'. With no preset table
    -- to check against nothing counts - a potion must never be "equipped" as a
    -- weapon on a guess. Read live: Claws is Category 'Weapons', a Cutlass
    -- 'Katana', the Biwa Bell 'Quest Items', potions 'Potions'.
    -- The equipped preset's wind-up before the hit is judged, for the lead.
    -- FARM_STATE.preset is set on every swing; before the first, 0.2.
    function FARM.hitDelay()
        local P = PRESETS()
        local p = P and FARM_STATE.preset and P[FARM_STATE.preset]
        local d = p and (p.default_before_hit or p.default_before_swing)
        return type(d) == 'number' and d or 0.2
    end

    function FARM.isWeapon(item)
        if not PRESETS() then return false end
        local p = resolve(item)
        if not p or p == FISTS then return false end
        local I = ITEMS()
        local e = I and I[item]
        return not (type(e) == 'table' and e.Category == 'Style')
    end

    local function farmPreset()
        local item = farmItem()
        if item == nil then return FISTS end
        if type(item) == 'string' then return resolve(item) or FISTS end
        -- `item` is the Tool_Accessories folder: no attribute to read, so take
        -- the first Model that is a real weapon and ignore clan pets, sheathes
        -- and anything else parked in there.
        for _, m in item:GetChildren() do
            if m:IsA('Model') and not m:GetAttribute('_ClanAccessory') then
                local p = resolve(m.Name)
                if p then return p end
            end
        end
        return FISTS
    end

    -- Argument 5 is a small client-reported animation offset, not a gate - the
    -- server ignores it. These are the values traced off the real client.
    local SWING = {
        ['Combat']         = { opener = 0.038, 0.13,  0,     0,     0,   0.15  },
        ['Regular Katana'] = { opener = 0.093, 0.125, 0.065, 0.065, 0.1, 0.075 },
    }

    -- What DOES gate the chain is the wait between steps, and the server paces
    -- it. Firing all five as fast as the client can send registers exactly one
    -- swing - which reads in play as "it only hits once, the mob gets knocked
    -- back, and the rest of the combo vanishes". Measured by firing 1..5 and
    -- reading the character's own `last_combo` attribute back off the server:
    --
    --     gap 0.00 -> 1     gap 0.15 -> 3
    --     gap 0.05 -> 2     gap 0.26 -> 5
    --
    -- 0.26 is exactly `Presets.Combat.default`, so the number is not a magic
    -- constant - it is the preset's own inter-swing wait, and every preset
    -- ships one (0.25 katana, 0.3 claws). Read it live and divide by the
    -- character's attack speed. Chains need no rest between them: three
    -- back-to-back chains at 0.26 all registered 5, 5, 5.
    farmGap = function()
        local P = PRESETS()
        local t = P and P[FARM_STATE.preset or FISTS]
        local d = t and tonumber(t.default)
        if not d then return FARM.gap end
        local mult, cp = 1, COMBAT()
        if cp and type(cp.attackSpeedMult) == 'function' then
            local ok, m = pcall(cp.attackSpeedMult)
            m = ok and tonumber(m)
            if m and m > 0 then mult = m end
        end
        return max(FARM.gap, d / mult)
    end

    farmPayload = function(step, opener)
        local preset = farmPreset()
        local t = SWING[preset] or SWING['Regular Katana']
        return preset, opener and t.opener or (t[step] or 0)
    end
end

local function farmSwing(step, opener)
    local remote = farmRemote()
    if not remote then return end
    local preset, d = farmPayload(step, opener)
    FARM_STATE.preset = preset
    FARM_STATE.swings = (FARM_STATE.swings or 0) + 1
    FP.probeSwings += 1
    remote:FireServer('Combat_Service', preset, step, opener and true or false,
        d, false, nil)
end

-- Candidates come from the ESP's own tracked set, so there is no second world
-- scan. A boss folder is tracked from its BossInfo and stays tracked while the
-- rig is despawned, which is exactly the entry you want to arm and wait on.
local function farmRefresh()
    if not FARM.dd then return end

    local origin = farmHrp and farmHrp.Parent and farmHrp.Position
    local rows, n = {}, 0
    for c, d in tracked do
        if FARM_CATS[d.cat] and typeof(c) == 'Instance' and c.Parent then
            -- Not d.anchor: the draw loop refreshes geometry only for a category
            -- that is switched on, and every category ships off, so an anchor
            -- can be a dead rig's orphaned root long after a respawn. Resolving
            -- the same way engagement does keeps "(-)" meaning exactly "cannot
            -- be engaged right now".
            local root = farmRoots[c]
            if not (root and root.Parent) then
                local _, live = farmResolve(c)
                root         = live
                farmRoots[c] = live
            end
            local dist
            if origin and root then
                dist = (root.Position - origin).Magnitude
            end
            if d.cat == 'Boss' or (dist and dist <= FARM.range) then
                n += 1
                rows[n] = { key = c, name = c.Name, dist = dist }
            end
        end
    end

    sort(rows, function(a, b)
        if (a.dist == nil) ~= (b.dist == nil) then return b.dist == nil end
        if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
        return a.name < b.name
    end)

    -- One row per NAME. The distance still decides the ORDER - nearest spawned
    -- first, unspawned alphabetically after - but it stays out of the label, so
    -- the list only churns when the set of names changes rather than every time
    -- we move. Names repeat freely (four folders here are called Bandit, and
    -- Bear Cubs come in litters) and they used to get `#2`, `#3` suffixes:
    -- four rows that all meant "a bear cub", where picking one bound the farm
    -- to a single body that would be dead a minute later. A name is the right
    -- unit of choice, so duplicates collapse and the FIRST row wins - which,
    -- given the sort above, is the nearest spawned one.
    clear(FARM.labels)
    local labels, seen = {}, {}
    for i = 1, n do
        local r = rows[i]
        if not seen[r.name] then
            seen[r.name] = true
            labels[#labels + 1] = r.name
            FARM.labels[r.name]  = r.key
            if #labels >= FARM.cap then break end
        end
    end

    local sig = concat(labels, '\0')
    if sig ~= FARM.sig then
        FARM.sig = sig
        FARM.dd:modify({ elements = labels })
    end
end

-- Typed lookup. Ranked so 'zuko' beats a substring hit elsewhere, and among
-- equal matches the nearest one wins; searches `tracked` rather than the
-- dropdown so it reaches targets past the list cap too.
local function farmFind(q)
    if type(q) ~= 'string' then return end
    q = q:lower():match('^%s*(.-)%s*$')
    if q == '' then return end

    local origin = farmHrp and farmHrp.Parent and farmHrp.Position
    local best, bestScore, bestDist
    for c, d in tracked do
        if FARM_CATS[d.cat] and typeof(c) == 'Instance' and c.Parent then
            local name = c.Name:lower()
            local score
            if name == q then score = 3
            elseif name:sub(1, #q) == q then score = 2
            elseif name:find(q, 1, true) then score = 1 end

            if score then
                local root = farmRoots[c]
                if not (root and root.Parent) then
                    local _, liveRoot = farmResolve(c)
                    root         = liveRoot
                    farmRoots[c] = liveRoot
                end
                local dist = (origin and root)
                    and (root.Position - origin).Magnitude or math.huge
                if not best or score > bestScore
                    or (score == bestScore and dist < bestDist) then
                    best, bestScore, bestDist = c, score, dist
                end
            end
        end
    end
    return best
end

-- A name to the body that should answer to it right now: nearest spawned wins,
-- and failing that any tracked entry with that name, so an unspawned boss can
-- still be armed in advance and picked up the moment it appears. This runs
-- every tick, which is what makes a target survive its own death - the next
-- Bear Cub simply becomes the one we are farming.
local function farmPick(name)
    if type(name) ~= 'string' or name == '' then return end
    local origin = farmHrp and farmHrp.Parent and farmHrp.Position
    local live, liveDist, idle
    for c, d in tracked do
        if FARM_CATS[d.cat] and typeof(c) == 'Instance' and c.Parent
            and c.Name == name then
            local rig, root, hum = farmResolve(c)
            if rig and hum and hum.Health > 0 then
                local dist = (origin and root)
                    and (root.Position - origin).Magnitude or math.huge
                if not live or dist < liveDist then live, liveDist = c, dist end
            elseif not idle then
                idle = c
            end
        end
    end
    return live or idle
end

-- Whether anything has asked the farm to fight: its own toggle, the raid, or
-- the auto quest. The raid and the quest DRIVE the farm rather than writing
-- FARM.on - a Seoul pill cannot be resynced, so a flag written from outside the
-- menu would leave the Farm switch lying for the session. Auto quest used to
-- need Farm target switched on beside it and, with only itself on, held the
-- quest and never swung - reported as "doesn't seem to actually start
-- attacking the targets".
function FARM.driven()
    return FARM.on or RAID.active() or (FARM.quest ~= nil and FARM.quest.on) or false
end

-- FARM_STATE.why exists because every refusal below is silent. A farm that is
-- switched on and doing nothing is indistinguishable from a broken one, and
-- "it just would not start" is the single hardest thing to diagnose here.
local function farmTick()
    FARM_STATE.key = farmKey
    FARM_STATE.want = farmWant
    if not FARM.driven() then
        FARM_STATE.why = 'off'
        return
    end
    if not farmWant then
        FARM_STATE.why = 'no target selected'
        return
    end
    -- Re-resolve the name every tick. A body that died or despawned is simply
    -- replaced by the next one answering to the same name, which is the whole
    -- point of targeting by name: the selection outlives the individual. Only
    -- a name that matches NOTHING any more is a refusal, and it keeps the
    -- selection so the farm picks up again when one respawns.
    -- Except the raid's pick. The raid addresses one specific BODY - the free
    -- mob of two with the same name, when another player is on the nearer -
    -- and re-picking by name here swapped it for the nearest same-named one
    -- before we had even engaged, which put two players on one mob.
    local raidBody = RAID.active() and farmKey ~= nil and farmResolve(farmKey) ~= nil
    if not (farmKey and typeof(farmKey) == 'Instance' and farmKey.Parent
        and farmKey.Name == farmWant and (farmEngaged or raidBody)) then
        local picked = farmPick(farmWant)
        if picked ~= farmKey then
            if farmEngaged then farmDisengage(true) end
            farmKey = picked
        end
    end
    if not farmKey then
        FARM_STATE.why = fmt('nothing named %s is tracked', farmWant)
        if FARM.seekWhy then FARM.seekWhy(farmWant) end
        return
    end
    if not farmBind() then
        FARM_STATE.why = 'no character'
        return
    end

    if farmRig and farmRig.Parent and farmRoot and farmRoot.Parent
        and farmHum and farmHum.Health > 0 then
        FARM_STATE.why = 'engaged'
        return
    end
    -- the last kill's loot first; the next target can wait for it
    if farmEngaged and not (farmHum and farmHum.Health > 0) then farmDisengage(true) end
    if FARM.lootHeld and FARM.lootHeld() then
        FARM_STATE.why = 'claiming loot'
        return
    end
    -- a kill before the quest is back in hand is a kill that counts for nothing
    if FARM.questHeld and FARM.questHeld() then
        FARM_STATE.why = 'quest: ' .. tostring(FARM.quest.why)
        return
    end

    local hp    = farmMe and farmMe.Health or math.huge
    local maxHp = (farmMe and farmMe.MaxHealth > 0) and farmMe.MaxHealth or 0
    -- A flat bail is right - what kills you is a skill landing for 250-300,
    -- which does not shrink with your pool - but a bail at or above the pool
    -- means "never engage", and it would do that silently. Cap it live so there
    -- is always a band above it to fight in, whatever MaxHealth becomes.
    local bail = FARM.bail
    if maxHp > 0 then bail = min(bail, floor(maxHp * 0.9)) end
    -- Healing up AFTER a retreat. This used to gate every engagement, not just
    -- re-entry, so the farm silently refused to start at any health under
    -- `resume` - which is nearly always - and reported nothing.
    if FARM_STATE.retreated and FARM.resume > 0 and hp < FARM.resume then
        FARM_STATE.why = fmt('healing: %d hp, resume at %d', floor(hp), FARM.resume)
        if farmEngaged then farmDisengage(true) end
        return
    end
    -- but never walk in below the bail line itself
    if bail > 0 and hp <= bail then
        FARM_STATE.why = fmt('health too low: %d hp, bail is %d', floor(hp), bail)
        if farmEngaged then farmDisengage(true) end
        return
    end
    FARM_STATE.retreated = false

    -- the target is down or has despawned: go home and wait for it to come back
    if farmEngaged then farmDisengage(true) end
    local rig, root, hum = farmResolve(farmKey)
    if rig then
        farmEngage(rig, root, hum)
        FARM_STATE.why = 'engaged'
    else
        FARM_STATE.why = 'target is not spawned'
        if FARM.seekWhy then FARM.seekWhy(farmWant) end
    end
end

local function farmStep()
    if not alive then return end
    -- The loot run owns the body while it is hopping between prompts. Stamp the
    -- beat anyway or the watchdog reads a deliberate pause as a wedge.
    if FARM_STATE.looting then
        farmBeat = clock()
        return
    end
    if not FARM.driven() then
        if farmEngaged then farmDisengage(true) end
        return
    end
    -- Our character is replaced on every death. farmHrp is only refreshed by the
    -- 1.5s scan, so without this we stop being pinned for up to a second and a
    -- half after a respawn, and the collision watcher stays bound to the dead
    -- humanoid for the rest of the engagement - the farm looks alive and does
    -- nothing. One property read per frame buys immediate recovery.
    if Me.Character ~= farmChar then
        farmBind()
        if farmEngaged then
            if farmStateConn then farmStateConn:Disconnect() end
            farmStateConn = farmMe and farmMe.StateChanged:Connect(farmPhase) or nil
            farmPhase()
        end
    end
    -- Two number reads per frame, and the only thing fast enough to matter:
    -- Gyutai took us 147 -> 0 in six seconds, which the 1.5s scan would miss.
    if farmEngaged and FARM.bail > 0 and farmMe and farmMe.Parent
        and farmMe.MaxHealth > 0 and farmMe.Health > 0
        and farmMe.Health <= min(FARM.bail, floor(farmMe.MaxHealth * 0.9)) then
        FARM_STATE.retreated = true
        farmDisengage(true)
        return
    end

    if not (farmEngaged and farmHrp and farmHrp.Parent) then return end
    if not (farmRoot and farmRoot.Parent) then return end
    -- A corpse is a deliberate wait, not a wedge: the scan disengages properly
    -- - and goes home - within its 1.5s, but the watchdog trips at 1.0s, so
    -- without stamping the beat here a kill landing more than a second before
    -- the next scan was torn down by the watchdog INSTEAD, and the watchdog
    -- does not go home because it does not know where we are. That is most
    -- kills, and it presents as the farm sometimes just staying at the corpse.
    -- Our own death is the same shape: the scan rebinds, the watchdog cannot.
    if farmMe and farmMe.Health <= 0 then
        farmBeat = clock()
        return
    end
    -- The target died: hand over NOW, not on the next scan. Waiting left the
    -- body unpinned for up to 1.5s - the ground ejected it into view and the
    -- mobs around the corpse hit it - and the next engagement waited the same
    -- 1.5s. farmDisengage arms the loot hold (which pins us where we are) or
    -- parks us there, and the deferred tick engages the next body at once.
    if not farmHum or farmHum.Health <= 0 then
        farmBeat = clock()
        farmDisengage(true)
        task.defer(guard, farmTick)
        return
    end

    -- Hold the dodge for exactly as long as a mover is alive. The move outlives
    -- its own animation - sonido_dash runs 3.26s - which is why returning on a
    -- fixed 3.0s timer ate a hit at +3.30s every time. Tracking the mover ends
    -- the dodge on the frame it dies, with no timer to guess at.
    if FARM.evade then
        local live = false
        for x in farmMarkers do
            if x.Parent then live = true else farmMarkers[x] = nil end
        end
        local now = clock()
        -- A live mover holds the dodge by itself. The grace and the minimum only
        -- cover the edges, so with grace at 0 we come back on the very frame the
        -- mover dies rather than on any timer.
        if live and FARM.evadeGrace > 0 then
            FP.evadeUntil = max(FP.evadeUntil, now + FARM.evadeGrace)
        end
        -- Disarm as it fires, so a spent stop is not re-tested and re-cleared
        -- on every later frame. Tidying only: the next marker re-arms it
        -- anyway, because a hard stop leaves farmEvadeUntil at 0.
        if FP.hardStop > 0 and now > FP.hardStop then
            FP.hardStop   = 0
            FP.evadeUntil = 0
            clear(farmMarkers)
            live = false
        end

        FARM_STATE.evading = live or now < FP.evadeUntil
    else
        FARM_STATE.evading = false
    end

    -- The slider wins whatever the target is: a new configured offset moves
    -- the body now and restarts any search from there.
    if FP.reach and FP.base ~= FARM.under then
        FP.base, FP.reach = FARM.under, FARM.under
        FP.probeAt, FP.lastHp, FP.probeSwings = clock(), nil, 0
    end

    -- Probe for reach, on the rigs that need it and on no others. A rig we
    -- cannot hurt from here looks identical to one we are simply missing, so
    -- the only honest signal is the target's health going down. Any drop
    -- confirms the current offset and banks it against the rig's name; a full
    -- `probe` window with nothing to show steps us in a stud. Only runs while
    -- actually swinging - a dodge parks us 37 studs out, and counting that as
    -- "out of reach" would walk the offset to the floor.
    if FP.probing and not FARM_STATE.evading and farmHum and FP.reach then
        local hp = farmHum.Health
        if FP.lastHp and hp < FP.lastHp - 0.01 then
            -- it is landing from here: this is the distance worth keeping
            REACH_CACHE[farmRig and farmRig.Name or '?'] = FP.reach
            FP.probeAt, FP.probeSwings = clock(), 0
        elseif clock() - FP.probeAt > FARM.probe
            and FP.probeSwings >= FARM.probeSwings then
            if FP.reach > FARM.underMin then
                FP.reach = max(FARM.underMin, FP.reach - 1)
            end
            FP.probeAt, FP.probeSwings = clock(), 0
        end
        FP.lastHp = hp
    end
    FARM_STATE.reach = FP.reach

    -- Written every frame on purpose: gravity still pulls on the body, so
    -- skipping the write because the target has not moved makes us sink.
    local cf   = farmRoot.CFrame
    lootAnchor, lootAnchorAt = cf.Position, clock()
    local drop = FARM_STATE.evading and FARM.evadeDrop or 0
    -- measured every frame so the estimate is warm; not applied mid-dodge,
    -- which is about getting away from the target, not meeting it
    local ahead = FARM.leadOffset(farmRoot)
    if FARM_STATE.evading then ahead = ZERO end
    FARM_STATE.lead = ahead.Magnitude
    local aim
    if FARM.place == 'behind' then
        -- +Z is a part's back, since LookVector points down -Z
        local spot = (cf * CFrame.new(0, 0, FARM.behind)).Position - vec3(0, drop, 0) + ahead
        aim = CFrame.lookAt(spot, cf.Position + ahead)
    else
        -- 'above' or 'under'. The dodge pushes further along the same axis, so
        -- from above it goes up and from below it goes down - either way it is
        -- moving away from the target rather than through it.
        local p    = cf.Position + ahead
        local sign = FARM.place == 'under' and -1 or 1
        local spot = vec3(p.X, p.Y + sign * (farmUnder() + drop), p.Z)
        -- A knocked-up target is FOLLOWED into the air - the hits land while it
        -- is up - everywhere except WAVE farm from floor `stayFloor` (50) on,
        -- where the spot stays UNDER THE GROUND however high it goes
        -- (requested). Deep floors hit hard (DeepFloor = 50 in the tower's
        -- own settings: damage and health scale faster from there), so being
        -- exposed in the air costs more than the hits it buys. A target
        -- standing on the ground already puts `under` below the surface, so
        -- the clamp only bites once it is up. One ground cast per
        -- `groundEvery` or sideways move, not one per frame.
        local stay = RAID.wave and FARM.towerFloor ~= nil
            and (FARM.towerFloor() or 0) >= FARM.stayFloor
        if sign < 0 and stay then
            local g = FP.ground
            if not g or clock() - g.t > FARM.groundEvery
                or (vec3(p.X, 0, p.Z) - g.xz).Magnitude > 2 then
                g = { t = clock(), xz = vec3(p.X, 0, p.Z), y = FARM.groundBelow(p, 300) }
                FP.ground = g
            end
            if g.y and spot.Y > g.y - FARM.bury then
                spot = vec3(spot.X, g.y - FARM.bury, spot.Z)
            end
        end
        -- Face the target: down from above, up from below. lookAt needs an
        -- explicit up vector here, or a vertical look direction leaves the
        -- default (0,1,0) parallel to it and so degenerate.
        aim = CFrame.lookAt(spot, spot - vec3(0, sign, 0), BACK)
    end
    farmHrp.CFrame                 = aim
    farmHrp.AssemblyLinearVelocity = ZERO
    FARM_STATE.frames += 1
    if FARM_STATE.evading then FARM_STATE.dodgeFrames += 1 end
    -- Stamped only on a frame that actually pinned us, which is what makes the
    -- watchdog in the scan loop mean something.
    farmBeat = clock()
end

conns[#conns + 1] = Run.Heartbeat:Connect(function() guard(farmStep) end)

-- One pass of the client's own combo, split out so the loop can run it through
-- guard(): an error in the loop body would otherwise kill the thread and stop
-- the farm swinging for the rest of the session with the pill still green.
local function farmCombo()
    if not (FARM.driven() and farmEngaged and farmHum
        and farmHum.Health > 0 and not FARM_STATE.evading) then
        -- short, because this is also the delay between engaging and the first
        -- swing landing
        task.wait(0.05)
        return
    end
    -- EVERY chain opens fresh. This used to latch: one `farmOpener` went false
    -- after the first swing of an engagement and never came back, so chain 2
    -- onwards shipped step 1 with runHit = false for the rest of the fight -
    -- the game's "this is a continuation" flag, sent forever. Measured against
    -- a boss at 50 swings a row: runHit never = 1.70 damage per swing, fresh
    -- on each chain's step 1 = 2.20. It is the difference between a combo that
    -- connects and one that lands its opener and fizzles.
    for step = 1, 5 do
        -- mid-combo too, not just between them: a dodge that starts on
        -- step 2 would otherwise keep firing the rest of the chain
        if not (alive and FARM.driven() and farmEngaged) then break end
        if FARM_STATE.evading then break end
        if not farmHum or farmHum.Health <= 0 then break end
        farmSwing(step, step == 1)
        -- The server paces the chain and will not register a step that arrives
        -- early: at a zero gap it banks exactly ONE swing out of five. farmGap
        -- reads the wait off the preset the client itself uses, so this tracks
        -- the weapon instead of a config number. Chains need no rest between
        -- them, so the loop just comes straight back round.
        task.wait(farmGap())
    end
    -- Then the skills, in the order typed. Real key presses rather than the
    -- skill remote, so the game's client supplies the payload - its mousepos
    -- argument included, which we have no way to know. Every condition is
    -- re-checked per key, because a dodge can start during the hold, and a
    -- focused text box would otherwise receive the keystrokes as typing.
    local keys = FARM.skillKeys
    if #keys == 0 then return end
    local ok, vim = pcall(game.GetService, game, 'VirtualInputManager')
    if not (ok and vim) then return end
    for _, name in keys do
        if not (alive and FARM.driven() and farmEngaged) then break end
        if FARM_STATE.evading then break end
        if not farmHum or farmHum.Health <= 0 then break end
        if Input:GetFocusedTextBox() then break end
        local code = Enum.KeyCode[name]
        FARM_STATE.skill = name
        vim:SendKeyEvent(true, code, false, game)
        task.wait(FARM.skillHold)
        vim:SendKeyEvent(false, code, false, game)
        task.wait(FARM.skillGap)
    end
end

task.spawn(function()
    while alive do
        -- every branch of farmCombo yields, so a failure cannot spin
        if not guard(farmCombo) then task.wait(0.2) end
    end
end)

-- ── skill aim ───────────────────────────────────────────────────────────────
-- Skills go out as ('server_skill_controller_signaler', <skill>,
-- 'Hold'|'UnHold'|'Cancel', <Vector3>[, nil]), and the Vector3 is the client's
-- mouse position - wherever the cursor happens to be. Logged live while the
-- farm pressed X/C/V: Explosive Fury aimed 90 studs from the Mizunoto it was
-- fighting, Flashing Willow 86. So while the farm is engaged, the game's own
-- skill calls get the target's root as their aim point instead. Everything
-- else passes through untouched: our own swings (checkcaller), every other
-- remote, and a skill cast by hand while the farm is not fighting.
--
-- One hook on the shared FireServer closure catches both call styles, which a
-- __namecall hook would not (see "Real MCP"). It is never unhooked: an old
-- run's closure goes pass-through once `alive` is false. Unhooking on cleanup
-- could restore the ORIGINAL over a newer run's hook when an old run tears
-- down late through the generation poll.
FARM.aimSkills = true
pcall(function()
    if type(hookfunction) ~= 'function' or type(newcclosure) ~= 'function'
        or type(checkcaller) ~= 'function' then
        return
    end
    FARM.fireOld = hookfunction(Instance.new('RemoteEvent').FireServer,
        newcclosure(function(self, a, b, c, d, ...)
            if alive and FARM.aimSkills and a == 'server_skill_controller_signaler'
                and typeof(d) == 'Vector3' and farmEngaged and farmRoot
                and farmRoot.Parent and not checkcaller() then
                d = farmRoot.Position
            end
            return FARM.fireOld(self, a, b, c, d, ...)
        end))
end)

-- The hook above fixes what the SERVER is told, but the skill's own client -
-- its VFX, anything it resolves locally - still followed the real cursor:
-- reported "they're still using my mouse pos". Every skill module reads
-- `mousepos` from CAM.Client.Controllers.Platform_Handler, the one module that
-- reads the cursor (GetMouseLocation -> ScreenPointToRay -> Raycast), and
-- Skill_Controller requires the same cached table. So its `mousepos` and
-- `getMouseDirection` are wrapped: while the farm is engaged they answer with
-- the target, otherwise with the real functions. The originals live ON the
-- module, so a re-execute wraps the real ones rather than our last wrapper.
pcall(function()
    local P = require(RepS.CAM.Client.Controllers.Platform_Handler)
    if type(P) ~= 'table' or type(P.mousepos) ~= 'function' then return end
    P.__psOrig = P.__psOrig or { mousepos = P.mousepos, dir = P.getMouseDirection }
    local orig = P.__psOrig
    local function aimed()
        return alive and FARM.aimSkills and farmEngaged and farmRoot and farmRoot.Parent
            and farmRoot.Position or nil
    end
    local pos = function(...)
        return aimed() or orig.mousepos(...)
    end
    local dir = function(...)
        local at = aimed()
        local from = farmHrp and farmHrp.Parent and farmHrp.Position
        if at and from and (at - from).Magnitude > 1e-3 then return (at - from).Unit end
        return orig.dir(...)
    end
    P.mousepos = pos
    if type(orig.dir) == 'function' then P.getMouseDirection = dir end
    FARM.aimRestore = function()
        if P.mousepos == pos then P.mousepos = orig.mousepos end
        if P.getMouseDirection == dir then P.getMouseDirection = orig.dir end
    end
end)

local function farmScan()
    farmBind()
    -- Watchdog. The Heartbeat stamps every frame it pins us; if it has not for a
    -- second while engaged, something is wedged that none of the guards above
    -- caught. Drop the engagement - without going home, since we do not know
    -- where we are - and let the tick below build a fresh one. Recovering
    -- blindly beats sitting there looking switched on.
    if farmEngaged and clock() - farmBeat > 1 then farmDisengage(false) end
    -- The list is not rebuilt mid-fight: pinned under a target every
    -- distance changes constantly, and each rebuild reclones every row.
    if not farmEngaged then farmRefresh() end
    farmTick()
end

task.spawn(function()
    while alive do
        guard(farmScan)
        task.wait(FARM.scan)
    end
end)

-- ── camera hold ──────────────────────────────────────────────────────────────
-- Farming from under a target parks the body inside the ground, and the
-- default camera collides with the world whatever the character does about its
-- own collisions: noclip is a property of OUR parts, and the camera's occlusion
-- test is not. So the whole fight is spent looking at terrain.
--
-- The camera is therefore taken outright - CameraType.Scriptable, one CFrame
-- written per frame - and flown slowly around the target: a held height, a
-- held distance and a steady circle, looking at the target the whole way.
-- Scriptable is also what switches the occlusion test off entirely, so there
-- is nothing left for the view to collide with.
--
-- Two things were tried first and are worth not repeating. Handing the DEFAULT
-- camera a subject above the target still orbits with the mouse, so the view
-- drifts with every twitch, and the game took the subject back on 18% of
-- frames. Sitting straight overhead looking down is steady but reads as a map,
-- not as a fight. The angle is what makes it a shot.
--
-- Nothing here reads the mouse on purpose: while the hold is on, the camera
-- moves only with the target and its own spin.
-- One table with its functions hung off it, for the register budget.
local CAMH = {
    y    = nil,     -- the height being held, nil when nothing is held
    dir  = nil,     -- unit horizontal direction from target to camera
    was  = nil,     -- the CameraType to put back
    held = false,
    -- The game's own scripts write the camera back to following us - measured
    -- live on CameraSubject, within about three frames - so ours has to be
    -- re-asserted every frame AND has to land after theirs. A render step bound
    -- just before Enum.RenderPriority.Camera is the one place guaranteed to.
    step = 'projectCamHold',
    -- Deadband in studs. A rig's root bobs with its animation, and its own
    -- attacks throw it around: measured live, a Kaiden Subordinate's root moved
    -- 27 studs vertically over ten seconds of being farmed. Following that
    -- verbatim rides the camera up and down for the whole fight, which is the
    -- thing this is meant to stop, so nothing inside the band moves it at all.
    band = 4,
    ease = 2,       -- studs-per-stud-per-second catch-up once outside the band
    floor = 2,      -- closest the camera may sit above the target: a target
                    -- thrown into the air climbs faster than the ease does,
                    -- and the shot must never end up underneath it
    near  = 6,      -- and no closer than this horizontally, or a distance of
                    -- zero leaves lookAt with no direction to work from
    -- A Heartbeat dt is not bounded, and one hitch should not swing the shot
    -- a third of the way round the target. Its own copy of the number rather
    -- than MOVE.maxStep: movement is declared further down this file, so the
    -- name would resolve to a nil global here and the spin would error every
    -- frame inside guard().
    maxStep = 0.1,
}

function CAMH.release()
    CAMH.y, CAMH.dir = nil, nil
    if not CAMH.held then return end
    CAMH.held = false
    -- Put back what was there, not what is usual: a game that runs its own
    -- camera type would otherwise be handed Custom and never get it back.
    if cam then
        -- ...but never Scriptable. A hold that engaged while the camera was
        -- already Scriptable - a re-execute overlapping the old run's hold -
        -- saved THAT as what was there, and every release after it put the
        -- lock back: reported as the camera staying locked with the farm off.
        local was = CAMH.was
        if was == Enum.CameraType.Scriptable then was = nil end
        cam.CameraType = was or Enum.CameraType.Custom
        local ch  = Me.Character
        local hum = ch and ch:FindFirstChildOfClass('Humanoid')
        if hum then cam.CameraSubject = hum end
    end
    CAMH.was = nil
end

function CAMH.pin(dt)
    local root = (alive and FARM.cam and farmEngaged
        and farmRoot and farmRoot.Parent) and farmRoot or nil
    if not (root and cam) then
        CAMH.release()
        return
    end
    dt = min(max(dt or 0, 0), CAMH.maxStep)
    local p    = root.Position
    local want = p.Y + FARM.camUp
    local y    = CAMH.y
    if not y then
        y = want
    elseif abs(want - y) > CAMH.band then
        -- Outside the band the target has genuinely changed height - knocked
        -- into the air, or walked down a hill. Ease into it rather than snap,
        -- or leaving the band is itself a jolt the width of the band.
        y += (want - y) * min(1, dt * CAMH.ease)
    end
    CAMH.y = y
    if not CAMH.held or not CAMH.dir then
        -- Start from where the user was already looking - behind the camera's
        -- own facing - so taking the camera does not swing the world round on
        -- the frame it engages.
        local look = cam.CFrame.LookVector
        local flat = vec3(-look.X, 0, -look.Z)
        CAMH.dir = flat.Magnitude > 1e-3 and flat.Unit or BACK
        CAMH.was = cam.CameraType
    else
        -- Rotate the held direction about Y rather than keep an angle and call
        -- atan2 on it: one sin and one cos a frame, and no angle to wrap.
        local a     = math.rad(FARM.camSpin) * dt
        local c, sn = math.cos(a), math.sin(a)
        local d     = CAMH.dir
        CAMH.dir   = vec3(d.X * c - d.Z * sn, 0, d.X * sn + d.Z * c).Unit
    end
    local out  = max(FARM.camOut, CAMH.near)
    local spot = CAMH.dir * out + vec3(p.X, max(y, p.Y + CAMH.floor), p.Z)
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(spot, p)
    CAMH.held  = true
end

-- Bound rather than connected: this has to run after whatever the game's own
-- camera scripts do and before the frame is drawn, which only a priority below
-- Enum.RenderPriority.Camera guarantees.
pcall(function()
    Run:BindToRenderStep(CAMH.step, Enum.RenderPriority.Camera.Value - 1,
        function(dt) guard(CAMH.pin, dt) end)
end)

-- ── teleports ───────────────────────────────────────────────────────────────
-- A second view over the ESP's own `tracked` set rather than a second world
-- scan, so places, NPCs, players, bosses, mobs and objects are all reachable
-- from the one list the ESP already maintains.
local TP = {
    cat  = 'Place',  -- category the list is showing
    up   = 4,        -- studs above the destination, so we do not land inside it
    hold = 0.6,      -- seconds to keep re-writing the CFrame after a jump. The
                     -- map streams, so a long jump arrives before the ground
                     -- does and one write drops us through the empty cell;
                     -- re-writing also outlasts a server correction.
    cap  = 60,       -- dropdown entries
    scan = 1.5,      -- seconds between list rebuilds
}

local tpDd, tpCatDd              -- menu elements, nil until the ui builds
TP.labels = {}                   -- label -> tracked key
TP.sig    = ''                   -- signature of the list last written
local tpKey                      -- selected tracked key
TP.token  = 0                    -- cancels a hold left over from an earlier jump
-- When the hold above stops re-writing our CFrame. Movement reads it: a jump
-- that is still being held and a flight write are two owners of one property.
local tpHoldUntil = 0
-- Resolved part per target, revalidated by Parent, weak keys. Same contract as
-- farmRoots and for the same reason: d.anchor is only maintained for categories
-- that are switched ON and every category ships off, so reading it here would
-- hand back a dead rig's orphaned root.
local tpParts  = setmetatable({}, { __mode = 'k' })
-- Last position we could actually resolve for a target. StreamingEnabled is on
-- here, so another player's character REPLICATES with all its scripts and
-- config and **zero BaseParts** once they are far enough away - there is no
-- position to read, and a list that drops anything without live geometry drops
-- every player who is not standing next to you. Remembering where they were
-- keeps them reachable, and still excludes a boss we have never seen.
local tpLastPos = setmetatable({}, { __mode = 'k' })

local function tpHrp()
    local ch = Me.Character
    return ch and ch:FindFirstChild('HumanoidRootPart')
end

local function tpPart(key)
    local p = tpParts[key]
    if p and p.Parent then return p end
    if typeof(key) ~= 'Instance' or not key.Parent then return end
    if key:IsA('BasePart') then
        tpParts[key] = key
        return key
    end
    -- PrimaryPart -> HumanoidRootPart -> first part. The first BasePart out of
    -- GetDescendants is an arbitrary limb, which puts the destination on an
    -- animated arm.
    local best = key:IsA('Model') and key.PrimaryPart or nil
    if not best then
        for _, x in key:GetDescendants() do
            if x:IsA('BasePart') then
                if x.Name == 'HumanoidRootPart' then
                    best = x
                    break
                end
                best = best or x
            end
        end
    end
    tpParts[key] = best
    return best
end

-- nil when the target has no geometry right now. A boss folder stays tracked
-- while its rig is despawned - the farm can arm one in advance, but there is
-- nowhere to arrive, so it is not listed here.
-- Live geometry if there is any, else the last place we saw it. The second
-- return says which, because teleporting to a remembered spot is a guess and
-- the menu should say so.
local function tpPoint(key, d)
    d = d or tracked[key]
    if d and d.point then return d.point end
    -- A Player is the stable handle; its Character is swapped out on every
    -- respawn, so remembering against the player is what makes the memory last.
    local target = key
    if typeof(key) == 'Instance' and key:IsA('Player') then target = key.Character end
    local p = target and tpPart(target)
    if p then
        local pos = p.Position
        tpLastPos[key] = pos
        return pos
    end
    local last = tpLastPos[key]
    if last then return last, true end
end

-- Accepts a Vector3 destination (offset by TP.up) or an exact CFrame. The
-- CFrame form is what the controllers use: the map sweep and the raid both
-- compute an exact spot to sit at, height offset included, rather than a point
-- to be offset again.
local function tpGo(dest)
    local cf
    if typeof(dest) == 'Vector3' then
        cf = CFrame.new(dest + vec3(0, TP.up, 0))
    elseif typeof(dest) == 'CFrame' then
        cf = dest
    else
        return false
    end
    local hrp = tpHrp()
    if not hrp then return false end
    -- Whoever teleports us now owns where we are. A park left standing would
    -- drag the body back once the hold expires - it cut the raid's stops
    -- short, and it would undo any jump from the menu. A caller that wants to
    -- be parked at the destination sets FARM.park AFTER this call.
    FARM.park = nil
    TP.token += 1
    local token = TP.token
    tpHoldUntil = clock() + TP.hold
    hrp.CFrame                 = cf
    hrp.AssemblyLinearVelocity = ZERO
    if TP.hold > 0 then
        task.spawn(function()
            local deadline = clock() + TP.hold
            while alive and TP.token == token and hrp.Parent and clock() < deadline do
                hrp.CFrame                 = cf
                hrp.AssemblyLinearVelocity = ZERO
                task.wait()
            end
        end)
    end
    return true
end

-- The name a row shows. `raw` is the display name the ESP settled on - a
-- prompt's ObjectText beats the instance name (MuzanLairModel -> Muzan) -
-- before RichText escaping, which a menu row does not want.
local function tpName(key, d)
    d = d or tracked[key]
    return (d and d.raw) or (typeof(key) == 'Instance' and key.Name) or tostring(key)
end

-- A player's key is the Player object rather than its Character, so it is not
-- in `tracked` and the category cannot be read from there.
local function tpCat(key)
    if typeof(key) == 'Instance' and key:IsA('Player') then return 'Player' end
    local d = tracked[key]
    return d and d.cat
end

-- Every candidate in a category, as (key, name, position-or-nil).
-- Players come from the SERVICE, not from `tracked`: GetPlayers lists everyone
-- in the server whether or not the ESP ever saw their character, which is the
-- only way the list is right for someone who joined and stayed out of range.
-- It carries no position though - a streamed-out character is a Model with all
-- its scripts and zero BaseParts, and Model.WorldPivot on a rig reads stale -
-- so the point is still resolved per target and may be a remembered one.
local function tpEach(cat, fn)
    if cat == 'Player' then
        for _, pl in Plrs:GetPlayers() do
            if pl ~= Me then fn(pl, pl.Name, (tpPoint(pl))) end
        end
        return
    end
    for c, d in tracked do
        if d.cat == cat then fn(c, tpName(c, d), (tpPoint(c, d))) end
    end
end

local function tpRefresh()
    if not tpDd then return end
    local hrp     = tpHrp()
    local origin  = hrp and hrp.Position
    local rows, n = {}, 0
    -- A player is always somewhere even when the client cannot see where, so
    -- they stay listed and the jump reports the truth. A boss folder with no
    -- rig is a different thing: it does not exist yet.
    local keepAll = TP.cat == 'Player'
    tpEach(TP.cat, function(key, name, pos)
        if not (pos or keepAll) then return end
        n += 1
        rows[n] = { key = key, name = name,
                    dist = (origin and pos) and (pos - origin).Magnitude or nil }
    end)

    sort(rows, function(a, b)
        if (a.dist == nil) ~= (b.dist == nil) then return b.dist == nil end
        if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
        return a.name < b.name
    end)

    -- Bare names, like the farm's list and for the same reason: the distance
    -- decides the ORDER but stays out of the label, so the list only churns when
    -- the set of targets changes rather than every time we move. Names repeat
    -- freely, so a bare name is not an address and duplicates take a suffix.
    clear(TP.labels)
    local labels, used = {}, {}
    for i = 1, min(n, TP.cap) do
        local base     = rows[i].name
        local label, k = base, 1
        while used[label] do
            k += 1
            label = fmt('%s #%d', base, k)
        end
        used[label]     = true
        labels[i]       = label
        TP.labels[label] = rows[i].key
    end

    local sig = concat(labels, '\0')
    if sig ~= TP.sig then
        TP.sig = sig
        tpDd:modify({ elements = labels })
    end
end

-- Typed lookup across EVERY category, not just the one on display: exact >
-- prefix > substring, nearest breaking ties. It reaches targets past the list
-- cap and past whichever category the dropdown happens to be showing.
local function tpFind(q)
    if type(q) ~= 'string' then return end
    q = q:lower():match('^%s*(.-)%s*$')
    if q == '' then return end
    local hrp    = tpHrp()
    local origin = hrp and hrp.Position
    local best, bestScore, bestDist
    local function offer(key, raw, pos, keep)
        local name = raw:lower()
        local score
        if name == q then score = 3
        elseif name:sub(1, #q) == q then score = 2
        elseif name:find(q, 1, true) then score = 1 end
        -- somewhere we can arrive, or a player, who is always somewhere
        if not score or not (pos or keep) then return end
        local dist = (origin and pos) and (pos - origin).Magnitude or math.huge
        if not best or score > bestScore
            or (score == bestScore and dist < bestDist) then
            best, bestScore, bestDist = key, score, dist
        end
    end
    for cat in CFG do
        tpEach(cat, function(key, name, pos)
            offer(key, name, pos, cat == 'Player')
        end)
    end
    return best
end

-- Its own loop rather than a second pass inside the farm's: a broken list must
-- never be able to stop the farm engaging, and vice versa.
task.spawn(function()
    while alive do
        guard(tpRefresh)
        task.wait(TP.scan)
    end
end)

-- ── loot ────────────────────────────────────────────────────────────────────
-- Verified in Ouwland: a chest is `Workspace.Chests.<name>` carrying a
-- ProximityPrompt (`Open`, T, hold 0), and firing it **destroys that prompt**
-- and spawns `Workspace.LootDrops.LootDrop`, a Part with a prompt of its own
-- (`Claim`, hold 0). So the existence of an enabled prompt IS the "claimable"
-- test - there is no claimed-set to keep and no double-fire to guard against,
-- and a chest already open when the script loads simply has nothing to find.
-- Hold prompts do exist here (`Snow Mound` digs at 0.5, the shrine at 1.0), and
-- this executor's `fireproximityprompt` takes no duration, so a hold is handled
-- by firing again until the prompt goes away rather than by passing a number.
local LOOT = {
    on      = false,  -- ships false: a Seoul toggle cannot be seeded
    folders = { 'LootDrops', 'Chests' },
    range   = 500,    -- studs from us OR from where the target died
    anchor  = 90,     -- seconds the death anchor stays valid
    -- Discretion. The claim happens from UNDER the chest, as deep as the
    -- prompt's own reach allows, so another player sees nothing - we are
    -- inside the floor, not standing on the loot. Verified live in Ouwland:
    -- every chest and drop prompt is `MaxActivationDistance = 12` with
    -- **`RequiresLineOfSight = false`**, so the ground between us and it costs
    -- nothing. The depth is read from the prompt rather than fixed, because a
    -- prompt with a shorter reach would otherwise silently go out of range.
    down    = 4,      -- floor: never shallower than this
    deep    = 12,     -- cap: never deeper than this however long the reach is
    margin  = 3,      -- studs of slack kept under MaxActivationDistance
    -- Being underground is only discreet if we STAY there. A body left in the
    -- ground is ejected by the solver - measured at 6.45 studs in 0.25s - so a
    -- claim pins its spot every frame and switches collisions off while it
    -- holds, the same two mechanisms flight uses.
    -- Studs below the GROUND at a tour stop, not below the beacon: a region
    -- point can sit anywhere relative to the terrain, so the depth is measured
    -- from a downward raycast and only falls back to the point itself when the
    -- area has not streamed in yet and there is nothing to hit.
    hide    = 40,
    probeUp = 200,    -- start the cast this far above the point
    probeDn = 2000,   -- and look this far down for ground
    -- Depth used when the cast finds NOTHING, which is the normal case for the
    -- first pass at a stop: we cast from outside the area, before it has
    -- streamed. Measured live over a 90s sweep, 8% of the waiting frames had
    -- open sky above them - all of them in that window - so the blind guess is
    -- deliberately far deeper than `hide`. Deep under a region beacon is out of
    -- sight either way; 40 studs over it is not.
    blind   = 250,
    -- The trigger is checked against our REPLICATED position, so firing on the
    -- frame we arrive is rejected for being outside MaxActivationDistance.
    -- These were cut right down once (0.1 / 0.08 / 8 tries / 0.2s sweep) and
    -- put back: fast did not claim more, it just fired more shots that missed.
    -- So they are unchanged. What WAS wasted is the wait AFTER a fire that
    -- already worked: the old code slept a flat `gap + HoldDuration` before
    -- even looking, which on the common case - claimed on the first shot - is
    -- most of the time spent on each drop, and it multiplies by the number of
    -- drops in a sweep. Waiting on the RESULT instead of on the clock costs
    -- nothing in extra shots and keeps the same upper bound.
    settle  = 0.25,   -- after arriving, before the first fire
    gap     = 0.2,    -- between tries
    poll    = 1 / 60, -- how often to look for the prompt to go away
    tries   = 4,      -- a hold prompt does not always take on the first fire
    scan    = 0.5,    -- seconds between sweeps
    fast    = 0.1,    -- ...while a kill's loot hold is up
    mobGrace = 0.3,   -- a mob kill's hold grace; bosses keep `grace`
    -- Map sweep. `range` above answers "is this OUR loot"; with the sweep on
    -- the question is instead "is this loot at all", so the range test is
    -- dropped entirely and the tour below is what bounds the work. This game
    -- has StreamingEnabled, so a chest on the far side of the map does not
    -- exist on the client at all - the only way to reach one is to go there,
    -- which is why this is a tour and not a bigger number.
    map     = false,  -- ships false: a Seoul toggle cannot be seeded
    -- How long a stop lasts. `dwell` is only the CAP: the stop ends as soon as
    -- the ground is under us and `ready` has passed, which is almost always.
    -- Measured live across all ten Ouwland regions, teleporting in cold:
    -- terrain answered a downward cast in **0.1-0.5s**, and the part count
    -- within 250 studs stopped changing by **0.6-1.4s**. A flat 5s was paying
    -- about 4s a stop for nothing. Nothing is lost by leaving early either -
    -- the tour laps, so a chest that streams in late is claimed next time
    -- round.
    ready   = 1.5,    -- minimum stop, once the ground is there
    dwell   = 2.5,    -- cap, for an area that never answers
}
-- The CFrame the loot run is holding the body at, or nil when it does not own
-- the body. Read by the Heartbeat pin below, by noclip, and by the farm and
-- movement, which both stand down while it is set.
LOOT.spot = nil

-- Whether anything wants loot claimed: `Claim loot`, the map sweep, the raid
-- (the chest its camp guards), or the auto quest - which DRIVES the loot run
-- the way the raid does, never writing LOOT.on, so the pill stays the user's.
-- A kill's drops are claimed before the next engagement, one kill at a time.
-- With only Auto quest on it used to claim nothing: measured live, 0 claims
-- across two kills with `Claim loot` off.
-- Wave farm is deliberately NOT here (requested: "make it so wave farm
-- doesn't auto claim loot") - only the camp raid drives it; `Claim loot`
-- still works alongside wave farm when switched on by hand.
function LOOT.wanted()
    return LOOT.on or LOOT.map or RAID.on or (FARM.quest ~= nil and FARM.quest.on) or false
end

-- The loot hold. A kill arms it, and while it is up NOTHING moves the body
-- anywhere but to a prompt: not home, not to the next target, not to the next
-- raid area or sweep stop. It ends when nothing claimable is left in range and
-- the last claim (or the kill) is `grace` old - a chest spawns after the kill
-- and its drop spawns after the chest opens, so "nothing right now" is not yet
-- "nothing". Reported: "it needs to claim ALL loot before teleporting ANYWHERE".
LOOT.grace   = 1.5  -- seconds after the kill / the last claim
LOOT.holdMax = 15   -- cap on a hold; every successful claim restarts it
LOOT.giveUp  = 2    -- failed runs before a prompt stops holding us here
LOOT.hold    = nil  -- { last, cap, seen, spot, home } while armed
-- Prompts that would not take, so one stubborn prompt cannot turn every kill
-- into a `holdMax` stall. Weak keys: a destroyed prompt drops out by itself.
LOOT.failed  = setmetatable({}, { __mode = 'k' })
-- Sweep state, on the LOOT table rather than as locals of its own: the top
-- level of this file is one Luau function and it is at the 200-local ceiling.
LOOT.sweep = { idx = 0, wait = 0, why = 'off', area = nil, claimed = 0, stops = 0,
               hide = nil, home = nil, at = nil, since = 0 }

-- Where the prompt is measured FROM, which is not always where its part is: a
-- chest hangs its prompt off a `ChestPromptAnchor` Attachment sitting ~3 studs
-- above the RootPart, and 3 studs is most of the slack a 12-stud reach leaves
-- once we are under it.
function LOOT.at(pr)
    local p = pr.Parent
    if p and p:IsA('Attachment') then return p.WorldPosition end
    return p and p:IsA('BasePart') and p.Position or nil
end

-- How far under it we can stand and still be heard.
function LOOT.depth(pr)
    local reach = tonumber(pr.MaxActivationDistance) or 10
    return max(LOOT.down, min(LOOT.deep, reach - LOOT.margin))
end

-- Where to sit at a tour stop so that nobody sees us waiting: under the
-- ground, not under the beacon. The cast starts above the point because a
-- point can be below an overhang, and ignores our own body or it would hit our
-- own parts and park us in mid-air.
-- Returns the CFrame to sit at, and whether it actually found ground - which
-- is also the cheapest "has this area streamed in yet" test available, since
-- the cast has to be made anyway.
function LOOT.buried(point)
    local y, drop = point.Y, LOOT.blind
    local ok, hit = pcall(function()
        local par = RaycastParams.new()
        par.FilterType = Enum.RaycastFilterType.Exclude
        par.FilterDescendantsInstances = { Me.Character }
        par.IgnoreWater = false
        return workspace:Raycast(point + vec3(0, LOOT.probeUp, 0),
            vec3(0, -(LOOT.probeUp + LOOT.probeDn), 0), par)
    end)
    -- No hit means the area has not streamed in yet. Going under the point is
    -- the best guess available, and the next stop re-measures anyway.
    if ok and hit then y, drop = hit.Position.Y, LOOT.hide end
    return CFrame.new(vec3(point.X, y - drop, point.Z)), ok and hit ~= nil
end

-- Where to hold the body BETWEEN jobs while the farm is driving: the last
-- underground spot something left it at - under the corpse, under the NPC, or
-- buried at a spawn we travelled to. Without it the gaps between kills, claims
-- and quest talks each dropped the pin, the ground ejected the body into view,
-- and the mobs got their hits in: measured live, the only damage in a minute
-- of farming landed exactly at those handovers. Nil whenever something else
-- owns the body (an engagement, a teleport hold) or nothing is driving.
function FARM.parked()
    local p = FARM.park
    if not p or farmEngaged or not FARM.driven() or clock() < tpHoldUntil then
        return nil
    end
    return p
end

-- Holds the body wherever the loot run put it, every frame, with collisions
-- off - otherwise the ground ejects us within a frame or two of arriving and
-- the whole point of being under it is lost. Costs two writes a frame while a
-- claim is live and nothing at all otherwise.
function LOOT.pin()
    -- An engaged farm owns the body. This pin runs AFTER farmStep in the same
    -- frame, so a LOOT.spot left set - a hold that never released, a spot a
    -- quest talk restored - overwrote the farm's write every frame: the farm
    -- reported engaged while the body sat underground wherever that spot was,
    -- for every target. Reported by a second user as "it never goes to the
    -- target". A claim is the only thing that may take the body
    -- mid-engagement, and it says so.
    if farmEngaged and not FARM_STATE.looting then return end
    local cf = LOOT.spot or FARM.parked()
    if not cf then return end
    local hrp = tpHrp()
    if not hrp then return end
    -- A park is only "stay where the last job left you". When something ELSE
    -- moves us a long way - the dungeon switching maps between floors, a
    -- respawn - that is the game putting us somewhere on purpose; our own
    -- teleports clear the park before they move. Seen live: a new floor on a
    -- new map teleported us there, this pin dragged us back every frame to the
    -- old map's spot, where nothing streams in, and wave farm waited forever
    -- on an empty baseplate. The ground's own push-out is ~6 studs, so a jump
    -- past `parkJump` is not that. Only once this park has been HELD a frame:
    -- a fresh park can legitimately be far from the body (a kill in the air
    -- parks us buried under it, often more than `parkJump` down).
    if not LOOT.spot then
        if FARM.parkHeld == cf and (hrp.Position - cf.Position).Magnitude > FARM.parkJump then
            FARM.park, FARM.parkHeld = nil, nil
            return
        end
        FARM.parkHeld = cf
    end
    hrp.CFrame                 = cf
    hrp.AssemblyLinearVelocity = ZERO
end

-- the prompt hangs off a part; that part is where we have to stand
local function lootPart(x)
    if not x:IsA('ProximityPrompt') or not x.Enabled then return end
    local p = x.Parent
    while p and not p:IsA('BasePart') do p = p.Parent end
    return p
end

local function lootScan()
    local hrp = tpHrp()
    if not hrp then return end
    local origin = hrp.Position
    -- A kill teleports us home before the chest is even there, so "near us" is
    -- the wrong question. Near us OR near where the target died.
    local anchor = (lootAnchor and clock() - lootAnchorAt <= LOOT.anchor)
        and lootAnchor or nil
    local function near(pos)
        -- The map sweep takes whatever it can see. Streaming is the only limit
        -- worth having then, and it is not one we can widen from here.
        if LOOT.map then return true end
        return (pos - origin).Magnitude <= LOOT.range
            or (anchor ~= nil and (pos - anchor).Magnitude <= LOOT.range)
    end

    local jobs, added = {}, {}
    local function offer(x)
        local part = lootPart(x)
        local at   = part and LOOT.at(x)
        if part and at and not added[x] and near(at) then
            added[x] = true
            jobs[#jobs + 1] = { prompt = x, part = part, at = at,
                               dist = (at - origin).Magnitude }
        end
    end

    -- Anything the listener flagged by action text, wherever it is parented.
    for x in lootSeen do
        if x.Parent then offer(x) else lootSeen[x] = nil end
    end
    -- Plus everything in the loot folders whatever its action text says, which
    -- is how a Dig site or a differently worded chest still gets taken.
    for _, name in LOOT.folders do
        local f = workspace:FindFirstChild(name)
        -- the common case is two empty folders, so cost nothing then
        if f and #f:GetChildren() > 0 then
            for _, x in f:GetDescendants() do offer(x) end
        end
    end
    -- Nearest first. Each claim is a teleport, so the order is the route - and
    -- with the map sweep on there can be a dozen of them at one stop.
    sort(jobs, function(a, b) return a.dist < b.dist end)
    return jobs
end

-- Success is the prompt going away, so WATCH for that rather than sleeping a
-- fixed time and looking afterwards. Same deadline as before - a hold prompt
-- still gets its full `gap + HoldDuration` to take - but a claim that lands on
-- the first shot stops costing the whole window. It never fires sooner, so it
-- cannot reintroduce the missed-shot problem that made cutting these numbers
-- fail last time.
local function lootTaken(pr, deadline)
    while true do
        if not (pr.Parent and pr.Enabled) then return true end
        if clock() >= deadline then return false end
        task.wait(LOOT.poll)
    end
end

-- Stand on it, fire, and keep firing until it is gone or we run out of tries.
local function lootClaim(job)
    local hrp = tpHrp()
    if not hrp then return false end
    for i = 1, LOOT.tries do
        local pr = job.prompt
        if not (pr.Parent and pr.Enabled and job.part.Parent) then return i > 1 end
        -- Under it, by as much as this prompt's reach allows. LOOT.spot is
        -- what actually keeps us there: the pin re-writes it every frame while
        -- this yields, so the ground cannot push us back into view.
        LOOT.spot = CFrame.new(LOOT.at(pr) - vec3(0, LOOT.depth(pr), 0))
        LOOT.pin()
        task.wait(i == 1 and LOOT.settle or LOOT.gap)
        pcall(fireproximityprompt, pr)
        if lootTaken(pr, clock() + LOOT.gap + (tonumber(pr.HoldDuration) or 0)) then
            return true
        end
    end
    return not job.prompt.Parent
end

-- Runs only while the farm is NOT engaged, which is exactly the window after a
-- kill: farmTick disengages the moment the target is down, and the chest and
-- its drop land in the seconds after that.
local function lootPass()
    -- FARM_STATE.looting does double duty: it stops the farm's Heartbeat
    -- writing our CFrame out from under a claim, and it is the re-entry guard.
    -- Three switches want this pass: `Claim loot`, the raid (which needs the
    -- chest its camp was guarding), and the map sweep - which is this same
    -- claimer with the range test dropped, so it must be able to run on its
    -- own rather than needing `Claim loot` on beside it.
    if not LOOT.wanted() then return end
    if FARM_STATE.looting or farmEngaged then return end
    -- taking a quest owns the body: a claim now would drag us off the NPC
    if FARM.quest and FARM.quest.busy then return end
    -- What this pass claimed is what tells the tour whether to move on, so it
    -- is reset here rather than in the tour: a pass that finds nothing has to
    -- read as zero, not as whatever the last stop managed.
    LOOT.sweep.claimed = 0
    local jobs = lootScan()
    if not jobs or #jobs == 0 then return end
    local hrp = tpHrp()
    if not hrp then return end

    local home = hrp.CFrame
    FARM_STATE.looting = true
    for _, job in jobs do
        if not (LOOT.wanted() and alive) then break end
        local ok, got = guard(lootClaim, job)
        if ok and got then
            FARM_STATE.looted += 1
            LOOT.sweep.claimed += 1
        elseif job.prompt.Parent then
            LOOT.failed[job.prompt] = (LOOT.failed[job.prompt] or 0) + 1
        end
    end
    -- Back to where the farm left us, or its own pin fights us for a frame.
    -- While the map sweep owns the body that place is the hide spot under the
    -- current stop, not the surface: surfacing between chests is exactly the
    -- moment another player would see us.
    -- During a loot hold that place is where the kill left us, held there, so
    -- the next pass starts from the same spot rather than from home.
    LOOT.spot = LOOT.sweep.hide or (LOOT.hold and LOOT.hold.spot)
    if hrp.Parent then
        hrp.CFrame                 = LOOT.spot or home
        hrp.AssemblyLinearVelocity = ZERO
    end
    FARM_STATE.looting = false
end

-- Loot that is ON ITS WAY: a drop in LootDrops whose prompt is still
-- disabled. Logged live at a raid camp: the cache opened and five LootDrops
-- spawned with `LootDropPrompt.Enabled = false`, enabling ~0.9s later.
-- lootScan skips a disabled prompt, so the hold read "nothing left" and let
-- go, the raid engaged the NEXT camp 450 studs off inside its radius, and the
-- loot run - which never interrupts a fight - left the drops lying until the
-- tour passed again. Reported: "it's opening chest for raid but skipping past
-- all the loot" and "if i turn off raid, it claims the loot". Only LootDrops:
-- a disabled prompt in Chests is a sealed cache, another camp's. Each counts
-- for `dropWait` from first sight, so one that never enables cannot hold us.
LOOT.dropWait = 5
LOOT.dropSeen = setmetatable({}, { __mode = 'k' })
function LOOT.dropsComing(at, within)
    local f   = workspace:FindFirstChild('LootDrops')
    local hrp = tpHrp()
    at = at or (hrp and hrp.Position)
    if not (f and at) then return false end
    local now = clock()
    for _, x in f:GetDescendants() do
        if x:IsA('ProximityPrompt') and not x.Enabled then
            local first = LOOT.dropSeen[x]
            if not first then first = now LOOT.dropSeen[x] = now end
            local part = x.Parent
            while part and not part:IsA('BasePart') do part = part.Parent end
            if now - first < LOOT.dropWait and part
                and (part.Position - at).Magnitude <= (within or LOOT.range) then
                return true
            end
        end
    end
    return false
end

-- Armed from farmDisengage when the target died. Returns true when it took
-- over, which tells the farm NOT to go home: that trip happens on release.
function FARM.lootArm(goHome)
    if not LOOT.wanted() then return false end
    local now = clock()
    local cf  = farmHrp and farmHrp.Parent and farmHrp.CFrame
    -- A mob's drop lands ~0.15s after it dies (measured on Mizunoto), so the
    -- full grace - there for a boss chest, whose spawn delay is unmeasured -
    -- was 1.5s of nothing after every mob kill.
    local d   = farmKey and tracked[farmKey]
    local grace = (d and d.cat == 'Mob') and LOOT.mobGrace or LOOT.grace
    LOOT.hold = { last = now, cap = now + LOOT.holdMax, seen = FARM_STATE.looted,
                  spot = cf or nil, home = goHome, grace = grace }
    -- pinned where the kill left us - under the corpse, out of sight - rather
    -- than left for the ground to eject
    if cf and not LOOT.spot then LOOT.spot = cf end
    return true
end

-- True while the hold is up. Releasing is done here, by whichever caller
-- notices first, so every gate agrees on the same answer.
function FARM.lootHeld()
    local h = LOOT.hold
    if not h then return false end
    local now = clock()
    if FARM_STATE.looted ~= h.seen then
        h.seen, h.last, h.cap = FARM_STATE.looted, now, max(h.cap, now + LOOT.holdMax)
    end
    if alive and LOOT.wanted() and now < h.cap then
        if FARM_STATE.looting or now - h.last < (h.grace or LOOT.grace) then return true end
        -- only drops near OUR kill: in a shared dungeon another player's drops
        -- can sit disabled for us, and each would hold the farm for dropWait
        if LOOT.dropsComing(lootAnchor, RAID.cacheNear) then return true end
        for _, job in lootScan() or {} do
            if (LOOT.failed[job.prompt] or 0) < LOOT.giveUp then return true end
        end
    end
    LOOT.hold = nil
    if LOOT.spot == h.spot then LOOT.spot = nil end
    -- the trip home the kill deferred
    local hrp = tpHrp()
    if h.home and farmHome and hrp then
        FARM.park = nil
        hrp.CFrame                 = farmHome
        hrp.AssemblyLinearVelocity = ZERO
    end
    -- the next engagement now, not on the farm's next 1.5s scan
    if FARM.driven() then task.defer(guard, farmTick) end
    return false
end

task.spawn(function()
    while alive do
        guard(lootPass)
        -- release promptly rather than on the farm's 1.5s scan
        if LOOT.hold then guard(FARM.lootHeld) end
        -- LOOT.tour is defined down in the raid section, because it tours the
        -- same area list; on this loop's very first tick the script has not
        -- reached it yet.
        if LOOT.tour then guard(LOOT.tour) end
        -- a kill's drop is due any moment while a hold is up: look often then
        task.wait(LOOT.hold and LOOT.fast or LOOT.scan)
    end
end)

-- ── raid ────────────────────────────────────────────────────────────────────
-- Verified in Ouwland: raid camps are three mobs guarding a sealed chest.
--
--   * The camp lives at `Workspace.Humanoids.Regions.Temporary.ActiveNpcs`, and
--     every folder there carries the attribute **`Temporary = true`**. That
--     attribute is the detector - not the names, which vary by camp (Grove
--     Raider, Raid Captain, Cache Lancer, Cache Prowler seen so far). 39 camp
--     slots exist and typically 3 are spawned: one camp at a time.
--   * The chest is `Workspace.Chests.<Sealed Cache T*>` about 20 studs away,
--     with `ChestState = 'Locked'`, `IsOpen = false`, and a `ChestPrompt` that
--     is **`Enabled = false`** while sealed. Killing all three unseals it;
--     there is no way to bypass that.
--
-- So this controller does not need to know anything about seals: the loot run
-- already skips a disabled prompt and takes it the moment it enables. All that
-- is left is find a camp, kill it, wait, move on.
RAID.idx   = 0     -- position in the area tour
RAID.waitUntil  = 0     -- clock() before which we do not travel again
RAID.fought = false

-- A living camp mob: tracked as a Mob, and its FOLDER says it is temporary.
-- Resolved here rather than from `d.anchor`, which the draw loop only maintains
-- for categories that are switched on - and everything ships off.
local function raidMobs(origin)
    local out = {}
    -- a wave can carry a boss, and the whole dungeon is "here"
    local reach = RAID.wave and math.huge or RAID.radius
    for c, d in tracked do
        -- A mob is keyed by its rig, whose FOLDER carries the attribute; a
        -- boss is keyed by the folder itself (from BossInfo), with the rig
        -- inside it only while spawned - farmResolve reaches it either way.
        if (d.cat == 'Mob' or (RAID.wave and d.cat == 'Boss'))
            and typeof(c) == 'Instance' and c.Parent
            and (c.Parent:GetAttribute('Temporary') == true
                or (d.cat == 'Boss' and c:GetAttribute('Temporary') == true)) then
            local _, root = farmResolve(c)
            if root and (root.Position - origin).Magnitude <= reach then
                out[#out + 1] = { key = c, dist = (root.Position - origin).Magnitude }
            end
        end
    end
    sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- The chests in Workspace.Chests within `cacheNear` of the camp, taken when
-- it dies. A cache is a Model holding a prompt (ChestPrompt, Enabled = false
-- while sealed); claiming it destroys the prompt.
function RAID.cachesNear(at)
    local out = {}
    local chests = workspace:FindFirstChild('Chests')
    if not (at and chests) then return out end
    for _, m in chests:GetChildren() do
        local pr = m:FindFirstChildWhichIsA('ProximityPrompt', true)
        local part = pr and pr.Parent
        while part and not part:IsA('BasePart') do part = part.Parent end
        if part and (part.Position - at).Magnitude <= RAID.cacheNear then
            out[#out + 1] = m
        end
    end
    return out
end

-- Anything of this camp's still unclaimed: a cache with its prompt (sealed or
-- not) and not open, or any claimable prompt - the drop a cache spawns - near
-- the camp. Failed prompts count too: the loot run keeps retrying them, and
-- leaving is exactly what the user asked not to happen.
function RAID.pending()
    if not RAID.caches then return false end
    for _, m in RAID.caches do
        if m.Parent and m:FindFirstChildWhichIsA('ProximityPrompt', true)
            and m:GetAttribute('IsOpen') ~= true then
            return true
        end
    end
    local at = RAID.campAt
    for _, job in (lootScan() or {}) do
        if at and (job.at - at).Magnitude <= RAID.cacheNear then return true end
    end
    return at ~= nil and LOOT.dropsComing(at, RAID.cacheNear)
end

-- Is anything alive in range at all? `raidMobs` answers "is there a CAMP here",
-- which is false for most regions most of the time; this answers "have this
-- region's NPCs replicated yet", which is what an arriving stop waits for.
-- Early-exits on the first hit, so it is cheaper than raidMobs in the common
-- case. On the RAID table rather than a local, for the 200-local ceiling.
function RAID.rigs(origin)
    for c, d in tracked do
        if (d.cat == 'Mob' or d.cat == 'Boss') and typeof(c) == 'Instance' and c.Parent then
            local root = c:FindFirstChild('HumanoidRootPart')
                or (c:IsA('Model') and c.PrimaryPart)
            if root and root.Parent and (root.Position - origin).Magnitude <= RAID.radius then
                return true
            end
        end
    end
    return false
end

-- The tour. Places come from the ESP's own Place entries, which the region
-- adapter fills, so a game that publishes no regions simply has nowhere to go
-- and the controller stays put and fights whatever is already in range.
local function raidAreas()
    local out = {}
    for c, d in tracked do
        if d.cat == 'Place' and d.point then
            out[#out + 1] = { name = d.raw or tostring(c), point = d.point }
        end
    end
    sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- ── map-wide loot sweep ─────────────────────────────────────────────────────
-- The raid tour without the fighting: walk the same area list, stop long enough
-- for each area to stream in, and let the loot pass above take whatever it can
-- see there. It lives here rather than in the loot section because it needs
-- `raidAreas`, and it is driven from the loot loop.
--
-- Travel is gated on what the LAST PASS CLAIMED, not on whether anything is
-- visible. "Stay while something is claimable" sounds right and hangs the tour
-- forever on the first prompt that will not take - a sealed cache we cannot
-- unseal, a prompt whose part never arrives - because that prompt is still
-- there on every pass. A pass that claims nothing means this stop is done.
--
-- It writes no toggle. The farm's and the raid's pills are theirs, and a Seoul
-- pill cannot be resynced, so a controller that flipped one would leave it
-- lying for the session - the same rule the raid already follows.
function LOOT.tour()
    local s = LOOT.sweep
    -- Standing down means giving the body back: the pin and the hide spot are
    -- ours only while we are actually driving.
    local function stop(why)
        s.why = why
        if s.hide then
            s.hide, s.at, LOOT.spot = nil, nil, nil
            if s.home then
                tpGo(s.home)
                s.home = nil
            end
        end
    end
    if not (LOOT.map and alive) then
        if s.why ~= 'off' then s.area = nil end
        stop('off')
        return
    end
    -- Two other things drive the body around the map. Neither is ours to
    -- fight: the raid is already touring, and the farm pins us every frame.
    if RAID.active() then
        stop('the raid is driving')
        return
    end
    if FARM.driven() and (farmEngaged or farmWant) then
        stop('the farm owns the body')
        return
    end
    if FARM_STATE.looting then
        s.why = 'claiming'
        return
    end
    -- taking a quest borrows LOOT.spot for its own pin
    if FARM.quest and FARM.quest.busy then
        s.why = 'taking a quest'
        return
    end
    if not tpHrp() then
        s.why = 'no character'
        return
    end
    if clock() < s.wait then
        s.why = 'waiting for the area to stream'
        -- The area streams in AFTER we arrive, so the cast made at travel time
        -- usually finds no ground and falls back to the beacon. Re-measure
        -- while we wait: the moment the terrain exists we sink under it. Half
        -- a stud of hysteresis, or a surface that flickers as it loads would
        -- re-teleport us every pass.
        if s.hide and s.at then
            local cf, ground = LOOT.buried(s.at)
            if abs(cf.Position.Y - s.hide.Position.Y) > 0.5 then
                s.hide, LOOT.spot = cf, cf
            end
            -- Ground under us means the area is here, so stop waiting on the
            -- clock and move on. `ready` is the floor, for the small things
            -- that arrive after the terrain does.
            if ground and clock() - s.since >= LOOT.ready then s.wait = 0 end
        end
        return
    end
    if FARM.lootHeld() then
        s.why = 'claiming'
        return
    end
    if s.claimed > 0 then
        -- Something landed here on the last pass, and a chest usually spawns
        -- its drop the moment it opens. Give the stop another pass.
        s.why = 'claiming'
        return
    end
    local areas = raidAreas()
    if #areas == 0 then
        s.why = 'nowhere to go'
        return
    end
    s.idx  = s.idx % #areas + 1
    local a = areas[s.idx]
    s.area, s.why = a.name, 'travelling'
    s.stops += 1
    -- Where the user was standing when the sweep took the body, so switching
    -- it off puts them back on the surface rather than leaving them buried.
    s.home = s.home or tpHrp().CFrame
    -- Arrive UNDERGROUND and stay there: streaming keys on where we are, not
    -- on how deep, so the area loads exactly the same out of sight.
    s.at      = a.point
    s.since   = clock()
    s.hide    = LOOT.buried(a.point)
    LOOT.spot = s.hide
    tpGo(s.hide)
    s.wait = clock() + LOOT.dwell
end

-- ── sharing a dungeon with other players ───────────────────────────────────
-- Requested: two players wave-farming the same dungeon should spread out, but
-- team up when there is nothing else - the last enemy, or one of several that
-- spawn one at a time (bosses and tanky mobs come last). The game does not
-- say who is fighting what, so "taken" is positional: another player's root
-- within `claimNear` of the mob. Another copy of this script sits `under`
-- (7) below its target; a player fighting by hand stands beside it. Kept
-- tight so a player on the next mob over does not claim this one.
RAID.claimNear = 10

-- The lowest UserId among other players on this mob, or nil when it is free.
function RAID.claimedBy(root)
    local low
    for _, pl in Plrs:GetPlayers() do
        if pl ~= Me then
            local ch = pl.Character
            local r  = ch and ch:FindFirstChild('HumanoidRootPart')
            if r and (r.Position - root.Position).Magnitude <= RAID.claimNear then
                local id = pl.UserId or 0
                if not low or id < low then low = id end
            end
        end
    end
    return low
end

-- `mobs` is nearest-first. A new target is the nearest FREE mob, else the
-- nearest (team up). The current one is kept - nearest-first would drop a
-- half-dead target for every fresh spawn that lands closer, and two scripts
-- that both switched on seeing each other would chase each other round the
-- room - except that when two players share a mob and a free one is waiting,
-- the one with the HIGHER UserId moves. Both copies apply the same rule, so
-- exactly one of them goes.
function RAID.waveTarget(mobs)
    local me = Me.UserId or 0
    local cur, free
    for _, m in mobs do
        local _, root = farmResolve(m.key)
        m.by = root and RAID.claimedBy(root) or nil
        if m.key == farmKey then cur = m end
        if m.by == nil and not free then free = m end
    end
    RAID_STATE.shared = cur ~= nil and cur.by ~= nil
    if cur then
        if cur.by ~= nil and free and me > cur.by then return free.key end
        return cur.key
    end
    return (free or mobs[1]).key
end

local function raidPass()
    if not RAID.active() then
        if RAID_STATE.phase ~= 'off' then
            RAID_STATE.phase, RAID_STATE.area = 'off', nil
            -- hand the body back; the farm's own toggle decides what happens
            -- next, and we never wrote it
            if farmKey and RAID.fought then farmWant, farmKey = nil, nil end
            RAID.fought = false
        end
        return
    end
    local hrp = tpHrp()
    if not hrp then return end

    -- Died mid-camp. Requested: "if i die, it should return to the raid i was
    -- doing". The respawn is far from the camp, so the camp was out of range
    -- on the next pass - which read as CLEARED, and the tour moved on to the
    -- next area. So: nothing is decided while we are dead, and a new body
    -- with a camp unfinished (still fighting, or its loot still pending) goes
    -- straight back to it, buried. Not in wave mode: the dungeon is all "here".
    local ch  = Me.Character
    local hum = ch and ch:FindFirstChildOfClass('Humanoid')
    if hum and hum.Health <= 0 then
        RAID_STATE.phase = 'dead'
        return
    end
    if RAID.char ~= ch then
        local was = RAID.char
        RAID.char = ch
        if was and not RAID.wave and RAID.campAt and (RAID.fought or RAID.caches) then
            RAID_STATE.phase = 'returning to the camp'
            tpGo((LOOT.buried(RAID.campAt)))
            return
        end
    end

    local mobs = raidMobs(hrp.Position)
    RAID_STATE.camp = #mobs
    if #mobs > 0 then
        -- Nearest first, one at a time. The farm is a single-target machine and
        -- pins us to whatever it is given; feeding it the closest of the three
        -- is what makes it work through a camp.
        RAID_STATE.phase = 'fight'
        RAID.fought = true
        local best = RAID.wave and RAID.waveTarget(mobs) or mobs[1].key
        -- where the camp is, for finding its cache once it is dead
        local _, bestRoot = farmResolve(best)
        if bestRoot then RAID.campAt = bestRoot.Position end
        if farmKey ~= best then
            -- the raid addresses a specific body, not a kind: three mobs in a
            -- camp share a name and it works through them one at a time, so
            -- the name goes in beside the body to keep farmTick's re-pick
            -- pointed at the same one
            farmKey  = best
            farmWant = best.Name
            if farmEngaged then farmDisengage(false) end
            guard(farmTick)
        end
        return
    end

    -- Nothing alive in range.
    if farmKey or farmWant then
        farmWant, farmKey = nil, nil
        if farmEngaged then farmDisengage(false) end
    end
    if RAID.fought then
        -- The camp just died. The seal breaks, the chest prompt enables and the
        -- loot run takes it - none of which is instant, so do not travel yet.
        RAID.fought = false
        RAID_STATE.cleared += 1
        RAID.waitUntil   = clock() + RAID.settle
        RAID.since = clock()
        RAID.loot  = FARM_STATE.looted
        RAID.seen  = FARM_STATE.looted
        RAID.caches, RAID.lootCapAt = RAID.cachesNear(RAID.campAt), clock() + RAID.lootCap
    end
    if RAID.wave then
        -- Nowhere to go: the next wave comes to us. The farm's park keeps the
        -- body buried at the last kill while we wait.
        RAID_STATE.phase = (FARM_STATE.looting or FARM.lootHeld()) and 'looting'
            or 'waiting for a wave'
        return
    end
    if FARM_STATE.looted ~= RAID.seen then
        RAID.seen, RAID.claimAt = FARM_STATE.looted, clock()
        -- a claim is proof the loot is still coming, so the cap restarts;
        -- it still ends, because it only moves on a claim that succeeded
        if RAID.loot >= 0 then RAID.waitUntil = max(RAID.waitUntil, clock() + RAID.settle) end
    end
    if clock() < RAID.waitUntil or FARM_STATE.looting then
        RAID_STATE.phase = 'looting'
        -- Two different waits end here, and each ends on its own evidence
        -- rather than on its cap.
        if not FARM_STATE.looting and clock() - RAID.since >= RAID.ready then
            if RAID.loot < 0 then
                -- Arriving. What we are waiting for is this region's NPCs
                -- replicating; one rig in range says they have. The camp check
                -- above has already run this tick, so if there were a camp we
                -- would be fighting it - move on.
                if RAID.rigs(hrp.Position) then RAID.waitUntil = 0 end
            elseif FARM_STATE.looted > RAID.loot
                and clock() - RAID.claimAt >= RAID.after then
                -- The chest the camp was guarding has been claimed, the last
                -- claim has had its grace, and nothing claimable is left in
                -- range - a drop between loot passes is not "done".
                local left = lootScan()
                if not (left and #left > 0) then RAID.waitUntil = 0 end
            end
        end
        return
    end

    if FARM.lootHeld() then
        RAID_STATE.phase = 'looting'
        return
    end
    -- The camp's own loot, on evidence, before any travel.
    if RAID.pending() then
        if clock() < (RAID.lootCapAt or 0) then
            RAID_STATE.phase = 'looting'
            return
        end
        RAID_STATE.phase = 'gave up on the camp\'s loot after ' .. RAID.lootCap .. 's'
    end
    RAID.caches = nil
    local areas = raidAreas()
    if #areas == 0 then
        RAID_STATE.phase = 'nowhere to go'
        return
    end
    RAID.idx = RAID.idx % #areas + 1
    local a = areas[RAID.idx]
    RAID_STATE.phase, RAID_STATE.area = 'travel', a.name
    tpGo(a.point)
    RAID.waitUntil   = clock() + RAID.dwell
    RAID.since = clock()
    -- Marks this wait as an ARRIVAL rather than a post-kill one. Without it the
    -- last camp's claim count is still sitting there, and every stop from then
    -- on ends the moment `after` has elapsed - a tour that will not stay
    -- anywhere long enough to see a camp.
    RAID.loot  = -1
end

task.spawn(function()
    while alive do
        guard(raidPass)
        task.wait(RAID.tick)
    end
end)

-- ── dungeon cards ───────────────────────────────────────────────────────────
-- The Minigames dungeon deals a hand after each floor. Verified live:
--
-- * A hand is PlayerGui.ComponentsHolder.MainNotificationFrame.OuwigaharaOffers
--   .BBCards.Cards.<slot>.Card.<slot>.Title/Bottom, 4-5 visible slots.
-- * Picking sends SignalEvent('OuwigaharaRequest', { action = 'Pick', id =
--   '<slot>' }), and the wave skip on the top bar ("Skip 0/1") sends
--   { action = 'Skip' }. Nothing else goes out; the buttons are only the UI.
-- * Two hands per floor. The first is rewards (Second Wind, stat cards,
--   trophies, Fortune); the second is floor events - "<Name>, x1.3 points" -
--   and always carries a `Skip` card ("No event this floor"), which is how
--   the two are told apart.
-- * Every event is described in Minigames.Ouwigahara.Events.Types, keyed by
--   an internal name, with `Title`, `Score.Multiplier` and `Floors` (1 = next
--   floor only, absent = the rest of the run). Streak ("+5% per clean floor,
--   up to +50%") has a FUNCTION multiplier, so it is valued at its cap.
--
-- Wanted (the user's order): Second Wind whenever we are under `lowFrac`
-- (30%) of max health. Then a multiplier that lasts the REST OF THE RUN
-- (Streak, Ascension, Marathon...) before anything, in either hand. Then
-- rewards - Fortune, then damage, then Second Wind; events - the biggest
-- one-floor multiplier, and the Skip card when nothing multiplies.
local CARDS = {
    on     = false,   -- ships false: a Seoul toggle cannot be seeded
    skip   = false,   -- press the wave skip between floors
    tick   = 0.25,
    wait   = 0.4,     -- a hand must have been up this long: slots fill in
    retry  = 2.5,     -- re-send if the same hand / skip is still up after this
    streak = 1.5,     -- what Streak is worth: its +50% cap
    lowFrac = 0.3,    -- under this share of max health, Second Wind beats
                      -- every other card. A share, not a number: max health
                      -- moves with the run (Glass Floor halves it, Thick
                      -- Blood adds half), and a flat 400 meant a different
                      -- risk every time it did.
    -- Never taken on our LAST heart, whatever put us there (Reincarnation
    -- stands us up on one, or we simply lost the rest): a floor that drains
    -- health every second is a death sentence with nothing to fall back on.
    -- Read off the player's `Hearts` attribute.
    lastHeart = { BleedingFloor = true },
    why    = 'off', last = nil, picks = 0, skips = 0,
    sig = nil, seenAt = 0, sentAt = 0, skipText = nil, skipAt = 0,
    -- Cards that cost more than they give, never taken even as a fallback.
    -- NotRanked cards are fine: asked for explicitly.
    avoid = { BloodPact = true, TollGate = true, Sacrifice = true, Tribute = true,
              Reshuffle = true, GlassCannon = true, Pacifist = true,
              Featherweight = true, FocusedMind = true, Handoff = true,
              Respec = true, TwinSouls = true, Wager = true, TimeAttack = true,
              LastRites = true },
}

-- Title -> { key, ty }, from the game's own table. Cached once it loads.
function CARDS.events()
    if CARDS.ev then return CARDS.ev end
    local x = RepS
    for _, name in { 'Minigames Place', 'Minigames', 'Ouwigahara', 'Events' } do
        x = x and x:FindFirstChild(name)
    end
    if not x then return {} end
    local ok, t = pcall(function() return require(x).Types end)
    if not (ok and type(t) == 'table') then return {} end
    local map = {}
    for key, ty in t do
        if type(ty) == 'table' and type(ty.Title) == 'string' then
            map[ty.Title] = { key = key, ty = ty }
        end
    end
    CARDS.ev = map
    return map
end

-- Visible all the way up to `stop`: a hidden slot keeps its last text.
function CARDS.shown(g, stop)
    while g and g ~= stop do
        if g:IsA('GuiObject') and not g.Visible then return false end
        if g:IsA('LayerCollector') and not g.Enabled then return false end
        g = g.Parent
    end
    return g == stop
end

function CARDS.root()
    local pg = Me:FindFirstChild('PlayerGui')
    local ch = pg and pg:FindFirstChild('ComponentsHolder')
    return ch and ch:FindFirstChild('MainNotificationFrame')
end

function CARDS.hand(root)
    local offers = root:FindFirstChild('OuwigaharaOffers')
    local bb     = offers and offers:FindFirstChild('BBCards')
    local slots  = bb and bb:FindFirstChild('Cards')
    local out    = {}
    if not (slots and CARDS.shown(slots, root)) then return out end
    for _, slot in slots:GetChildren() do
        local card  = slot:FindFirstChild('Card')
        local inner = card and card:FindFirstChild(slot.Name)
        local title = inner and inner:FindFirstChild('Title')
        if title and title.Text ~= '' and CARDS.shown(title, root) then
            local bottom = inner:FindFirstChild('Bottom')
            out[#out + 1] = { id = slot.Name, title = title.Text,
                              desc = bottom and bottom.Text or '' }
        end
    end
    sort(out, function(a, b) return a.id < b.id end)
    return out
end

-- The points multiplier on a card, or nil. From the module when it knows the
-- title, else from the title text ("..., x1.3 points").
function CARDS.mult(c)
    local e = CARDS.events()[c.title]
    local m = e and e.ty.Score and e.ty.Score.Multiplier
    if type(m) == 'function' then return CARDS.streak end
    if type(m) == 'number' then return m end
    if c.title:match('^Streak') then return CARDS.streak end
    local x = c.title:match('x([%d%.]+) points')
    return x and tonumber(x) or nil
end

-- Takes skills away for the REST OF THE RUN: the module's NoSkills flag on a
-- card with no one-floor limit, or the text saying so for a card it does not
-- know. Iron Discipline (one floor, no flag) passes; Pacifist does not.
function CARDS.noSkillsForRun(c, e)
    if e then return e.ty.NoSkills == true and e.ty.Floors ~= 1 end
    local d = c.desc:lower()
    return d:find('no longer use skills', 1, true) ~= nil
        and d:find('rest of the run', 1, true) ~= nil
end

-- Lasting = the module gives it no `Floors`; one read off a title alone is
-- assumed to be one floor, except Streak, which says so in its text.
function CARDS.lasting(c)
    local e = CARDS.events()[c.title]
    if e then return e.ty.Floors == nil end
    return c.title:match('^Streak') ~= nil
end

function CARDS.score(c, events)
    local t = c.title
    local e = CARDS.events()[t]
    if e and CARDS.avoid[e.key] then return -1 end
    -- The table can fail to load (it is a game module, required on whatever
    -- executor this is), and the avoid list must not depend on it: match the
    -- same keys against the title, CamelCase split - GlassCannon starts
    -- "Glass Cannon".
    if not e then
        for key in CARDS.avoid do
            local words = key:gsub('(%l)(%u)', '%1 %2')
            if t:sub(1, #words) == words then return -1 end
        end
    end
    -- Never lose skills for the whole run; one floor without them is fine.
    if CARDS.noSkillsForRun(c, e) then return -1 end
    local hearts = Me:GetAttribute('Hearts')
    if type(hearts) == 'number' and hearts <= 1 then
        for key in CARDS.lastHeart do
            local words = key:gsub('(%l)(%u)', '%1 %2')
            if (e and e.key == key) or t:sub(1, #words) == words then return -1 end
        end
    end
    -- Hurt, a full heal is worth more than anything a card can pay later.
    if t == 'Second Wind' then
        local hum = Me.Character and Me.Character:FindFirstChildOfClass('Humanoid')
        if hum and hum.MaxHealth > 0 and hum.Health < hum.MaxHealth * CARDS.lowFrac then
            return 20000
        end
    end
    local m = CARDS.mult(c)
    -- a whole-run multiplier outranks everything else, in either hand
    if m and m > 1 and CARDS.lasting(c) then return 10000 + m end
    if events then
        if t == 'Skip' then return 1 end
        if m then return m end
        return 0.5
    end
    local n = t:match('^Fortune %+(%d+)')
    if n then return 4000 + min(tonumber(n), 999999) / 1e6 end
    n = t:match('^Damage %+([%d%.]+)%%')
    if n then return 3000 + tonumber(n) end
    if e and e.key == 'HeavyHitter' then return 3020 end
    n = t:match('^Damage %+([%d%.]+)$')
    if n then return 2900 + min(tonumber(n), 99) end
    -- A one-floor points multiplier in this hand beats Second Wind (reported:
    -- it took Second Wind over Fair Fight at full health). Below Fortune and
    -- damage, which the user put first. Hurt, Second Wind still wins above.
    if m then return 2500 + m end
    -- Flat points. Five tiers, read off Rewards.Score.Points: Trophy,
    -- Fine, Greater, Grand, Supreme = 5/10/25/50/100 kills at 15 = 75, 150,
    -- 375, 750, 1500. Only GRAND and SUPREME rank above Second Wind
    -- (requested); the rest are a last resort. Fortune stays above all of
    -- them - it scales with the points already held. The most points first.
    n = t:match('%+(%d+)$')
    local pts = n and (c.desc:find('[Pp]oints') or t:find('Trophy', 1, true)) and tonumber(n)
    if pts and (t:find('^Grand Trophy') or t:find('^Supreme Trophy')) then
        return 2000 + 1 + min(pts, 99999) / 1e5
    end
    -- Max Health stat cards ("Max Health +162"): above Second Wind, under the
    -- Grand/Supreme points above (requested); the bigger one first.
    n = t:match('^Max Health %+([%d%.]+)')
    if n then return 2000.5 + min(tonumber(n), 999) / 1e4 end
    if t == 'Second Wind' then return 2000 end
    if pts then return 500 + min(pts, 99999) / 1e5 end
    return 100
end

function CARDS.best(hand)
    local events = false
    for _, c in hand do
        if c.title == 'Skip' then events = true end
    end
    local best, bestS
    for _, c in hand do
        local sc = CARDS.score(c, events)
        if sc >= 0 and (not bestS or sc > bestS) then best, bestS = c, sc end
    end
    return best, events
end

-- ── keep a weapon in hand, round by round ──────────────────────────────────
-- Requested: "every new round, it should try to equip anything that isn't the
-- fist, but is also a weapon" - and on a Bare Hands floor, fists. Read live:
-- a toolbar key press sends SignalEvent('Item_Equip', <slot>);
-- Players.<me>.Items_Config.Equipped is the equipped slot, 0 for none; and
-- pressing the equipped slot's key again UNEQUIPS (Item_Equip(0)), so a key is
-- only ever pressed for a slot that is not the equipped one. The game strips
-- the weapon itself on the frame a Bare Hands floor starts - to nothing, not
-- to fists - and never gives it back. Keys are pressed like a player would,
-- as asked, not through the game's own functions.
-- A round starts when the top bar's floor label changes. Per round: up to
-- `gearTries` presses, `gearGap` apart, so a floor where equipping is locked
-- costs a few taps and not a stream of them.
CARDS.keys      = { 'One', 'Two', 'Three', 'Four', 'Five' }
CARDS.gear      = { floor = nil, want = nil, tries = 0, at = 0, bare = false }
CARDS.gearTries = 5
CARDS.gearGap   = 1.5
CARDS.bareNext  = false   -- the next round is a Bare Hands floor
CARDS.lastWeapon = nil    -- the weapon slot we last saw equipped: preferred

function CARDS.equipped()
    local ic = Me:FindFirstChild('Items_Config')
    local e  = ic and ic:FindFirstChild('Equipped')
    return e and e.Value or nil
end

-- Slot number -> item name, from the save: Player_Service.Data.<me>.slots.
-- Slot<slotEquipped>.Inventory.Toolbar.<One..Five> holds item ids, resolved
-- through the same save's Inventory.Inventory.<item name>.Id.
function CARDS.toolbar()
    local x = RepS
    for _, name in { 'Player_Service', 'Data', Me.Name } do x = x and x:FindFirstChild(name) end
    local se    = x and x:FindFirstChild('slotEquipped')
    local slots = x and x:FindFirstChild('slots')
    local save  = se and slots and slots:FindFirstChild('Slot' .. tostring(se.Value))
    local inv   = save and save:FindFirstChild('Inventory')
    local bar   = inv and inv:FindFirstChild('Toolbar')
    local items = inv and inv:FindFirstChild('Inventory')
    local names = {}
    if not (bar and items) then return names end
    local byId = {}
    for _, it in items:GetChildren() do
        local id = it:FindFirstChild('Id')
        if id then byId[id.Value] = it.Name end
    end
    for i, key in CARDS.keys do
        local v = bar:FindFirstChild(key)
        if v and v.Value ~= 0 then names[i] = byId[v.Value] end
    end
    return names
end

function CARDS.isWeaponSlot(i, names)
    return i ~= nil and names[i] ~= nil and FARM.isWeapon ~= nil and FARM.isWeapon(names[i])
end

function CARDS.weaponSlot(names)
    if CARDS.isWeaponSlot(CARDS.lastWeapon, names) then return CARDS.lastWeapon end
    for i = 1, #CARDS.keys do
        if CARDS.isWeaponSlot(i, names) then return i end
    end
    return nil
end

function CARDS.fistsSlot(names)
    for i = 1, #CARDS.keys do
        if names[i] == 'Combat' then return i end
    end
    return nil
end

function CARDS.floorText(root)
    local bar = root:FindFirstChild('OuwigaharaTopBar')
    bar = bar and bar:FindFirstChild('Bar')
    local f = bar and bar:FindFirstChild('Floor')
    return f and f.Text or nil
end

-- One tap of a toolbar key, the way a player would. Never into a focused text
-- box: it would type the digit instead.
function CARDS.press(slot)
    if Input:GetFocusedTextBox() then return false end
    local ok, vim = pcall(game.GetService, game, 'VirtualInputManager')
    if not (ok and vim) then return false end
    local code = Enum.KeyCode[CARDS.keys[slot]]
    vim:SendKeyEvent(true, code, false, game)
    task.delay(0.1, function() vim:SendKeyEvent(false, code, false, game) end)
    return true
end

function CARDS.gearStep(root)
    local g     = CARDS.gear
    local names = CARDS.toolbar()
    local now   = CARDS.equipped()
    if CARDS.isWeaponSlot(now, names) then CARDS.lastWeapon = now end
    local f = CARDS.floorText(root)
    if f ~= g.floor then
        local first = g.floor == nil
        g.floor, g.tries, g.at = f, 0, 0
        if not first then
            g.bare = CARDS.bareNext
            CARDS.bareNext = false
            g.want = g.bare and 'fists' or 'weapon'
        end
    end
    local want = nil
    if g.want == 'fists' then
        want = CARDS.fistsSlot(names)
    elseif g.want == 'weapon' then
        -- already holding a weapon: nothing to do this round
        if CARDS.isWeaponSlot(now, names) then g.want = nil return end
        want = CARDS.weaponSlot(names)
    end
    if not want then return end
    if now == want then g.want = nil return end
    if g.tries >= CARDS.gearTries or clock() < g.at then return end
    g.at = clock() + CARDS.gearGap
    if CARDS.press(want) then g.tries += 1 end
end

-- The tower floor from the top bar's "Floor N", for the farm's stay-down
-- rule. Read at most once a second: the farm asks every frame.
function FARM.towerFloor()
    local now = clock()
    if FARM.floorAt and now - FARM.floorAt < 1 then return FARM.floorN end
    FARM.floorAt = now
    local root = CARDS.root()
    local t = root and CARDS.floorText(root)
    FARM.floorN = t and tonumber(t:match('(%d+)')) or nil
    return FARM.floorN
end

function CARDS.pass()
    if not (CARDS.on or CARDS.skip) then CARDS.why = 'off' return end
    local root = CARDS.root()
    if not root then CARDS.why = 'no dungeon ui' return end
    if CARDS.on then CARDS.gearStep(root) end
    local hand = CARDS.hand(root)
    if #hand > 0 then
        if not CARDS.on then CARDS.why = 'a hand is up; auto pick is off' return end
        local sig = {}
        for i, c in hand do sig[i] = c.id .. '=' .. c.title end
        sig = concat(sig, '|')
        if sig ~= CARDS.sig then CARDS.sig, CARDS.seenAt, CARDS.sentAt = sig, clock(), 0 end
        if clock() - CARDS.seenAt < CARDS.wait then CARDS.why = 'reading the hand' return end
        if CARDS.sentAt > 0 and clock() - CARDS.sentAt < CARDS.retry then
            CARDS.why = 'waiting for the pick to land'
            return
        end
        local best = CARDS.best(hand)
        if not best then CARDS.why = 'nothing worth taking' return end
        local remote = farmRemote()
        if not remote then CARDS.why = 'no remote' return end
        remote:FireServer('OuwigaharaRequest', { action = 'Pick', id = best.id })
        CARDS.sentAt, CARDS.last = clock(), best.title
        if best.title:match('^Bare Hands') then CARDS.bareNext = true end
        CARDS.picks += 1
        CARDS.why = 'picked ' .. best.title
        return
    end
    CARDS.sig = nil
    if not CARDS.skip then CARDS.why = 'waiting for a hand' return end
    local bar = root:FindFirstChild('OuwigaharaTopBar')
    local sk  = bar and bar:FindFirstChild('Skip')
    local btn = sk and sk:FindFirstChild('Button')
    if not (btn and CARDS.shown(btn, root)) then
        CARDS.skipText = nil
        CARDS.why = 'waiting'
        return
    end
    local lbl  = btn:FindFirstChild('TextLabel', true)
    local text = lbl and lbl.Text or ''
    -- Once per appearance. The vote count changing ("Skip 0/1" -> "1/1") is
    -- the proof it registered; only an unchanged label is re-sent, and only
    -- after `retry`, since a second press may well take the vote back.
    if CARDS.skipText ~= nil and (CARDS.skipText ~= text
        or clock() - CARDS.skipAt < CARDS.retry) then
        CARDS.why = 'skip sent'
        return
    end
    local remote = farmRemote()
    if not remote then CARDS.why = 'no remote' return end
    remote:FireServer('OuwigaharaRequest', { action = 'Skip' })
    CARDS.skipText, CARDS.skipAt = text, clock()
    CARDS.skips += 1
    CARDS.why = 'skipped the wait'
end

task.spawn(function()
    while alive do
        guard(CARDS.pass)
        task.wait(CARDS.tick)
    end
end)

-- ── auto quest ──────────────────────────────────────────────────────────────
-- Loops one quest: whenever it is not held, go to the NPC that offers it, take
-- it through the game's own dialogue, and come back. Verified live:
--
-- * A quest completes the moment its task is met - no turn-in - so the whole
--   loop is "take it again". The kills are the farm's job; this only keeps
--   the quest in hand, and holds the farm off while it is not, since a kill
--   without the quest counts for nothing.
-- * Taking one sends no remote of its own. The prompt opens the dialogue
--   client-side, and the option button's click handler does the rest, so we
--   fire the prompt and call that handler rather than forge a payload.
-- * One quest at a time (`MaxQuestsPerPlayer = 1`), and the 30s `QuestCD` runs
--   from the ACCEPT - a quest takes longer than that, so re-taking it the
--   moment it completes works.
-- * What we hold is `Data.<me>.slots.Slot<slotEquipped>.Quests.Holder`, one
--   child per quest carrying a `QuestString` = the quest's key.
--
-- Everything hangs off FARM: the top level has no local headroom.
FARM.quest = {
    on    = false,   -- ships false: a Seoul toggle cannot be seeded
    want  = nil,     -- quest key, e.g. 'Ill take 3 bandits'
    why   = 'off',
    busy  = false,
    retry = 0,       -- clock() before which a failed accept is not retried
    taken  = 0,
    handed = 0,      -- hand-ins made
    -- a task named like this is a trip back to someone, not a kill
    turnVerbs = { '^return', '^report', '^bring', '^deliver', '^speak', '^go talk', '^talk' },
    wait  = 3,       -- cap on the prompt streaming in, and on the confirm
    talk  = 6,       -- cap on the dialogue reaching our option
    click = 0.5,     -- seconds between clicks through an NPC's opening line
    back  = 5,       -- seconds between failed attempts
    -- After this many failures in a row it stops trying and stops holding the
    -- farm: a quest we cannot take must not park the farm for the session.
    giveUp = 3,
    fails  = 0,
    tick  = 1,
    target   = nil,  -- the NPC name the held quest resolved to
    near     = 150,  -- studs from a target's spawn that count as "there"
    settle   = 8,    -- seconds after travelling before travelling again
    travelAt = 0,
    dd     = nil,    -- the menu's quest dropdown, and the order it shows
    sig    = nil,
    relist = 3,      -- seconds between re-sorting it by distance
    band   = 250,    -- studs per distance band the sort compares
    listAt = 0,
}

function FARM.questDb()
    local x = RepS
    for _, name in { 'CAM', 'Global', 'Subsets', 'Gameplay', 'Quests' } do
        x = x and x:FindFirstChild(name)
    end
    if not x then return nil end
    local ok, m = pcall(require, x)
    return ok and type(m) == 'table' and type(m.Holder) == 'table' and m.Holder or nil
end

-- Our save slot's `Quests` folder: `Holder` (active) and `Completed`.
function FARM.questData()
    local data = RepS:FindFirstChild('Player_Service')
    data = data and data:FindFirstChild('Data')
    data = data and data:FindFirstChild(Me.Name)
    local n = data and data:FindFirstChild('slotEquipped')
    local slots = data and data:FindFirstChild('slots')
    local slot = n and slots and slots:FindFirstChild('Slot' .. tostring(n.Value))
    return slot and slot:FindFirstChild('Quests')
end

-- What the menu offers: quests an NPC hands out, minus the one-offs already
-- done - a one-off lands in `Completed` by name, a repeatable one never does.
function FARM.questList()
    local db, list = FARM.questDb(), {}
    if not db then return list end
    local q = FARM.questData()
    local done = q and q:FindFirstChild('Completed')
    -- Nearest giver first. The quest carries its giver's spot; NpcSpawns is the
    -- fallback, and a quest with neither sorts after, alphabetically.
    local spawns = FARM.questSpawns()
    local hrp    = tpHrp()
    local dist   = {}
    for key, info in db do
        if type(info) == 'table' and type(info.OfferNpc) == 'string'
            and not (done and done:FindFirstChild(key)) then
            list[#list + 1] = key
            local at = typeof(info.Position) == 'Vector3' and info.Position
                or spawns[info.OfferNpc]
            -- banded, so the order only moves when we change area rather
            -- than on every step the farm takes
            dist[key] = (hrp and typeof(at) == 'Vector3')
                and floor((at - hrp.Position).Magnitude / FARM.quest.band) or math.huge
        end
    end
    table.sort(list, function(a, b)
        if dist[a] ~= dist[b] then return dist[a] < dist[b] end
        return a < b
    end)
    return list
end

-- Repaint the menu's quest list when its ORDER changed. `modify({elements})`
-- destroys and reclones every row, so only on a real change - it is the order
-- that moves as we do, and it moves only when we pass one giver for another.
function FARM.questRelist()
    local Q = FARM.quest
    if not Q.dd then return end
    -- Never while the list is OPEN. A rebuild destroys every row and the list
    -- snaps back to the top, so the row under the cursor changes between
    -- looking and clicking - reported as "it's accepting the first quest
    -- instead of the one chosen". Seoul opens a dropdown by tweening its frame
    -- from 18 to 67 px tall; anything taller than closed counts as open.
    local frame = Q.dd._instance
    if frame and frame.Size.Y.Offset > 18 then return end
    local list = FARM.questList()
    local sig  = table.concat(list, '\n')
    if sig ~= Q.sig then
        Q.sig = sig
        Q.dd:modify({ elements = list })
    end
end

-- The key of the quest we hold and its instance, or nil. nil also when the
-- data is not there.
function FARM.questNow()
    local h = FARM.questData()
    h = h and h:FindFirstChild('Holder')
    if not h then return nil end
    for _, q in h:GetChildren() do
        local s = q:FindFirstChild('QuestString')
        if s then return s.Value, q end
    end
    return nil
end

-- Every NPC the game knows by name, with its spawn: `ReplicatedStorage.Regions`
-- carries `NpcSpawns` (111 names -> Vector3), map-wide, streaming or not. That
-- is both the candidate list for a kill code and where to go for a target
-- that has not streamed in.
function FARM.questSpawns()
    local mod = RepS:FindFirstChild('Regions')
    if not mod then return {} end
    local ok, m = pcall(require, mod)
    return ok and type(m) == 'table' and type(m.NpcSpawns) == 'table'
        and m.NpcSpawns or {}
end

-- A task's kill code to an NPC name. The code is a server-side id and is NOT
-- on the live rig anywhere - appearance is randomised and NpcConfig is one
-- shared module - so this matches by name, each word a prefix of its code
-- token or the other way round, in one of two shapes:
--   the name lines up with the code's LAST tokens: KaruVillageBandit -> Bandit,
--     HoyuzoSub -> Hoyuzo Subordinate, MotherBear -> Mother Bear (not Bear Cub)
--   the code is the start of a longer name: WaterTrainee -> Water Trainee Sabito
-- An exact word-for-word match outranks the second shape, or Hoyuzo would farm
-- Hoyuzo Subordinate. A `_Region` suffix is dropped.
function FARM.questMatch(code)
    local base = code:match('^(.-)_') or code
    local toks = {}
    for t in (base:gsub('(%l)(%u)', '%1 %2')):gmatch('%S+') do
        toks[#toks + 1] = t:lower()
    end
    local k = #toks
    local function like(w, t) return w:sub(1, #t) == t or t:sub(1, #w) == w end
    local best, bestScore = nil, 0
    local function try(name)
        if type(name) ~= 'string' then return end
        local words = {}
        for w in name:lower():gmatch('%w+') do words[#words + 1] = w end
        local n, score = #words, 0
        if n == 0 then return end
        if n <= k then
            score = n + (n == k and 5 or 0)
            for j = 1, n do
                if not like(words[j], toks[k - n + j]) then score = 0 break end
            end
        end
        if score == 0 and n > k then
            score = k
            for j = 1, k do
                if not like(words[j], toks[j]) then score = 0 break end
            end
        end
        if score > bestScore then best, bestScore = name, score end
    end
    for name in FARM.questSpawns() do try(name) end
    for c, d in tracked do
        if FARM_CATS[d.cat] and typeof(c) == 'Instance' then try(c.Name) end
    end
    return best
end

-- The held quest's CURRENT step: the first unfinished task whose `After`
-- prerequisites are all done. GetChildren order is arbitrary, and Five Broken
-- Blades lists 'Return to the Shady Individual' beside the katanas it waits on.
-- Returns task, key, info, marker.
function FARM.questStep()
    local key, inst = FARM.questNow()
    local tasks = inst and inst:FindFirstChild('Tasks')
    if not tasks then return nil end
    local info  = (FARM.questDb() or {})[key]
    local marks = type(info) == 'table' and type(info.Markers) == 'table'
        and info.Markers or {}
    local function done(t)
        local v, m = t:FindFirstChild('Value'), t:FindFirstChild('Max')
        return v and m and v.Value >= m.Value
    end
    for _, t in tasks:GetChildren() do
        if not done(t) then
            local mk, ready = marks[t.Name], true
            if type(mk) == 'table' and type(mk.After) == 'table' then
                for _, dep in mk.After do
                    local d = tasks:FindFirstChild(dep)
                    if d and not done(d) then ready = false end
                end
            end
            if ready then return t, key, info, type(mk) == 'table' and mk or nil end
        end
    end
    return nil, key, info
end

-- The longest NPC name that appears, as whole words, in `text`. A quest name
-- often says who it is about when its tasks do not: 'Ill eliminate the
-- Mizunoto' is a collection quest whose task only says 'Broken Nichirin
-- Katanas'.
function FARM.questNamed(text)
    if type(text) ~= 'string' then return nil end
    local hay = ' ' .. text:lower():gsub('%W', ' ') .. ' '
    local best
    for name in FARM.questSpawns() do
        if type(name) == 'string' then
            local n = ' ' .. name:lower():gsub('%W', ' ') .. ' '
            if hay:find(n, 1, true) and (not best or #name > #best) then best = name end
        end
    end
    return best
end

-- A hand-in step - go back to someone and talk - is named plainly in the data
-- ('Return to Runo', 'Report back to Niko', 'Speak with Noote'). Returns who
-- to talk to: the step's marker when it names one, else someone the step's
-- own text names, else whoever gave the quest.
function FARM.questTurnNpc(t, info, mk)
    local n = t.Name:lower()
    for _, verb in FARM.quest.turnVerbs do
        if n:find(verb) then
            return (mk and type(mk.Npc) == 'string' and mk.Npc)
                or FARM.questNamed(t.Name)
                or (type(info) == 'table' and type(info.OfferNpc) == 'string'
                    and info.OfferNpc)
                or nil
        end
    end
    return nil
end

-- Who the held quest wants dead, as a name for the farm, from its current
-- step: a marker naming the NPC, a kill `Code`, or - for a collection step -
-- the NPC the quest's own name mentions. A hand-in step wants no one.
-- Returns name, code.
function FARM.questTarget()
    local t, key, info, mk = FARM.questStep()
    if not t or FARM.questTurnNpc(t, info, mk) then return nil end
    if mk and type(mk.Npc) == 'string' then return mk.Npc end
    local code = t:FindFirstChild('Code')
    code = code and code.Value
    -- a kill code is one CamelCase word; anything with a space is a label
    if type(code) == 'string' and code ~= '' and not code:find('%s') then
        return FARM.questMatch(code), code
    end
    return FARM.questNamed(key), nil
end

-- Point the farm at the quest's target. Writes farmWant, never FARM.on: the
-- toggle is the user's.
function FARM.questAim()
    local Q = FARM.quest
    local name, code = FARM.questTarget()
    Q.target = name
    if not name then
        if code then Q.why = fmt("can't tell who %s is - pick the farm target", code) end
        return
    end
    if name ~= farmWant then
        farmWant, farmKey = name, nil
        if farmEngaged then farmDisengage(true) end
        if FARM.dd then FARM.dd:modify({ name = 'Target: ' .. name }) end
        guard(farmTick)
    end
    -- The farm only sees rigs that have streamed in, and a quest's targets are
    -- often across the map. With no live one in view, go to its spawn and let
    -- them load - only while the body is free, and not when already there.
    if farmEngaged or FARM_STATE.looting or FARM.lootHeld() or RAID.active()
        or clock() < tpHoldUntil or clock() < Q.travelAt then
        return
    end
    local key = farmPick(name)
    local rig, _, hum = key and farmResolve(key)
    if rig and hum and hum.Health > 0 then return end
    local spawn = FARM.questSpawns()[name]
    local hrp   = tpHrp()
    if typeof(spawn) == 'Vector3' and hrp
        and (hrp.Position - spawn).Magnitude > Q.near then
        Q.why, Q.travelAt = 'travelling to ' .. name, clock() + Q.settle
        -- arrive underground and stay there until the farm engages; the rigs
        -- stream in by distance, not by depth
        local spot = LOOT.buried(spawn)
        tpGo(spot)
        FARM.park = spot
    end
end

-- Farm target's way to a target this client cannot see yet. Rigs stream in
-- whole (ModelStreamingMode.Atomic) and only within the client's streaming
-- radius, which Roblox sizes per device: on a lower-end PC a target a few
-- hundred studs off does not exist on the client at all, so the farm read
-- "nothing named X" and never moved - reported as "if he's insanely close it
-- will start farming; mine just teleports". The raid never hit this because it
-- travels to each camp's area first. This does the same for one name: go to
-- its spawn (NpcSpawns, map-wide), buried, ask for the area to stream, and
-- wait there parked until the rig appears and farmTick engages it.
-- Only for the farm's OWN toggle: the raid picks its targets from what is in
-- range, and the auto quest travels on its own (questAim).
-- farmTick's refusal line, told apart from a wait that is going to plan
function FARM.seekWhy(name)
    local sk = FARM.seek and FARM.seek(name)
    if sk == 'here' then
        FARM_STATE.why = fmt("waiting at %s's spawn for it to stream in", name)
    elseif sk then
        FARM_STATE.why = fmt('travelling to %s: not streamed in here', name)
    end
end

FARM.parkJump   = 60    -- moved further than this by someone else: drop the park
FARM.seekNear   = 150   -- studs from the spawn that count as "there"
FARM.seekSettle = 8     -- seconds between trips, so a slow stream is waited out
FARM.seekAt     = 0
function FARM.seek(name)
    if not (FARM.on and name) or RAID.active() then return false end
    if FARM.quest and FARM.quest.on and FARM.questHere() then return false end
    -- The loot hold too: farmTick reaches here BEFORE its own lootHeld gate
    -- (the "nothing named X" branch), and a kill's loot is claimed before the
    -- body goes anywhere.
    if farmEngaged or FARM_STATE.looting or FARM.lootHeld()
        or clock() < tpHoldUntil then
        return false
    end
    local spawn = FARM.questSpawns()[name]
    local hrp   = tpHrp()
    if typeof(spawn) ~= 'Vector3' or not hrp then return false end
    -- Horizontal: we wait buried, so the straight-line distance to a spawn on
    -- the surface is never small, and read as "not there yet" it re-travelled.
    local d = hrp.Position - spawn
    if vec3(d.X, 0, d.Z).Magnitude <= FARM.seekNear then return 'here' end
    if clock() < FARM.seekAt then return true end
    FARM.seekAt = clock() + FARM.seekSettle
    -- Asking beats waiting: the stream around our new position comes anyway,
    -- this just starts it before we arrive. Yields, so it gets a thread.
    task.spawn(pcall, function() Me:RequestStreamAroundAsync(spawn) end)
    -- Without ground yet (not streamed) LOOT.buried drops `blind` (250) under
    -- the point - on a small streaming radius, too far for a rig on the
    -- surface ever to stream in. The spawn is itself a surface point, so
    -- `hide` under it is as good a guess and stays in range.
    local spot, ground = LOOT.buried(spawn)
    if not ground then spot = CFrame.new(spawn - vec3(0, LOOT.hide, 0)) end
    tpGo(spot)
    -- tpGo clears the park; set it after, so the body waits buried here
    FARM.park = spot
    return true
end

-- Gates the farm's next engagement: while we are talking to someone, while
-- the quest is not in hand, and while its current step is a hand-in - a kill
-- then is a kill for nothing, and the farm would hold the body forever. Never
-- while ANOTHER quest is held, or the farm would wait on a quest we cannot
-- take until that one ends.
-- Is the chosen quest offered in THIS place? The Minigames dungeon loads the
-- quest module with an EMPTY Holder, and a quest restored from the config
-- then held the farm forever: nothing in hand, nothing to take, so no failed
-- take ever counted towards `giveUp`. The raid bypasses the gate, which is why
-- a second user saw the raid work while `Farm target` sat him under the map
-- on an old park spot, for every target.
function FARM.questHere()
    local db = FARM.questDb()
    return db ~= nil and type(db[FARM.quest.want]) == 'table'
end

function FARM.questHeld()
    local Q = FARM.quest
    if not (Q.on and Q.want) or RAID.active() then return false end
    if not FARM.questHere() then return false end
    if Q.fails >= Q.giveUp then return false end
    if Q.busy then return true end
    local now = FARM.questNow()
    if now == nil then return true end
    if now ~= Q.want then return false end
    local t, _, info, mk = FARM.questStep()
    return t ~= nil and FARM.questTurnNpc(t, info, mk) ~= nil
end

-- Close whatever the dialogue is showing: its Close row when it offers one,
-- else click through its line until the frame goes. After a hand-in the NPC
-- says something and the frame stays up until clicked.
function FARM.questBye()
    local Q   = FARM.quest
    local gui = Me:FindFirstChild('PlayerGui')
    local deadline = clock() + Q.wait
    while alive and clock() < deadline do
        local df = gui and gui:FindFirstChild('DialogueFrame', true)
        if not df then return end
        local bye = df:FindFirstChild('ZZZZZZZZZ2', true)
        bye = bye and bye:FindFirstChildWhichIsA('GuiButton')
        local adv = bye or df:FindFirstChild('ClickDetector', true)
        if adv then
            for _, c in getconnections(adv.MouseButton1Click) do pcall(c.Function) end
        end
        task.wait(Q.click)
    end
end

-- Talk to `npc` from UNDERGROUND and click the dialogue row `pick(holder)`
-- returns; true once `done()` holds. Standing beside an NPC on the surface
-- pulls every mob in range onto us and they interrupt the dialogue, so the
-- body is pinned under it with noclip - LOOT.spot, the loot run's pin, which
-- is ours alone while `busy`. The caller restores LOOT.spot.
function FARM.questTalk(npc, near, pick, done)
    local Q = FARM.quest
    if typeof(near) ~= 'Vector3' then near = FARM.questSpawns()[npc] end
    -- the NPC may not be streamed in yet: wait buried under where it stands
    if typeof(near) == 'Vector3' then
        LOOT.spot = LOOT.buried(near)
        tpGo(LOOT.spot)
    end
    Q.why = 'finding ' .. npc
    local prompt
    local deadline = clock() + Q.wait
    -- stationary NPCs live under Debree; the whole workspace is the fallback
    local root = workspace:FindFirstChild('Debree') or workspace
    repeat
        for _, p in root:GetDescendants() do
            if p:IsA('ProximityPrompt') and p.Parent and p.Parent.Parent
                and p.Parent.Parent.Name == npc and p.Parent:IsA('BasePart') then
                prompt = p
                break
            end
        end
        if not prompt then task.wait(0.25) end
    until prompt or clock() > deadline or not alive
    if not prompt then
        Q.why = npc .. ' is not here'
        return false
    end
    -- Straight under it, as deep as its reach allows (7 at the NPCs' 10):
    -- every NPC prompt read live has RequiresLineOfSight = false, the same as
    -- the chests, so the ground between costs nothing.
    LOOT.spot = CFrame.new(LOOT.at(prompt) - vec3(0, LOOT.depth(prompt), 0))
    tpGo(LOOT.spot)
    task.wait(TP.hold)
    Q.why = 'talking to ' .. npc
    fireproximityprompt(prompt)
    local gui = Me:FindFirstChild('PlayerGui')
    local row
    local nextClick = clock() + Q.click
    deadline = clock() + Q.talk
    repeat
        local df = gui and gui:FindFirstChild('DialogueFrame', true)
        local bh = df and df:FindFirstChild('ButtonHolder', true)
        row = bh and pick(bh)
        -- Some NPCs (Krue) show their options at once; others (Tom, Rooyi)
        -- type a line first and only offer them after it is clicked through.
        -- The frame's `ClickDetector` button is that click; it does not pick
        -- an option when options are showing (tested).
        local adv = df and df:FindFirstChild('ClickDetector', true)
        if not row and adv and clock() >= nextClick then
            nextClick = clock() + Q.click
            for _, c in getconnections(adv.MouseButton1Click) do pcall(c.Function) end
        end
        if not row then task.wait(0.1) end
    until row or clock() > deadline or not alive
    local btn = row and row:FindFirstChildWhichIsA('GuiButton')
    if not btn then
        Q.why = npc .. ' has no option for it (level, or done for good?)'
        FARM.questBye()
        return false
    end
    -- each row's handler closes over its own action ('AddQuest', key, or a
    -- scripted hand-in like 'DeliverKatanasToRooyi'), so calling it is the click
    for _, c in getconnections(btn.MouseButton1Click) do pcall(c.Function) end
    deadline = clock() + Q.wait
    repeat task.wait(0.1) until done() or clock() > deadline or not alive
    local ok = done()
    FARM.questBye()
    return ok
end

function FARM.questTake()
    local Q    = FARM.quest
    local info = (FARM.questDb() or {})[Q.want]
    local npc  = type(info) == 'table' and info.OfferNpc
    if type(npc) ~= 'string' then
        Q.why = 'no NPC offers ' .. Q.want
        return false
    end
    local hrp = tpHrp()
    if not hrp then
        Q.why = 'no character'
        return false
    end
    local home = hrp.CFrame
    local ok = FARM.questTalk(npc, info.Position,
        function(bh) return bh:FindFirstChild(Q.want) end,
        function() return FARM.questNow() == Q.want end)
    if ok then
        Q.why = 'doing'
    elseif Q.why:find('^talking') then
        Q.why = 'the NPC did not give it (cooldown or requirement?)'
    end
    -- Stay if we know who to kill: the giver usually stands near them, and
    -- questAim travels to their spawn if not - parked under the giver in the
    -- meantime, not released to surface. Otherwise give the spot back.
    local stay = ok and FARM.questTarget() ~= nil
    if stay and LOOT.spot then FARM.park = LOOT.spot end
    -- Release the pin BEFORE moving, or it drags us straight back under the
    -- NPC on the next frame.
    LOOT.spot = Q.prevSpot
    if not stay then tpGo(home) end
    return ok
end

-- The current step is a hand-in: talk to that NPC and take its one real
-- option. A hand-in dialogue offers exactly that plus Close ("Hand over the
-- katanas"), so the row is whichever is neither Close nor a quest on offer.
function FARM.questHandIn()
    local Q = FARM.quest
    local t, key, info, mk = FARM.questStep()
    local npc = t and FARM.questTurnNpc(t, info, mk)
    if not npc then return false end
    local db   = FARM.questDb() or {}
    local near = mk and typeof(mk.Position) == 'Vector3' and mk.Position or nil
    local ok = FARM.questTalk(npc, near,
        function(bh)
            for _, r in bh:GetChildren() do
                if r:IsA('GuiObject') and r.Name ~= 'ZZZZZZZZZ2' and not db[r.Name] then
                    return r
                end
            end
        end,
        function()
            local v, m = t:FindFirstChild('Value'), t:FindFirstChild('Max')
            return not t.Parent or FARM.questNow() ~= key
                or (v and m and v.Value >= m.Value)
        end)
    if ok then
        Q.handed += 1
        Q.why = 'handed in to ' .. npc
    elseif Q.why:find('^talking') then
        Q.why = npc .. ' did not take the hand-in'
    end
    return ok
end

function FARM.questPass()
    local Q = FARM.quest
    if not Q.on then Q.why = 'off' return end
    if not Q.want then Q.why = 'no quest selected' return end
    if Q.busy then return end
    if not FARM.questHere() then Q.why = 'that quest is not offered in this place' return end
    local now = FARM.questNow()
    if now and now ~= Q.want then Q.why = 'another quest is active: ' .. now return end
    if RAID.active() then Q.why = 'the raid is driving' return end
    local turn
    if now == Q.want then
        local t, _, info, mk = FARM.questStep()
        turn = t and FARM.questTurnNpc(t, info, mk)
        if not turn then
            Q.why = 'doing'
            FARM.questAim()
            return
        end
    end
    if Q.fails >= Q.giveUp then
        Q.why = 'gave up after ' .. Q.fails .. ' tries - ' .. (Q.last or '?')
        return
    end
    -- the farm, the loot run and a teleport each own the body; wait them out
    if farmEngaged or FARM_STATE.looting or FARM.lootHeld()
        or clock() < tpHoldUntil then
        Q.why = 'waiting for the body'
        return
    end
    if clock() < Q.retry then return end
    local function run(fn)
        Q.busy, Q.prevSpot = true, LOOT.spot
        local ok, res = pcall(fn)
        -- a finished talk parks us under the NPC rather than surfacing us
        if ok and res and LOOT.spot then FARM.park = LOOT.spot end
        -- an error mid-talk must not leave us pinned under the NPC
        Q.busy, LOOT.spot = false, Q.prevSpot
        if ok and res then
            Q.fails = 0
            return true
        end
        if not ok then warn('[project] quest: ' .. tostring(res)) end
        Q.retry, Q.fails, Q.last = clock() + Q.back, Q.fails + 1, Q.why
        return false
    end
    if turn then
        if not run(FARM.questHandIn) then return end
        -- A hand-in that finished the quest leaves us under its giver, which
        -- is exactly where the next take happens: do it now rather than
        -- surfacing for a tick among the mobs. A step that remains is
        -- questAim's.
        if FARM.questNow() then
            guard(FARM.questAim)
            return
        end
    end
    if run(FARM.questTake) then
        Q.taken += 1
        guard(FARM.questAim)
    end
end

task.spawn(function()
    while alive do
        guard(FARM.questPass)
        if clock() >= FARM.quest.listAt then
            FARM.quest.listAt = clock() + FARM.quest.relist
            guard(FARM.questRelist)
        end
        task.wait(FARM.quest.tick)
    end
end)

-- ── movement ────────────────────────────────────────────────────────────────
-- Speed and flight both move the body by writing its CFrame a frame at a time.
-- Nothing touches WalkSpeed, JumpPower or a BodyMover, so there is no property
-- left set for the game's own scripts to reset or notice.
--
-- Flight is the one exception: it switches the body's parts non-collidable for
-- as long as it runs, because a CFrame write into a wall is resolved by the
-- physics solver and the body is pushed straight back out - flight without
-- noclip stops dead at the first cliff and jitters against it. Speed keeps its
-- collisions on purpose, so a wall is still a wall on the ground.
local MOVE = {
    speed    = false,  -- ships false: a Seoul toggle cannot be seeded
    -- EXTRA studs per second, on top of the walk the humanoid is already
    -- doing, so the speed on the ground is about this plus the game's own 16.
    walk     = 48,
    fly      = false,  -- ships false, same reason
    flySpeed = 90,     -- the WHOLE speed: flight owns the body while it is on
    -- A Heartbeat dt is not bounded. One hitch of a second at 90 studs/s is a
    -- 90 stud jump through whatever is in between, which is the exact shape of
    -- a move a server rejects. Cap the step rather than trust the frame.
    maxStep  = 0.1,
    -- Flight advances a point it owns rather than reading the body every
    -- frame, or gravity's half-frame of acceleration sinks us a little on
    -- every write. When something ELSE has moved us - a teleport, a respawn, a
    -- server correction - the two diverge by far more than one frame of
    -- travel, and flight re-seeds from the body instead of hauling it back.
    resync   = 8,
    -- Not a menu control. Flight through walls is what flight IS here, and a
    -- knob that lets the two disagree only produces a flight that does not
    -- work; config is for taste, not for identity.
    noclip   = true,
}
local MOVE_STATE = { flying = false, speeding = false, why = 'off', noclip = false }

-- One table rather than four locals, for the register budget again: `MV.flyAt` is
-- the point flight holds and is nil whenever flight is not running.
local MV = { char = nil, hrp = nil, hum = nil, flyAt = nil }

-- Noclip. The part list is cached per character rather than walked every
-- frame, and `NOCLIP.was` remembers only the parts that were actually colliding
-- when we took them, because a rig already has non-collidable parts
-- (HumanoidRootPart, accessory handles) and switching those ON at the end
-- would be a change, not a restore.
-- One table rather than four locals: the top level of this file is one Luau
-- function and Luau allows 200 locals in one.
-- Its two functions hang off the table for the same reason.
local NOCLIP = { parts = {}, was = {}, conn = nil, on = false }

function NOCLIP.bind(ch)
    if NOCLIP.conn then
        pcall(function() NOCLIP.conn:Disconnect() end)
        NOCLIP.conn = nil
    end
    clear(NOCLIP.parts)
    clear(NOCLIP.was)
    NOCLIP.on = false
    MOVE_STATE.noclip = false
    if not ch then return end
    for _, x in ch:GetDescendants() do
        if x:IsA('BasePart') then NOCLIP.parts[#NOCLIP.parts + 1] = x end
    end
    -- A tool equipped or a limb welded on mid-flight has to join the set, or
    -- it is the one part still catching on the wall. Per-character connection,
    -- so it is released here on the next rebind rather than leaking one a
    -- respawn.
    NOCLIP.conn = ch.DescendantAdded:Connect(function(x)
        if x:IsA('BasePart') then NOCLIP.parts[#NOCLIP.parts + 1] = x end
    end)
end

-- Re-asserted every frame, because the game's own scripts (and a respawn's
-- character setup) switch CanCollide back on - but only written on a part that
-- is actually colliding, so a settled frame costs zero writes like every other
-- property here.
function NOCLIP.set(want)
    if want and MOVE.noclip then
        for _, x in NOCLIP.parts do
            if x.Parent and x.CanCollide then
                NOCLIP.was[x] = true
                x.CanCollide = false
            end
        end
        NOCLIP.on = true
    elseif NOCLIP.on then
        for x in NOCLIP.was do
            if x.Parent then x.CanCollide = true end
        end
        clear(NOCLIP.was)
        NOCLIP.on = false
    end
    MOVE_STATE.noclip = NOCLIP.on
end

-- Rebuilt only when the character changes, like farmBind: a respawn hands us a
-- new body somewhere else entirely, so the held point goes with the old one.
local function moveBind()
    local ch = Me.Character
    if ch == MV.char and MV.hrp and MV.hrp.Parent then return true end
    -- The old body's parts are gone with it; nothing to restore, and holding
    -- references to them would keep a dead rig alive.
    NOCLIP.set(false)
    MV.char = ch
    MV.hrp  = ch and ch:FindFirstChild('HumanoidRootPart')
    MV.hum  = ch and ch:FindFirstChildOfClass('Humanoid')
    MV.flyAt    = nil
    NOCLIP.bind(ch)
    return MV.hrp ~= nil
end

-- Which way the user is asking to go, in world space and normalised. Keys are
-- read rather than taken from Humanoid.MoveDirection because that vector is
-- flattened onto the ground plane and flight wants to climb by aiming up;
-- MoveDirection is the fallback, which is what keeps a gamepad or a touch
-- stick working. A focused text box owns the keyboard: without that check,
-- typing a target name into the farm box flies.
local function moveWish(pitch)
    local dir = ZERO
    if not Input:GetFocusedTextBox() then
        local cf    = cam.CFrame
        local fwd   = cf.LookVector
        local right = cf.RightVector
        if not pitch then fwd = vec3(fwd.X, 0, fwd.Z) end
        if Input:IsKeyDown(Enum.KeyCode.W) then dir += fwd end
        if Input:IsKeyDown(Enum.KeyCode.S) then dir -= fwd end
        if Input:IsKeyDown(Enum.KeyCode.D) then dir += right end
        if Input:IsKeyDown(Enum.KeyCode.A) then dir -= right end
        if pitch then
            if Input:IsKeyDown(Enum.KeyCode.Space) then dir += UP end
            if Input:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= UP end
        end
    end
    if dir.Magnitude < 1e-3 and MV.hum then dir = MV.hum.MoveDirection end
    if dir.Magnitude < 1e-3 then return ZERO end
    return dir.Unit
end

local function moveStep(dt)
    MOVE_STATE.flying, MOVE_STATE.speeding = false, false
    -- Bind BEFORE the off test: NOCLIP.parts comes from this, and the loot
    -- pin and the quest take noclip through it with movement switched off.
    -- Bound only inside the movement branch, the set stayed empty and every
    -- underground pin ran with collisions on - ejected 3.2 studs in 0.75s.
    local bound = moveBind()
    if not (MOVE.fly or MOVE.speed) then
        MOVE_STATE.why = 'off'
        MV.flyAt = nil
        return
    end
    if not bound then
        MOVE_STATE.why = 'no character'
        return
    end
    -- The farm pins the body every frame and a teleport re-writes it for
    -- TP.hold seconds afterwards. Both own the body outright while they run,
    -- so movement stands down rather than fighting over the same property -
    -- the same rule teleports follow, and for the same reason.
    if farmEngaged or FARM_STATE.looting or FARM.parked() then
        MOVE_STATE.why = 'farm owns the body'
        MV.flyAt = nil
        return
    end
    if clock() < tpHoldUntil then
        MOVE_STATE.why = 'teleporting'
        MV.flyAt = nil
        return
    end

    dt = min(dt or 0, MOVE.maxStep)
    -- A zero-length frame has no movement in it, but it is no reason to hand
    -- the body its collisions back for one frame and take them again on the
    -- next: say which mode we are in and skip only the maths.
    if dt <= 0 then
        if MOVE.fly then MOVE_STATE.flying, MOVE_STATE.why = true, 'flying' end
        return
    end

    if MOVE.fly then
        local pos = MV.hrp.Position
        if not MV.flyAt or (MV.flyAt - pos).Magnitude > MOVE.resync then MV.flyAt = pos end
        MV.flyAt += moveWish(true) * (MOVE.flySpeed * dt)
        -- Position only. The rotation stays whatever the character's own
        -- control module last set, so flight does not stop the body turning.
        MV.hrp.CFrame                 = CFrame.new(MV.flyAt) * MV.hrp.CFrame.Rotation
        MV.hrp.AssemblyLinearVelocity = ZERO
        MOVE_STATE.flying = true
        MOVE_STATE.why    = 'flying'
        return
    end

    MV.flyAt = nil
    local dir = moveWish(false)
    if dir.Magnitude < 1e-3 then
        MOVE_STATE.why = 'standing still'
        return
    end
    -- Added to wherever the humanoid has already walked us this frame, which
    -- is what keeps jumping, slopes and collisions behaving normally.
    MV.hrp.CFrame = MV.hrp.CFrame + dir * (MOVE.walk * dt)
    MOVE_STATE.speeding = true
    MOVE_STATE.why      = 'speeding'
end

-- One call after moveStep rather than one per exit path: MOVE_STATE.flying is
-- cleared at the top of moveStep and set only in the flight branch, so this
-- restores collisions on every way out of it - switched off, no character, the
-- farm taking the body, a teleport hold, or moveStep erroring inside guard().
conns[#conns + 1] = Run.Heartbeat:Connect(function(dt)
    -- The loot run holds a spot between its own yields, and it holds it inside
    -- the ground, so it needs both of the mechanisms flight needs.
    guard(LOOT.pin)
    guard(moveStep, dt)
    -- engaged too: collisions on mid-fight let the ground push us up between
    -- the farm's own writes - 405 surfaced frames in 100s of fighting
    guard(NOCLIP.set, MOVE_STATE.flying or LOOT.spot ~= nil or FARM.parked() ~= nil
        or farmEngaged)
end)

-- ── config ────────────────────────────────────────────────────────
-- Settings the user chose - colours, switches, slider values, the farm target -
-- written to JSON in the executor's workspace folder and read back on the next
-- run. The file is plain text someone may edit, so everything is checked by
-- type and clamped on the way in: a wrong shape is ignored, never applied and
-- never fatal. A missing executor filesystem is simply no persistence.
local CONF = {
    folder  = 'ProjectSlayer',
    path    = 'ProjectSlayer/config.json',
    delay   = 1,    -- seconds after the last change before the write, so that
                    -- dragging a slider costs one write rather than sixty
    version = 1,
}
local confAt    = 0      -- when the last change was marked, 0 when clean
local confSaved          -- what was read at startup, applied in two phases
-- Registered by the menu as it builds: a saved boolean can only be applied if
-- the pill that reports it can be made to agree, so the element has to be here.
local SWITCHES = {}

local function confFs()
    return type(isfile) == 'function' and type(readfile) == 'function'
        and type(writefile) == 'function'
end

local function hex(c)
    return fmt('#%02X%02X%02X', floor(c.R * 255 + 0.5),
        floor(c.G * 255 + 0.5), floor(c.B * 255 + 0.5))
end

local function unhex(v)
    if type(v) ~= 'string' then return nil end
    local r, g, b = v:match('^#(%x%x)(%x%x)(%x%x)$')
    if not r then return nil end
    return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

-- A number the menu could actually have produced. NaN defeats every comparison,
-- so it is rejected outright rather than clamped.
local function num(v, lo, hi, dflt)
    if type(v) ~= 'number' or v ~= v then return dflt end
    return clamp(v, lo, hi)
end

local function dig(t, path)
    for part in path:gmatch('[^.]+') do
        if type(t) ~= 'table' then return nil end
        t = t[part]
    end
    return t
end

local function confDump()
    local esp = {}
    for key, c in CFG do
        esp[key] = { on = c.on, showName = c.showName, showDist = c.showDist,
                     color = hex(c.color) }
    end
    return {
        version = CONF.version,
        esp     = esp,
        tuning  = { maxVisible = TUNING.maxVisible },
        move    = { fly = MOVE.fly, speed = MOVE.speed,
                    flySpeed = MOVE.flySpeed, walk = MOVE.walk },
        farm    = { on = FARM.on, bail = FARM.bail, resume = FARM.resume,
                    evadeDrop = FARM.evadeDrop, want = farmWant,
                    noDodge = not FARM.evade,
                    skills = FARM.skills,
                    cam = FARM.cam, camUp = FARM.camUp,
                    camOut = FARM.camOut, camSpin = FARM.camSpin },
        loot    = { on = LOOT.on, map = LOOT.map },
        raid    = { on = RAID.on, wave = RAID.wave },
        cards   = { on = CARDS.on, skip = CARDS.skip },
        quest   = { on = FARM.quest.on, want = FARM.quest.want },
        tp      = { up = TP.up, cat = TP.cat },
    }
end

-- The shipped values, snapshotted before anything saved is applied, so a reset
-- has somewhere to go back to without re-running the script.
local DEFAULTS = confDump()

local function confSave()
    if not confFs() then return false end
    local ok, err = pcall(function()
        if type(isfolder) == 'function' and type(makefolder) == 'function'
            and not isfolder(CONF.folder) then
            makefolder(CONF.folder)
        end
        writefile(CONF.path, Http:JSONEncode(confDump()))
    end)
    confAt = 0
    if not ok then warn('[project] config save failed: ' .. tostring(err)) end
    return ok
end

local function confMark() confAt = clock() end

local function confRead()
    if not confFs() then return nil end
    local ok, data = pcall(function()
        if not isfile(CONF.path) then return nil end
        return Http:JSONDecode(readfile(CONF.path))
    end)
    if not ok then
        warn('[project] config unreadable, ignoring it: ' .. tostring(data))
        return nil
    end
    return type(data) == 'table' and data or nil
end

-- Phase one: everything that is not a switch. Runs BEFORE the menu is built so
-- that each slider and dropdown is created already carrying its restored value
-- in its name - Seoul shows neither, and neither can be repainted from outside
-- its own callback.
local function confValues(d)
    if type(d) ~= 'table' then return end
    if type(d.esp) == 'table' then
        for key, c in CFG do
            local saved = d.esp[key]
            if type(saved) == 'table' then c.color = unhex(saved.color) or c.color end
        end
    end
    if type(d.tuning) == 'table' then
        TUNING.maxVisible = num(d.tuning.maxVisible, 1, 300, TUNING.maxVisible)
    end
    if type(d.move) == 'table' then
        MOVE.flySpeed = num(d.move.flySpeed, 0, 400, MOVE.flySpeed)
        MOVE.walk     = num(d.move.walk, 0, 300, MOVE.walk)
    end
    if type(d.farm) == 'table' then
        FARM.bail      = num(d.farm.bail, 0, math.huge, FARM.bail)
        FARM.resume    = num(d.farm.resume, 0, math.huge, FARM.resume)
        FARM.evadeDrop = num(d.farm.evadeDrop, 0, 200, FARM.evadeDrop)
        FARM.camUp     = num(d.farm.camUp, 0, 100, FARM.camUp)
        FARM.camOut    = num(d.farm.camOut, 0, 200, FARM.camOut)
        FARM.camSpin   = num(d.farm.camSpin, 0, 90, FARM.camSpin)
        if type(d.farm.want) == 'string' and d.farm.want ~= '' then
            farmWant = d.farm.want
        end
        if type(d.farm.skills) == 'string' then
            local keys = FARM.parseSkills(d.farm.skills)
            if keys then
                FARM.skills, FARM.skillKeys = table.concat(keys, ','), keys
            end
        end
    end
    if type(d.quest) == 'table' and type(d.quest.want) == 'string'
        and d.quest.want ~= '' then
        FARM.quest.want = d.quest.want
    end
    if type(d.tp) == 'table' then
        TP.up = num(d.tp.up, 0, 50, TP.up)
        if type(d.tp.cat) == 'string' and CFG[d.tp.cat] then TP.cat = d.tp.cat end
    end
end

-- Phase two: the switches. A Seoul toggle closes over a hardcoded
-- `local state = false` that nothing in its API can seed, so a restored `true`
-- would leave the pill grey while the feature ran, and the next click would
-- turn the feature OFF while the pill went green - inverted for the session.
-- The state IS reachable: the element carries its frame, the frame's `trigger`
-- button carries the one click handler, and that handler's only boolean upvalue
-- is the state. Seed it, paint the pill the colours the handler would, and
-- prove it took by reading it back. If any step is missing - another executor,
-- a library rewrite - the switch is left OFF, which is the one state that is
-- always honest.
local PILL_ON = Color3.new(0.14902, 1, 0)

local function seed(el, want)
    if not (el and el._instance) then return false end
    local trig = el._instance:FindFirstChild('trigger')
    if not trig or type(getconnections) ~= 'function' or type(debug) ~= 'table'
        or type(debug.getupvalues) ~= 'function'
        or type(debug.getupvalue) ~= 'function'
        or type(debug.setupvalue) ~= 'function' then
        return false
    end
    return (pcall(function()
        local cons = getconnections(trig.MouseButton1Click)
        local fn   = cons and cons[1] and cons[1].Function
        if not fn then error('no handler', 0) end
        -- Found by TYPE, never by a fixed index: an index is a property of the
        -- library's source order, and would rot silently on the next release.
        local idx
        for i, v in pairs(debug.getupvalues(fn)) do
            if type(v) == 'boolean' then
                if idx then error('ambiguous state', 0) end
                idx = i
            end
        end
        if not idx then error('no state upvalue', 0) end
        debug.setupvalue(fn, idx, want)
        if debug.getupvalue(fn, idx) ~= want then error('seed did not take', 0) end
        trig.BackgroundColor3       = want and PILL_ON or WHITE
        trig.BackgroundTransparency = want and 0.6 or 0.95
    end))
end

-- `path` is where this switch lives in the saved file, e.g. 'esp.Boss.on'.
local function confSwitch(path, el, set)
    SWITCHES[path] = { el = el, set = set }
end

local function confSwitches(d)
    if type(d) ~= 'table' then return 0 end
    local n = 0
    for path, sw in SWITCHES do
        local want = dig(d, path)
        -- The value follows the pill, never the other way round.
        if type(want) == 'boolean' and seed(sw.el, want) then
            sw.set(want)
            n += 1
        end
    end
    return n
end

confSaved = confRead()
confValues(confSaved)

task.spawn(function()
    while alive do
        guard(function()
            if confAt > 0 and clock() - confAt >= CONF.delay then confSave() end
        end)
        task.wait(0.5)
    end
end)

-- ── lifecycle ───────────────────────────────────────────────────────────────
local function cleanup()
    if not alive then return end
    -- Write before the teardown, not after: `alive = false` stops the autosave
    -- loop, so an unload would otherwise drop whatever changed in the last
    -- second of the session.
    if confAt > 0 then confSave() end
    alive = false
    farmDisengage(true)
    -- Unloading mid-flight must not leave the body walking through walls.
    NOCLIP.set(false)
    NOCLIP.bind(nil)
    -- A render step is not in `conns` and outlives a destroyed ScreenGui like
    -- any other world connection, so it is unbound by name. Release after it,
    -- or the release would be undone by the last frame's pin.
    pcall(function() Run:UnbindFromRenderStep(CAMH.step) end)
    CAMH.release()
    -- hand the skills their real cursor back
    if FARM.aimRestore then pcall(FARM.aimRestore) end
    -- An RBXScriptConnection has no :Destroy(); :Disconnect() is the teardown,
    -- and every connection this script makes lands in one of four places so
    -- that a re-execute frees all of them: `conns` for world and input signals,
    -- `playerConns` keyed per player, `d.conns` per tracked target, and
    -- `farmEvadeConns` for the engagement. pcall because a connection to an
    -- instance that has already gone can throw.
    for _, x in conns do pcall(function() x:Disconnect() end) end
    clear(conns)
    for p in playerConns do unhook(p) end
    for c in tracked do untrack(c) end
    clear(pool)
    np = 0
    if uiGui then pcall(function() uiGui:Destroy() end) end
    if genv.seoul == uiGui then genv.seoul = nil end
    gui:Destroy()
    if genv.project == gui then genv.project = nil end
    -- Only if it is still OURS. A re-execute can land in the same getgenv view,
    -- in which case the new run has already published its own cleanup and
    -- clearing it unconditionally would disarm the run that is taking over.
    if genv.projectCleanup == cleanup then genv.projectCleanup = nil end
end

-- ── optional game adapter: region places ────────────────────────────────────
-- A place has no instance to find: the map streams, so a region you are not
-- standing in has no parts at all. When a game publishes its regions as data,
-- read them. Shape-checked at every step, so this quietly does nothing
-- anywhere else.
local function loadPlaces()
    local rs = game:GetService('ReplicatedStorage')
    local script_ = rs:FindFirstChild('Regions')
    if not script_ or not script_:IsA('ModuleScript') then return 0 end
    local ok, mod = pcall(require, script_)
    if not ok or type(mod) ~= 'table' or type(mod.Regions) ~= 'table' then return 0 end

    local spawns = type(mod.NpcSpawns) == 'table' and mod.NpcSpawns or {}
    local added = 0

    for key, region in mod.Regions do
        local area = type(region) == 'table' and region.Area or nil
        local grid = type(area) == 'table' and area.Grid or nil
        if type(grid) == 'table' then
            for _, cell in grid do
                -- Center and Radius are Vector2 of world X/Z; there is no Y
                if type(cell) == 'table' and typeof(cell.Center) == 'Vector2' then
                    local c, r = cell.Center, cell.Radius
                    -- borrow the altitude from npc spawns standing in this area
                    local sum, hits = 0, 0
                    for _, pos in spawns do
                        if typeof(pos) == 'Vector3' then
                            if not r or (abs(pos.X - c.X) <= r.X and abs(pos.Z - c.Y) <= r.Y) then
                                sum += pos.Y
                                hits += 1
                            end
                        end
                    end
                    local y = hits > 0 and sum / hits or 0
                    if addPoint(region.Name or key, vec3(c.X, y, c.Y)) then
                        added += 1
                    end
                    break   -- one marker per region, not one per grid cell
                end
            end
        end
    end
    return added
end

pcall(loadPlaces)

rescan()
conns[#conns + 1] = workspace.DescendantAdded:Connect(consider)
conns[#conns + 1] = workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
    cam = workspace.CurrentCamera
end)

local function hook(p)
    if p == Me or playerConns[p] then return end
    playerConns[p] = p.CharacterAdded:Connect(function(ch) track(ch, 'Player') end)
end
for _, p in Plrs:GetPlayers() do hook(p) end
conns[#conns + 1] = Plrs.PlayerAdded:Connect(hook)
conns[#conns + 1] = Plrs.PlayerRemoving:Connect(unhook)

local live, sweep = {}, 0
-- weight biases the cull: a plain nearest-first sort drops a boss the moment a
-- crowd of nearer mobs fills the cap, which is exactly when you want it
local function byRank(a, b) return a.rank < b.rank end

-- In `conns` as well as held in `rc`: the self-disconnect below only fires on
-- the NEXT frame, so without this a re-execute overlaps one frame of the old
-- draw loop with the new one. Disconnecting twice is harmless.
local rc
rc = Run.RenderStepped:Connect(function()
    if not alive or not gui.Parent then
        rc:Disconnect()
        cleanup()
        return
    end
    if not cam then return end

    local eye = cam.CFrame.Position
    local vp  = cam.ViewportSize
    local now = clock()
    local minX, maxX = -K.CULL, vp.X + K.CULL
    local minY, maxY = -K.CULL, vp.Y + K.CULL

    -- pass one: filter and measure, no projection and no property writes
    clear(live)
    local n = 0
    for c, d in tracked do
        -- a point target has a synthetic key, so it has no Parent to lose
        if not d.point and not c.Parent then
            untrack(c)
            continue
        end
        local cat = CFG[d.cat]
        if not cat or cat.on ~= true then
            hide(d)
            continue
        end
        if d.point then
            d.dist = (d.point - eye).Magnitude
            d.rank = d.dist * (cat.weight or 1)
            n += 1
            live[n] = d
            continue
        end
        if d.dirty then refresh(c, d) end
        -- No retry poll: a target with no rig yet just stays hidden until
        -- DescendantAdded marks it dirty. Polling here meant every unspawned
        -- boss folder re-walked its descendants twice a second forever.
        local anchor = d.anchor
        if not anchor or not anchor.Parent or not d.top then
            hide(d)
            continue
        end
        local cf = anchor.CFrame
        d.cf   = cf
        d.dist = (cf * d.center - eye).Magnitude
        d.rank = d.dist * (cat.weight or 1)
        n += 1
        live[n] = d
    end

    -- pass two: budget. Sorting only happens over the cap.
    local cap, shown = TUNING.maxVisible, n
    if n > cap then
        sort(live, byRank)
        shown = cap
        for i = cap + 1, n do hide(live[i]) end
    end

    for i = 1, shown do
        local d = live[i]
        draw(d, CFG[d.cat], minX, maxX, minY, maxY)
    end

    if now - sweep >= K.SWEEP then
        sweep = now
        for _, d in tracked do
            if d.w and d.since and now - d.since >= K.RELEASE then
                release(d.w)
                d.w = nil
            end
        end
    end
end)
conns[#conns + 1] = rc

-- ── ui ──────────────────────────────────────────────────────────────────────
-- Seoul quirks worked around here: a toggle cannot be seeded or resynced (so
-- every flag ships off and nothing outside the menu writes one), a slider's drag
-- ignores `min` (so min is always 0), and neither sliders nor dropdowns show
-- their own value (so each carries it in its name).
local FLAGS   = { { 'Enabled', 'on' }, { 'Name', 'showName' }, { 'Distance', 'showDist' } }
local COLOURS = {
    { 'White',  WHITE },
    { 'Gold',   Color3.fromRGB(255, 205,  90) },
    { 'Cyan',   Color3.fromRGB(110, 215, 255) },
    { 'Orange', Color3.fromRGB(255, 150,  80) },
    { 'Green',  Color3.fromRGB(130, 235, 140) },
    { 'Red',    Color3.fromRGB(255,  95,  95) },
    { 'Violet', Color3.fromRGB(190, 140, 255) },
    { 'Pink',   Color3.fromRGB(255, 140, 200) },
}

local function buildUi()
    local seoul = loadstring(game:HttpGet(K.SEOUL))()()
    local win = seoul:window('Project Slayer (E)')
    if not win then return end
    uiGui = genv.seoul
    -- the X on the topbar destroys this gui: take everything else with it.
    -- Deferred, so cleanup does not run inside the library's own destroy.
    pcall(function()
        conns[#conns + 1] = uiGui.Destroying:Connect(function()
            task.defer(cleanup)
        end)
    end)

    local g = win:folder('Global')
    local sl
    sl = g:slider({
        name = 'Max markers: ' .. TUNING.maxVisible, min = 0, max = 300,
        call = function(v)
            TUNING.maxVisible = v < 1 and 1 or v
            sl:modify({ name = 'Max markers: ' .. TUNING.maxVisible })
            confMark()
        end,
    })
    g:query({
        placeholder = 'Track by name...',
        call = function(q)
            if not q or q == '' then return end
            local hits = 0
            for _, x in workspace:GetDescendants() do
                if x.Name == q and (x:IsA('Model') or x:IsA('BasePart'))
                    and track(x, 'Object', true) then
                    hits += 1
                end
            end
            seoul:notify(hits > 0 and fmt('Tracking %d x %s', hits, q)
                or fmt('Nothing named %s', q))
        end,
    })
    -- Movement. Both toggles ship off, so both pills start honest, and the two
    -- sliders carry their value in the name because Seoul never shows one.
    g:divider('Movement')
    confSwitch('move.fly',
        g:toggle({ name = 'Fly (WASD, Space/Ctrl)',
            call = function(v)
                MOVE.fly = v
                confMark()
            end }),
        function(v) MOVE.fly = v end)
    local flySl
    flySl = g:slider({
        name = 'Fly speed: ' .. MOVE.flySpeed, min = 0, max = 400,
        call = function(v)
            MOVE.flySpeed = v
            flySl:modify({ name = 'Fly speed: ' .. v })
            confMark()
        end,
    })
    confSwitch('move.speed',
        g:toggle({ name = 'CFrame speed',
            call = function(v)
                MOVE.speed = v
                confMark()
            end }),
        function(v) MOVE.speed = v end)
    local spdSl
    spdSl = g:slider({
        -- signed, because it ADDS to the game's own walk rather than replacing it
        name = 'Speed: +' .. MOVE.walk, min = 0, max = 300,
        call = function(v)
            MOVE.walk = v
            spdSl:modify({ name = 'Speed: +' .. v })
            confMark()
        end,
    })

    g:button({ name = 'Unload', call = cleanup })

    -- Neither a dropdown nor a button shows its own value, so each carries the
    -- current one in its name and repaints it in the callback.
    local farmF = win:folder('Farm')
    -- One folder, split by dividers: it had grown to twenty-odd controls
    -- in one run. A divider takes a bare string (see Seoul in CLAUDE.md).
    farmF:divider('Target')
    FARM.dd = farmF:dropdown({
        name = 'Target: none', elements = {},
        call = function(pick)
            if not FARM.labels[pick] then return end
            -- the label IS the name now, so the pick survives that body dying
            farmWant = pick
            farmKey  = nil
            if farmEngaged then farmDisengage(true) end
            FARM.dd:modify({ name = 'Target: ' .. pick })
            confMark()
            -- act now rather than on the next scan: up to 1.5s of nothing
            -- happening after a click reads as the farm being broken
            guard(farmTick)
        end,
    })
    farmF:query({
        placeholder = 'Target by name...',
        call = function(text)
            local key = farmFind(text)
            if not key then
                seoul:notify('No boss or mob matching ' .. tostring(text))
                return
            end
            -- keep the NAME the search landed on, not the body: typing
            -- "bear cub" should farm bear cubs, not one particular cub
            farmWant = key.Name
            farmKey  = nil
            if farmEngaged then farmDisengage(true) end
            FARM.dd:modify({ name = 'Target: ' .. farmWant })
            seoul:notify('Target: ' .. farmWant)
            confMark()
            guard(farmTick)
        end,
    })
    confSwitch('farm.on',
        farmF:toggle({ name = 'Farm target', call = function(v)
            FARM.on = v
            confMark()
            guard(farmTick)
        end }),
        function(v) FARM.on = v end)
    -- Skill keys, typed in cast order. The box cannot show its own value, so
    -- the placeholder carries the restored one and every submit notifies.
    farmF:query({
        placeholder = FARM.skills ~= '' and ('Skills: ' .. FARM.skills)
            or 'Skills in order, e.g. Z,X,C',
        call = function(text)
            local keys, bad = FARM.parseSkills(text)
            if not keys then
                seoul:notify('Not a key: ' .. tostring(bad) .. ' (letters and digits only)')
                return
            end
            FARM.skills, FARM.skillKeys = table.concat(keys, ','), keys
            seoul:notify(#keys > 0 and ('Skills: ' .. FARM.skills) or 'Skills off')
            confMark()
        end,
    })
    FARM.btn = farmF:button({
        name = 'Return point: none',
        call = function()
            local char = Me.Character
            local hrp  = char and char:FindFirstChild('HumanoidRootPart')
            if not hrp then
                seoul:notify('No character')
                return
            end
            farmHome = hrp.CFrame
            local p  = farmHome.Position
            FARM.btn:modify({ name = fmt('Return point: %d, %d, %d',
                floor(p.X + 0.5), floor(p.Y + 0.5), floor(p.Z + 0.5)) })
            seoul:notify('Return point set')
        end,
    })

    farmF:divider('Safety')
    -- The resting offset gets no slider: it follows the equipped weapon, so a
    -- control for it would be silently overwritten by the next weapon swap.
    -- The dodge is a free choice on top, so that one keeps its slider.
    do
        local maxHp = farmMaxHp()
        for _, row in { { 'Bail at', 'bail' }, { 'Resume at', 'resume' } } do
            local hpSl
            hpSl = farmF:slider({
                name = row[1] .. ': ' .. FARM[row[2]] .. ' hp', min = 0, max = maxHp,
                call = function(v)
                    FARM[row[2]] = v
                    hpSl:modify({ name = row[1] .. ': ' .. v .. ' hp' })
                    confMark()
                end,
            })
        end
    end
    -- Off switch for the dodge. A trigger that keeps firing - something a
    -- weapon or effect puts on the target that the filters do not know -
    -- parks the body `evadeDrop` studs down for the whole fight, and it reads
    -- as "never goes to the target". `Farm status` names the trigger.
    confSwitch('farm.noDodge',
        farmF:toggle({ name = 'Never dodge',
            call = function(v)
                FARM.evade = not v
                confMark()
            end }),
        function(v) FARM.evade = not v end)
    local dropSl
    dropSl = farmF:slider({
        name = 'Dodge drop: ' .. FARM.evadeDrop, min = 0, max = 200,
        call = function(v)
            FARM.evadeDrop = v
            dropSl:modify({ name = 'Dodge drop: ' .. FARM.evadeDrop })
            confMark()
        end,
    })
    -- What the farm is doing, in one line: the question every "it does
    -- nothing" report starts with, answerable without a console.
    farmF:button({
        name = 'Farm status',
        call = function()
            local st = FARM_STATE
            local share = st.frames > 0 and floor(100 * st.dodgeFrames / st.frames + 0.5) or 0
            seoul:notify(fmt('%s | dodging %d%% | last dodge: %s | loot pin: %s | lead %.2fs (%.1f studs now)',
                tostring(st.why), share, tostring(st.dodge or 'none'),
                (LOOT.spot and 'set' or 'none'), FARM.leadTime(), st.lead or 0))
        end,
    })
    farmF:divider('Camera')
    -- Farming from under a target buries the body, and the default camera has
    -- nothing to show from in there. This parks the camera above the target
    -- instead, locked: while it is on, the mouse does not move the view.
    confSwitch('farm.cam',
        farmF:toggle({ name = 'Lock camera on target',
            call = function(v)
                FARM.cam = v
                confMark()
            end }),
        function(v) FARM.cam = v end)
    for _, row in { { 'Camera height', 'camUp', 100 },
                    { 'Camera distance', 'camOut', 200 },
                    { 'Camera spin', 'camSpin', 90 } } do
        local camSl
        camSl = farmF:slider({
            name = row[1] .. ': ' .. FARM[row[2]], min = 0, max = row[3],
            call = function(v)
                FARM[row[2]] = v
                camSl:modify({ name = row[1] .. ': ' .. v })
                confMark()
            end,
        })
    end

    farmF:divider('Loot')
    confSwitch('loot.on',
        farmF:toggle({ name = 'Claim loot',
            call = function(v)
                LOOT.on = v
                confMark()
            end }),
        function(v) LOOT.on = v end)
    -- The same claimer with the range test dropped and a tour of the map under
    -- it, claiming from inside the ground at every stop. It runs on its own -
    -- `Claim loot` does not have to be on beside it.
    confSwitch('loot.map',
        farmF:toggle({ name = 'Sweep map for loot',
            call = function(v)
                LOOT.map = v
                confMark()
            end }),
        function(v) LOOT.map = v end)
    farmF:divider('Raid & dungeon')
    -- Drives the farm and the loot run without writing either toggle, so both
    -- pills keep telling the truth about what the user switched on.
    confSwitch('raid.on',
        farmF:toggle({ name = 'Raid farm',
            call = function(v)
                RAID.on = v
                confMark()
            end }),
        function(v) RAID.on = v end)
    -- The raid without the tour: fight every spawn, bosses too, and wait for
    -- the next wave in place. For modes you never leave (dungeon / infinite).
    confSwitch('raid.wave',
        farmF:toggle({ name = 'Wave farm (dungeon)',
            call = function(v)
                RAID.wave = v
                confMark()
            end }),
        function(v) RAID.wave = v end)
    -- The dungeon's hands: rewards Fortune > damage > Second Wind, events the
    -- biggest points multiplier. And the wave skip between floors.
    confSwitch('cards.on',
        farmF:toggle({ name = 'Auto pick cards',
            call = function(v)
                CARDS.on = v
                confMark()
            end }),
        function(v) CARDS.on = v end)
    confSwitch('cards.skip',
        farmF:toggle({ name = 'Auto skip wave',
            call = function(v)
                CARDS.skip = v
                confMark()
            end }),
        function(v) CARDS.skip = v end)
    farmF:divider('Quest')
    -- Keeps one quest in hand and holds the farm off while it is not; the farm
    -- target above is still what gets killed.
    do
        local qDd
        local list = FARM.questList()
        qDd = farmF:dropdown({
            name = 'Quest: ' .. (FARM.quest.want or 'none'),
            elements = list,
            call = function(pick)
                FARM.quest.want, FARM.quest.retry, FARM.quest.fails = pick, 0, 0
                qDd:modify({ name = 'Quest: ' .. pick })
                -- the row text is long and the list moves; say what was taken
                seoul:notify('Quest: ' .. pick)
                confMark()
            end,
        })
        FARM.quest.dd, FARM.quest.sig = qDd, table.concat(list, '\n')
    end
    confSwitch('quest.on',
        farmF:toggle({ name = 'Auto quest',
            call = function(v)
                FARM.quest.on, FARM.quest.retry, FARM.quest.fails = v, 0, 0
                confMark()
                -- it drives the farm, so act on the click like Farm target does
                guard(farmTick)
            end }),
        function(v) FARM.quest.on = v end)

    -- Teleports. Same two ways in as the farm - pick from a list, or type a
    -- name - over the same tracked set, so anything the ESP can draw is
    -- somewhere we can go.
    local tpF = win:folder('Teleports')
    local function tpPaint(label)
        if tpDd then tpDd:modify({ name = 'Target: ' .. (label or 'none') }) end
    end
    -- The farm pins us to its target every frame, so it wins any argument with
    -- a teleport. Say so rather than writing FARM.on, which a Seoul toggle
    -- cannot be resynced to.
    local function tpJump(key, label)
        local pos, stale = tpPoint(key)
        if not pos then
            seoul:notify(tostring(label or '?') .. (tpCat(key) == 'Player'
                and ' is too far away to locate - get closer'
                or ' is not spawned'))
            return false
        end
        if not tpGo(pos) then
            seoul:notify('No character')
            return false
        end
        seoul:notify('-> ' .. tostring(label or '?')
            .. (stale and ' (last known spot)' or ''))
        if FARM.on then seoul:notify('Farm is on - it will pull you back') end
        return true
    end

    local catNames, catKey = {}, {}
    for i, key in ORDER do
        catNames[i] = LABELS[key] or key
        catKey[catNames[i]] = key
    end
    tpCatDd = tpF:dropdown({
        name = 'Category: ' .. (LABELS[TP.cat] or TP.cat), elements = catNames,
        call = function(pick)
            local key = catKey[pick]
            if not key then return end
            TP.cat, tpKey = key, nil
            tpCatDd:modify({ name = 'Category: ' .. pick })
            confMark()
            tpPaint(nil)
            guard(tpRefresh)
        end,
    })
    tpDd = tpF:dropdown({
        name = 'Target: none', elements = {},
        call = function(pick)
            local key = TP.labels[pick]
            if not key then return end
            tpKey = key
            tpPaint(pick)
        end,
    })
    tpF:button({
        name = 'Teleport',
        call = function()
            if not tpKey then
                seoul:notify('No target selected')
                return
            end
            tpJump(tpKey, tpName(tpKey))
        end,
    })
    tpF:query({
        placeholder = 'Teleport by name...',
        call = function(text)
            local key = tpFind(text)
            if not key then
                seoul:notify('Nothing spawned matching ' .. tostring(text))
                return
            end
            local cat = tpCat(key)
            -- follow the hit into its own category, or the list on screen
            -- disagrees with the target the Teleport button now holds
            if cat and cat ~= TP.cat then
                TP.cat = cat
                tpCatDd:modify({ name = 'Category: ' .. (LABELS[cat] or cat) })
                guard(tpRefresh)
            end
            tpKey = key
            local name = tpName(key)
            tpPaint(name)
            tpJump(key, name)
        end,
    })
    local tpSl
    tpSl = tpF:slider({
        name = 'Height: ' .. TP.up, min = 0, max = 60,
        call = function(v)
            TP.up = v
            tpSl:modify({ name = 'Height: ' .. TP.up })
            confMark()
        end,
    })
    guard(tpRefresh)

    -- One folder for every category, split by dividers. Six collapsible
    -- folders was six clicks to compare two categories; the divider carries the
    -- name so the controls under it can stay plainly Enabled / Name / Distance.
    local espF = win:folder('ESP')
    for _, key in ORDER do
        local c = CFG[key]
        -- a divider takes a bare string, unlike every other element here:
        -- divider:__new does tostring(name), so a table renders as its address
        espF:divider(LABELS[key] or key)
        for _, fl in FLAGS do
            local field = fl[2]
            confSwitch('esp.' .. key .. '.' .. field,
                espF:toggle({ name = fl[1],
                    call = function(v)
                        c[field] = v
                        confMark()
                    end }),
                function(v) c[field] = v end)
        end
        local dd
        local function cap()
            for _, pair in COLOURS do
                if pair[2] == c.color then return 'Colour: ' .. pair[1] end
            end
            return 'Colour: ?'
        end
        local names = {}
        for i, pair in COLOURS do names[i] = pair[1] end
        dd = espF:dropdown({
            name = cap(), elements = names,
            call = function(pick)
                for _, pair in COLOURS do
                    if pair[1] == pick then
                        c.color = pair[2]
                        break
                    end
                end
                dd:modify({ name = cap() })
                confMark()
            end,
        })
    end

    conns[#conns + 1] = Input.InputBegan:Connect(function(i, typed)
        if not typed and i.KeyCode == K.UI_KEY and uiGui and uiGui.Parent then
            uiGui.Enabled = not uiGui.Enabled
        end
    end)

    -- Phase two of the config: the switches, now that every pill exists to be
    -- seeded. A saved target is a name, so it survives the body that carried it.
    if farmWant and FARM.dd then FARM.dd:modify({ name = 'Target: ' .. farmWant }) end
    local restored = confSwitches(confSaved)

    win:ready()
    seoul:notify(confSaved and fmt('ESP loaded - config restored (%d switches)', restored)
        or 'ESP loaded - RightShift hides the menu')
    return { seoul = seoul, window = win }
end


genv.projectCleanup = cleanup

-- The teardown that does not depend on getgenv(). One attribute read every
-- GEN.poll seconds, and it stops everything this run owns - threads, Heartbeat
-- connections, gui - the moment a newer execution stamps its own token.
task.spawn(function()
    while alive do
        if GEN.stale() then
            guard(cleanup)
            break
        end
        -- Closing the menu ends the script. Seoul's topbar X destroys the
        -- whole library ScreenGui, and that used to leave the farm, the raid,
        -- the loot run and the ESP all running with no menu left to stop
        -- them. The Destroying hook in buildUi is instant; this catches a gui
        -- that went away any other way.
        if uiGui and not uiGui.Parent then
            guard(cleanup)
            break
        end
        task.wait(GEN.poll)
    end
end)

-- When live-reload is driving, let it own teardown: without this a reload would
-- leave the previous run's connections, render loop and gui alive alongside the
-- new one. Harmless when run standalone, where STATE is simply nil.
if STATE and STATE.onCleanup then STATE.onCleanup(cleanup) end
genv.esp = {
    gui     = gui,
    config  = CFG,
    tuning  = TUNING,
    tracked = tracked,
    add      = function(x, cat) return track(x, cat or 'Object', true) end,
    addPoint = addPoint,
    loadPlaces = loadPlaces,
    remove  = untrack,
    rescan  = rescan,
    destroy = cleanup,
    farm    = FARM,
    farmState = FARM_STATE,
    -- takes an Instance or a plain name; either way what is stored is the name
    setTarget = function(x)
        farmWant = (typeof(x) == 'Instance' and x.Name)
            or (type(x) == 'string' and x)
            or nil
        farmKey = nil
        if farmEngaged then farmDisengage(true) end
        guard(farmTick)
    end,
    setHome   = function(cf) farmHome = cf end,
    lootHeld  = function() return LOOT.hold ~= nil end,
    loot      = LOOT,
    raid      = RAID,
    cards     = CARDS,
    raidState = RAID_STATE,
    quest     = FARM.quest,
    move      = MOVE,
    moveState = MOVE_STATE,
    conf      = {
        path     = CONF.path,
        defaults = DEFAULTS,
        dump     = confDump,
        save     = confSave,
        read     = confRead,
        -- both phases, for a reload from disk at runtime
        apply    = function(d)
            confValues(d)
            return confSwitches(d)
        end,
        reload   = function()
            local d = confRead()
            if not d then return false end
            confSaved = d
            confValues(d)
            confSwitches(d)
            return true
        end,
    },
    tp        = TP,
    tpTo      = tpGo,
    tpPoint   = tpPoint,
    tpFind    = tpFind,
    tpTarget  = function(x) tpKey = x end,
}

-- the esp has to survive a dead request or a library change
local okUi, res = pcall(buildUi)
if okUi then genv.esp.ui = res end
