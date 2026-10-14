--[[ Oc1DvHUB × MOURGE SHIFT HALLOWEEN EDITION — FINAL V4
     Walk Natural: Noclip + Smooth Vertical (auto naik/turun ke target)
     Collect V1 & V2, Pumpkin, ESP, Event, Misc, Tema, Credits
     Full map scan, unlimited distance, anti-detect
     Semua toggle default OFF
]]
print("[Oc1DvHUB] Loading FINAL V4...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local MPS = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local LP = Players.LocalPlayer

local CONFIG = {
    DISCORD = "https://discord.gg/wtVKkDvyz",
    LOGO = "rbxassetid://78682047053280",
    SND = "rbxassetid://7405483764",
}

local BG_LIST = {
    {name = "HALLOWEEN", id = "rbxassetid://71753681160488"},
    {name = "UTAMA", id = "rbxassetid://124159830401488"},
    {name = "LANSKYP", id = "rbxassetid://70693066629625"},
    {name = "LUFFY", id = "rbxassetid://77692656015127"},
    {name = "TEXT", id = "rbxassetid://136619070579232"},
    {name = "MBG BLUE", id = "rbxassetid://75442560708193"},
}

local C = {
    Pri = Color3.fromRGB(255, 145, 80),
    PriDark = Color3.fromRGB(210, 110, 55),
    Bg = Color3.fromRGB(24, 24, 28),
    Panel = Color3.fromRGB(34, 34, 40),
    Card = Color3.fromRGB(44, 44, 52),
    Txt = Color3.fromRGB(240, 240, 245),
    Dim = Color3.fromRGB(150, 150, 160),
    Red = Color3.fromRGB(255, 100, 110),
    Grn = Color3.fromRGB(110, 220, 140),
    Yel = Color3.fromRGB(255, 210, 110),
    Cyn = Color3.fromRGB(110, 200, 245),
    Pur = Color3.fromRGB(191, 90, 242),
    Orng = Color3.fromRGB(255, 165, 0),
}

local S = {
    StartTime = os.time(), GameName = "Loading...",
    curBG = 1, selBG = 1, HueColor = C.Pri,
    BGBrightness = 0.55, MiniMode = true,
}

local colorEls = {}
local function track(obj, prop) table.insert(colorEls, {obj = obj, prop = prop}) end
local function applyColor(newC)
    C.Pri = newC
    C.PriDark = Color3.new(newC.R*0.82, newC.G*0.82, newC.B*0.82)
    for _, e in ipairs(colorEls) do
        if e.obj and e.obj.Parent then
            pcall(function() e.obj[e.prop] = newC end)
        end
    end
end

local searchables = {}
local function trackSearch(frame, text)
    frame:SetAttribute("SearchText", string.lower(text))
    table.insert(searchables, frame)
end

local pg = LP:WaitForChild("PlayerGui", 10) or game:GetService("CoreGui")
local old = pg:FindFirstChild("Oc1DvHUB_UI")
if old then old:Destroy() end

task.spawn(function()
    local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
    S.GameName = (ok and info and info.Name) or "Unknown"
end)

local function sfx()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = CONFIG.SND; s.Volume = 0.25; s.Parent = pg
        s:Play(); Debris:AddItem(s, 2)
    end)
end

local NotifyUser, Log

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local State = {
    CollectV1Enabled = false,
    CollectMode = "walk",
    CollectInterval = 2,
    WalkSpeed = 32,

    CollectV2Enabled = false,
    CollectV2Mode = "path",
    CollectV2Interval = 2,
    CollectV2WalkSpeed = 32,
    CollectV2Timeout = 120,

    PumpkinEnabled = false,
    PumpkinInterval = 2,

    -- WALK NATURAL
    WalkNaturalEnabled = false,
    WalkVerticalSpeed = 30,
    WalkVerticalSmoothness = 0.05,
    WalkHorizontalRange = 25,

    ItemESP = false, PumpkinESP = false, ReaperESP = false, GhostESP = false,
    ShowDistance = false,

    FirePrompt = false, NoDelay = false,

    AntiAFK = false, AntiAFKInterval = 90,

    GodMode = false, DesyncRadius = 30, DesyncTPDistance = 500,

    Invisible = false, Noclip = false,

    Fly = false, FlySpeed = 80, FlyKey = Enum.KeyCode.F,

    WalkSpeedEnabled = false, WalkSpeedValue = 16,
}

local StatsData = {
    ItemsFound = 0, ItemsCollected = 0, ItemsSpawned = 0,
    PumpkinsFound = 0, PumpkinsCollected = 0, PumpkinsSpawned = 0,
    ReapersFound = 0, GhostsFound = 0, AFKTicks = 0, DesyncCount = 0,
    VerticalSteps = 0,
}

local itemCache, pumpkinCache, reaperCache, ghostCache = {}, {}, {}, {}
local countedItems, countedPumpkins = {}, {}
local lastSeenItems, lastSeenPumpkins = {}, {}

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════
local function getHRP()
    local c = LP.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function hasCharacter()
    return LP.Character and LP.Character.Parent and getHRP() ~= nil
end
local function safeTP(pos)
    if not hasCharacter() then return false end
    pcall(function() getHRP().CFrame = CFrame.new(pos) end)
    return true
end

local function doAntiAFK()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        StatsData.AFKTicks += 1
    end)
end

task.spawn(function()
    while true do
        task.wait(State.AntiAFKInterval)
        if State.AntiAFK then doAntiAFK() end
    end
end)
pcall(function()
    LP.Idled:Connect(function() if State.AntiAFK then doAntiAFK() end end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then
                    if State.Invisible then
                        p.LocalTransparencyModifier = 1
                        p.Transparency = 1
                    else
                        p.LocalTransparencyModifier = 0
                        p.Transparency = 0
                    end
                    if State.Noclip or State.Invisible or State.Fly or State.WalkNaturalEnabled then
                        p.CanCollide = false
                    else
                        p.CanCollide = true
                    end
                end
            end
        end
    end
end)

-- FLY
local flyBV, flyBG, flyConn
local function stopFly()
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
end
local function startFly()
    stopFly()
    if not hasCharacter() then return end
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 9e4; flyBG.D = 500; flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    flyConn = RunService.RenderStepped:Connect(function()
        if not State.Fly or not hasCharacter() then return end
        local h, hm = getHRP(), getHum()
        if not h or not hm then return end
        local dir = Vector3.zero
        if hm.MoveDirection.Magnitude > 0 then dir = hm.MoveDirection end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        flyBV.Velocity = dir * State.FlySpeed
        flyBG.CFrame = workspace.CurrentCamera.CFrame
    end)
end
UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == State.FlyKey then
        State.Fly = not State.Fly
        if State.Fly then startFly() else stopFly() end
        NotifyUser("Fly", State.Fly and "ON" or "OFF", State.Fly and "success" or "info")
    end
end)
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if State.Fly then startFly() end
end)

-- ANTI-DETECT
local AntiDetect = {
    Enabled = true,
    Running = false,
    ScriptsDisabled = 0,
    KicksBlocked = 0,
    RemotesBlocked = 0,
    MovementBlocked = 0,
    MaxTPDistance = 80,
    MaxSpeed = 100,
    lastPos = nil,
    lastTime = nil,
}

local DETECT_KEYWORDS = {
    "detect","anticheat","anti_cheat","ac_","acscript","log","report",
    "flag","ban","kick","admin","cheat","hack","exploit","suspicious",
    "monitor","watch","sentry","guardian","speedcheck","positioncheck",
}
local function isDetectionName(name)
    local low = tostring(name):lower()
    for _, kw in ipairs(DETECT_KEYWORDS) do
        if low:find(kw, 1, true) then return true end
    end
    return false
end

pcall(function()
    if type(hookfunction) == "function" then
        hookfunction(LP.Kick, function(self, ...)
            if self == LP and AntiDetect.Enabled then
                AntiDetect.KicksBlocked += 1
                return
            end
        end)
    end
end)

pcall(function()
    if type(hookmetamethod) == "function" then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if AntiDetect.Enabled then
                if method == "Kick" and self == LP then
                    AntiDetect.KicksBlocked += 1
                    return
                end
                if method == "FireServer" or method == "InvokeServer" then
                    local ok, name = pcall(function() return self:GetFullName() end)
                    if ok and isDetectionName(name) then
                        AntiDetect.RemotesBlocked += 1
                        return
                    end
                end
            end
            return old(self, ...)
        end)
    end
end)

local function disableDetectionScripts(parent)
    if not AntiDetect.Enabled then return end
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("LocalScript") and isDetectionName(obj.Name) then
            pcall(function()
                obj.Disabled = true
                AntiDetect.ScriptsDisabled += 1
            end)
        end
    end
end

task.spawn(function()
    while true do
        task.wait(3)
        if AntiDetect.Enabled then
            pcall(function() disableDetectionScripts(LP) end)
            pcall(function() disableDetectionScripts(pg) end)
        end
    end
end)

LP.DescendantAdded:Connect(function(obj)
    if AntiDetect.Enabled and obj:IsA("LocalScript") and isDetectionName(obj.Name) then
        task.wait(0.1)
        pcall(function() obj.Disabled = true end)
    end
end)

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not AntiDetect.Enabled or not AntiDetect.Running or not hasCharacter() then
            AntiDetect.lastPos = nil
            AntiDetect.lastTime = nil
            continue
        end
        local hrp = getHRP()
        if not hrp then continue end
        local now = tick()
        local pos = hrp.Position
        if AntiDetect.lastPos and AntiDetect.lastTime then
            local deltaDist = (pos - AntiDetect.lastPos).Magnitude
            local deltaTime = now - AntiDetect.lastTime
            local speed = deltaTime > 0 and (deltaDist / deltaTime) or 0
            if deltaDist > AntiDetect.MaxTPDistance then
                AntiDetect.MovementBlocked += 1
                pcall(function() hrp.CFrame = CFrame.new(AntiDetect.lastPos) end)
            elseif not State.Fly and speed > AntiDetect.MaxSpeed then
                AntiDetect.MovementBlocked += 1
                pcall(function() hrp.CFrame = CFrame.new(AntiDetect.lastPos) end)
            end
        end
        AntiDetect.lastPos = hrp.Position
        AntiDetect.lastTime = now
    end
end)

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(pg) end
    if protect_gui then protect_gui(pg) end
end)

-- ═══════════════════════════════════════════════════════════
-- KEYWORDS + SCAN
-- ═══════════════════════════════════════════════════════════
local ITEM_KEYWORDS = {
    "trickortreatitem","trickortreat","trick_or_treat","trick","treat",
    "candy","candies","sweet","halloweenitem","eventitem","collectitem",
    "pickupitem","trickortreatltem",
}
local ITEM_BLACKLIST = {
    "prompt","ui","gui","shop","sign","spawner","spawn","effect","sound",
    "particle","highlight","button","text","label","screen","folder",
}
local PUMPKIN_KEYWORDS = {
    "spookypumpkin","spooky_pumpkin","spooky pumpkin","pumpkin","pumkin",
    "jacko","jackolantern","jack_o_lantern","halloweenpumpkin","pumpkinitem","pumpkin_item",
}
local PUMPKIN_BLACKLIST = {
    "prompt","ui","gui","shop","sign","spawner","spawn","effect","sound",
    "particle","highlight","button","text","label","screen","folder","decal",
    "texture","mesh","light","beam","trail",
}

local function checkName(name, keywords, blacklist)
    local low = name:lower()
    for _, bl in ipairs(blacklist) do
        if low:find(bl, 1, true) then return false end
    end
    for _, kw in ipairs(keywords) do
        if low:find(kw, 1, true) then return true end
    end
    return false
end

local function extractPart(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") or obj:IsA("MeshPart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChildWhichIsA("MeshPart")
    end
    if obj:IsA("Tool") then return obj:FindFirstChildWhichIsA("BasePart") end
    if obj:IsA("Folder") then return obj:FindFirstChildWhichIsA("BasePart", true) end
    return nil
end

local function scanByKeyword(keywords, blacklist)
    local found, seen = {}, {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not obj.Parent then continue end
            if seen[obj] then continue end
            if checkName(obj.Name, keywords, blacklist) then
                local part = extractPart(obj)
                if part and part.Parent then
                    local root = part:FindFirstAncestorOfClass("Model") or obj
                    if not seen[root] then
                        seen[root] = true
                        table.insert(found, {model = root, part = part, name = obj.Name, source = obj})
                    end
                end
            end
        end
    end)
    return found
end

local function scanItems() return scanByKeyword(ITEM_KEYWORDS, ITEM_BLACKLIST) end
local function scanPumpkins() return scanByKeyword(PUMPKIN_KEYWORDS, PUMPKIN_BLACKLIST) end

local function scanReapers()
    local found = {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local n = obj.Name:lower()
                if (n:find("reaper") or n:find("death") or n:find("grim"))
                   and not Players:GetPlayerFromCharacter(obj) then
                    local part = extractPart(obj)
                    if part then table.insert(found, {model = obj, part = part}) end
                end
            end
        end
    end)
    return found
end

local GHOST_KEYWORDS = {"ghost","hantu","spirit","phantom","wraith","soul","specter","spectre","haunt","poltergeist","banshee","revenant","demon","devil","monster","zombie","skeleton","skull","shadow","nightmare","undead","curse"}
local GHOST_BLACKLIST = {"ghostbuster","ghost_shop","ghostsign","ghost_ui","soulmate","soul_shop","console","shining","souvenir"}

local function scanGhosts()
    local found, seen = {}, {}
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
                local n = obj.Name:lower()
                local bl = false
                for _, b in ipairs(GHOST_BLACKLIST) do
                    if n:find(b, 1, true) then bl = true; break end
                end
                if not bl then
                    for _, kw in ipairs(GHOST_KEYWORDS) do
                        if n == kw or n:find("^" .. kw .. "_") or n:find("^" .. kw .. " ")
                           or n:find(" " .. kw .. " ") or n:find(" " .. kw .. "$") then
                            local hum = obj:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and not seen[obj] then
                                seen[obj] = true
                                local part = extractPart(obj)
                                if part then table.insert(found, {model = obj, part = part, name = obj.Name}) end
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
    return found
end

-- ═══════════════════════════════════════════════════════════
-- WALK NATURAL: Smooth Vertical (naik/turun ke target)
-- ═══════════════════════════════════════════════════════════
local lastVertStep = 0
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not State.WalkNaturalEnabled or not hasCharacter() then continue end
        local hum = getHum()
        local hrp = getHRP()
        if not hum or not hrp then continue end

        -- Noclip
        for _, p in ipairs(LP.Character:GetChildren()) do
            if p:IsA("BasePart") and p.CanCollide then
                p.CanCollide = false
            end
        end

        local now = tick()
        if now - lastVertStep < State.WalkVerticalSmoothness then continue end
        lastVertStep = now

        -- Kumpulkan target
        local checkList = {}
        if State.CollectV1Enabled or State.CollectV2Enabled then
            for _, d in ipairs(scanItems()) do table.insert(checkList, d) end
        end
        if State.PumpkinEnabled then
            for _, d in ipairs(scanPumpkins()) do table.insert(checkList, d) end
        end

        -- Target terdekat
        local nearest, nearestDist = nil, math.huge
        for _, d in ipairs(checkList) do
            if d.part and d.part.Parent then
                local dist = (d.part.Position - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = d
                end
            end
        end
        if not nearest then continue end

        local targetPos = nearest.part.Position
        local myPos = hrp.Position
        local relY = targetPos.Y - myPos.Y
        local dx = targetPos.X - myPos.X
        local dz = targetPos.Z - myPos.Z
        local distXZ = math.sqrt(dx*dx + dz*dz)

        -- Kalau target dalam jangkauan horizontal dan beda Y signifikan
        if distXZ < State.WalkHorizontalRange and math.abs(relY) > 1 then
            local step = State.WalkVerticalSpeed * State.WalkVerticalSmoothness
            if step > math.abs(relY) then step = math.abs(relY) end
            local dir = relY > 0 and 1 or -1
            pcall(function()
                hrp.CFrame = hrp.CFrame + Vector3.new(0, step * dir, 0)
            end)
            StatsData.VerticalSteps += 1
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- WALK TO TARGET (pathfinding + vertical smooth kalau perlu)
-- ═══════════════════════════════════════════════════════════
local function walkToTarget(targetPart, timeout)
    timeout = timeout or 120
    if not hasCharacter() or not targetPart or not targetPart.Parent then return false end
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return false end
    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = State.WalkSpeed
    local success = false
    local startTime = tick()

    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5,
        AgentCanJump = true, AgentCanClimb = true,
        WaypointSpacing = 8,
    })
    local ok = pcall(function()
        path:ComputeAsync(hrp.Position, targetPart.Position)
    end)

    if ok and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in ipairs(waypoints) do
            if tick() - startTime > timeout then break end
            if not hasCharacter() or not targetPart.Parent then break end
            local h = getHRP()
            if not h then break end
            if wp.Action == Enum.PathWaypointAction.Jump then
                pcall(function() hum.Jump = true end)
                task.wait(0.2)
            end
            pcall(function() hum:MoveTo(wp.Position) end)
            local wpStart = tick()
            while tick() - wpStart < 5 do
                if tick() - startTime > timeout then break end
                if not hasCharacter() then break end
                local h2 = getHRP()
                if not h2 then break end
                if (h2.Position - wp.Position).Magnitude < 3.5 then break end
                task.wait(0.08)
            end
            task.wait(0.03)
        end
        if hasCharacter() and targetPart.Parent then
            success = (getHRP().Position - targetPart.Position).Magnitude < 12
        end
    end

    if not success then
        local fbStart = tick()
        local lastProgressTime = tick()
        local lastDist = (getHRP().Position - targetPart.Position).Magnitude
        local stuckCount = 0
        while tick() - fbStart < timeout do
            if not hasCharacter() or not targetPart.Parent then break end
            local h = getHRP()
            if not h then break end
            local dir = targetPart.Position - h.Position
            local dist = dir.Magnitude
            if dist < 5 then success = true; break end

            local now = tick()
            if math.abs(lastDist - dist) < 0.8 then
                if now - lastProgressTime > 2.5 then
                    pcall(function() hum.Jump = true end)
                    stuckCount += 1
                    lastProgressTime = now
                    if stuckCount >= 5 then
                        local sideStep = Vector3.new(dir.Unit.Z, 0, -dir.Unit.X) * 10
                        pcall(function() hum:MoveTo(h.Position + sideStep) end)
                        task.wait(0.6)
                        stuckCount = 0
                    end
                end
            else
                lastProgressTime = now
                lastDist = dist
            end
            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            if flatDir.Magnitude > 0 then
                pcall(function() hum:MoveTo(h.Position + flatDir.Unit * math.min(dist, 12)) end)
            end
            task.wait(0.1)
        end
    end

    if hasCharacter() then pcall(function() hum:MoveTo(getHRP().Position) end) end
    hum.WalkSpeed = oldSpeed
    return success
end

-- ═══════════════════════════════════════════════════════════
-- V2 METHODS
-- ═══════════════════════════════════════════════════════════
local function moveModeTarget(targetPart, timeout)
    timeout = timeout or State.CollectV2Timeout
    if not hasCharacter() or not targetPart or not targetPart.Parent then return false end
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return false end
    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = State.CollectV2WalkSpeed
    local startTime = tick()
    local lastProgressTime = tick()
    local lastDist = (hrp.Position - targetPart.Position).Magnitude
    local success = false
    while tick() - startTime < timeout do
        if not hasCharacter() or not targetPart.Parent then break end
        local h = getHRP()
        if not h then break end
        local diff = targetPart.Position - h.Position
        local dist = diff.Magnitude
        if dist < 5 then success = true; break end
        local dir = Vector3.new(diff.X, 0, diff.Z)
        if dir.Magnitude > 0 then
            pcall(function() hum:Move(dir.Unit) end)
        end
        local now = tick()
        if math.abs(lastDist - dist) < 0.8 then
            if now - lastProgressTime > 2.5 then
                pcall(function() hum.Jump = true end)
                lastProgressTime = now
            end
        else
            lastProgressTime = now
            lastDist = dist
        end
        task.wait(0.05)
    end
    pcall(function() hum:Move(Vector3.zero) end)
    hum.WalkSpeed = oldSpeed
    return success
end

local function alignModeTarget(targetPart, timeout)
    timeout = timeout or State.CollectV2Timeout
    if not hasCharacter() or not targetPart or not targetPart.Parent then return false end
    local hrp = getHRP()
    if not hrp then return false end
    local att = Instance.new("Attachment")
    att.Parent = hrp
    local align = Instance.new("AlignPosition")
    align.Attachment0 = att
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Position = targetPart.Position
    align.MaxForce = 5e5
    align.Responsiveness = 20
    align.Parent = hrp
    local vel = Instance.new("LinearVelocity")
    vel.Attachment0 = att
    vel.MaxForce = 5e5
    vel.VectorVelocity = Vector3.zero
    vel.RelativeTo = Enum.ActuatorRelativeTo.World
    vel.Parent = hrp
    local success = false
    local startTime = tick()
    while tick() - startTime < timeout do
        if not hasCharacter() or not targetPart.Parent then break end
        local h = getHRP()
        if not h then break end
        local diff = targetPart.Position - h.Position
        if diff.Magnitude < 4 then success = true; break end
        align.Position = targetPart.Position
        if diff.Magnitude > 0 then
            vel.VectorVelocity = diff.Unit * State.CollectV2WalkSpeed
        end
        task.wait(0.05)
    end
    pcall(function() align:Destroy() end)
    pcall(function() vel:Destroy() end)
    pcall(function() att:Destroy() end)
    return success
end

local function walkPointModeTarget(targetPart, timeout)
    timeout = timeout or State.CollectV2Timeout
    if not hasCharacter() or not targetPart or not targetPart.Parent then return false end
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return false end
    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = State.CollectV2WalkSpeed
    local startTime = tick()
    local success = false
    while tick() - startTime < timeout do
        if not hasCharacter() or not targetPart.Parent then break end
        local h = getHRP()
        if not h then break end
        if (targetPart.Position - h.Position).Magnitude < 4 then success = true; break end
        pcall(function() hum.WalkToPoint = targetPart.Position end)
        task.wait(0.08)
    end
    hum.WalkSpeed = oldSpeed
    return success
end

local function walkPartModeTarget(targetPart, timeout)
    timeout = timeout or State.CollectV2Timeout
    if not hasCharacter() or not targetPart or not targetPart.Parent then return false end
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then return false end
    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = State.CollectV2WalkSpeed
    local startTime = tick()
    local success = false
    pcall(function() hum.WalkToPart = targetPart end)
    while tick() - startTime < timeout do
        if not hasCharacter() or not targetPart.Parent then break end
        local h = getHRP()
        if not h then break end
        if (targetPart.Position - h.Position).Magnitude < 4 then success = true; break end
        task.wait(0.1)
    end
    pcall(function() hum.WalkToPart = nil end)
    hum.WalkSpeed = oldSpeed
    return success
end

local function pathModeTarget(targetPart, timeout)
    return walkToTarget(targetPart, timeout or State.CollectV2Timeout)
end

-- MODE DISPATCHER
local function moveV1(part, dist)
    if State.WalkNaturalEnabled then
        return walkToTarget(part, 120)
    end
    if dist <= 5 then return true end
    return walkToTarget(part, 120)
end

local function moveV2(part)
    if State.WalkNaturalEnabled then
        return walkToTarget(part, 120)
    end
    local mode = State.CollectV2Mode
    if mode == "move" then return moveModeTarget(part, State.CollectV2Timeout) end
    if mode == "align" then return alignModeTarget(part, State.CollectV2Timeout) end
    if mode == "walkpoint" then return walkPointModeTarget(part, State.CollectV2Timeout) end
    if mode == "walkpart" then return walkPartModeTarget(part, State.CollectV2Timeout) end
    return pathModeTarget(part, State.CollectV2Timeout)
end

-- GOD MODE
task.spawn(function()
    while true do
        task.wait(0.3)
        if State.GodMode and hasCharacter() then
            local hrp = getHRP()
            local ghosts = scanGhosts()
            local nearest, minDist = nil, math.huge
            for _, g in ipairs(ghosts) do
                local d = (g.part.Position - hrp.Position).Magnitude
                if d < minDist then minDist = d; nearest = g end
            end
            if nearest and minDist <= State.DesyncRadius then
                if getconnections then
                    pcall(function()
                        for _, obj in ipairs(nearest.model:GetChildren()) do
                            if obj:IsA("BasePart") then
                                for _, conn in ipairs(getconnections(obj.Touched)) do
                                    if conn.Disable then conn:Disable() end
                                end
                            end
                        end
                    end)
                end
                local dir = (hrp.Position - nearest.part.Position)
                if dir.Magnitude > 0 then dir = dir.Unit else dir = Vector3.new(1,0,0) end
                safeTP(nearest.part.Position + dir * State.DesyncTPDistance)
                StatsData.DesyncCount += 1
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if State.WalkSpeedEnabled then
            local hum = getHum()
            if hum and math.abs(hum.WalkSpeed - State.WalkSpeedValue) > 0.5 then
                hum.WalkSpeed = State.WalkSpeedValue
            end
        end
    end
end)

local function forceNoDelayPrompt(obj)
    if obj:IsA("ProximityPrompt") and State.NoDelay then
        pcall(function()
            obj.HoldDuration = 0
            obj.MaxActivationDistance = 9e9
            obj.Enabled = true
        end)
    end
end
pcall(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        forceNoDelayPrompt(obj)
    end
end)
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") and State.NoDelay then
        task.wait(0.05)
        forceNoDelayPrompt(obj)
    end
end)

local function collectItem(data)
    if not data or not data.part or not data.part.Parent then return false end
    local part, model = data.part, data.model
    local success = false
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then prompt = part:FindFirstChildWhichIsA("ProximityPrompt") end
    if prompt then
        pcall(function()
            prompt.MaxActivationDistance = 9e9
            prompt.Enabled = true
            if State.NoDelay then prompt.HoldDuration = 0 end
        end)
        if State.FirePrompt and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt, 0) success = true end)
        end
    end
    local cd = model:FindFirstChildWhichIsA("ClickDetector", true)
    if not cd and part then cd = part:FindFirstChildWhichIsA("ClickDetector") end
    if cd and fireclickdetector then
        pcall(function() fireclickdetector(cd) success = true end)
    end
    local hrp = getHRP()
    if hrp and firetouchinterest then
        pcall(function()
            firetouchinterest(hrp, part, 0)
            task.wait(0.02)
            firetouchinterest(hrp, part, 1)
            success = true
        end)
    end
    return success
end

-- ESP
local function createHL(model, color, name)
    if not model or not model.Parent then return end
    local e = model:FindFirstChild(name)
    if e then e:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = name
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = model
end

local function createTag(part, label, color, tagName)
    if not part or not part.Parent then return end
    local e = part:FindFirstChild(tagName)
    if e then e:Destroy() end
    local bb = Instance.new("BillboardGui")
    bb.Name = tagName
    bb.Size = UDim2.fromOffset(200, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    local lbl = Instance.new("TextLabel", bb)
    lbl.Name = "NameLbl"
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    local dLbl = Instance.new("TextLabel", bb)
    dLbl.Name = "DistLbl"
    dLbl.Size = UDim2.new(1, 0, 0, 16)
    dLbl.Position = UDim2.new(0, 0, 0, 22)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = "---"
    dLbl.TextColor3 = Color3.new(1, 1, 1)
    dLbl.TextStrokeTransparency = 0
    dLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    dLbl.TextSize = 12
    dLbl.Font = Enum.Font.GothamBold
    bb.Parent = part
end

local function removeESP(model)
    if not model then return end
    for _, c in ipairs(model:GetChildren()) do
        if c.Name:find("ESP_HL") then c:Destroy() end
    end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            for _, t in ipairs(p:GetChildren()) do
                if t.Name:find("ESP_Tag") then t:Destroy() end
            end
        end
    end
end

-- AUTO COLLECT V1
task.spawn(function()
    while true do
        task.wait(State.CollectInterval)
        if State.CollectV1Enabled and hasCharacter() then
            AntiDetect.Running = true
            local items = scanItems()
            if #items > 0 then
                local hrp = getHRP()
                for _, d in ipairs(items) do
                    d.dist = (d.part.Position - hrp.Position).Magnitude
                end
                table.sort(items, function(a, b) return a.dist < b.dist end)
                local collected = 0
                for _, d in ipairs(items) do
                    if not hasCharacter() then break end
                    if collected >= 10 then break end
                    moveV1(d.part, d.dist)
                    if collectItem(d) then
                        if not countedItems[d.model] then
                            countedItems[d.model] = true
                            StatsData.ItemsCollected += 1
                            NotifyUser("V1", "Collected! (" .. math.floor(d.dist) .. " studs)", "success")
                        end
                        collected += 1
                        task.wait(0.2)
                    end
                end
            end
            AntiDetect.Running = false
        end
    end
end)

-- AUTO COLLECT V2
task.spawn(function()
    while true do
        task.wait(State.CollectV2Interval)
        if State.CollectV2Enabled and hasCharacter() then
            AntiDetect.Running = true
            local items = scanItems()
            if #items > 0 then
                local hrp = getHRP()
                for _, d in ipairs(items) do
                    d.dist = (d.part.Position - hrp.Position).Magnitude
                end
                table.sort(items, function(a, b) return a.dist < b.dist end)
                local collected = 0
                for _, d in ipairs(items) do
                    if not hasCharacter() then break end
                    if collected >= 10 then break end
                    moveV2(d.part)
                    if collectItem(d) then
                        if not countedItems[d.model] then
                            countedItems[d.model] = true
                            StatsData.ItemsCollected += 1
                            NotifyUser("V2", "Collected! (" .. math.floor(d.dist) .. " studs)", "success")
                        end
                        collected += 1
                        task.wait(0.2)
                    end
                end
            end
            AntiDetect.Running = false
        end
    end
end)

-- PUMPKIN
task.spawn(function()
    while true do
        task.wait(State.PumpkinInterval)
        if State.PumpkinEnabled and hasCharacter() then
            AntiDetect.Running = true
            local pumpkins = scanPumpkins()
            if #pumpkins > 0 then
                local hrp = getHRP()
                for _, d in ipairs(pumpkins) do
                    d.dist = (d.part.Position - hrp.Position).Magnitude
                end
                table.sort(pumpkins, function(a, b) return a.dist < b.dist end)
                local collected = 0
                for _, d in ipairs(pumpkins) do
                    if not hasCharacter() then break end
                    if collected >= 10 then break end
                    if State.WalkNaturalEnabled or State.CollectV2Enabled then
                        moveV2(d.part)
                    else
                        moveV1(d.part, d.dist)
                    end
                    if collectItem(d) then
                        if not countedPumpkins[d.model] then
                            countedPumpkins[d.model] = true
                            StatsData.PumpkinsCollected += 1
                            NotifyUser("Pumpkin", "Collected! (" .. math.floor(d.dist) .. " studs)", "success")
                        end
                        collected += 1
                        task.wait(0.2)
                    end
                end
            end
            AntiDetect.Running = false
        end
    end
end)

-- SPAWN COUNTER
task.spawn(function()
    while true do
        task.wait(3)
        local items = scanItems()
        StatsData.ItemsFound = #items
        for _, d in ipairs(items) do
            if not lastSeenItems[d.model] then
                lastSeenItems[d.model] = true
                StatsData.ItemsSpawned += 1
            end
        end
        local curI = {}
        for _, d in ipairs(items) do curI[d.model] = true end
        for m in pairs(lastSeenItems) do
            if not curI[m] then lastSeenItems[m] = nil end
        end
        for m in pairs(countedItems) do
            if not m.Parent then countedItems[m] = nil end
        end
        local pk = scanPumpkins()
        StatsData.PumpkinsFound = #pk
        for _, d in ipairs(pk) do
            if not lastSeenPumpkins[d.model] then
                lastSeenPumpkins[d.model] = true
                StatsData.PumpkinsSpawned += 1
            end
        end
        local curP = {}
        for _, d in ipairs(pk) do curP[d.model] = true end
        for m in pairs(lastSeenPumpkins) do
            if not curP[m] then lastSeenPumpkins[m] = nil end
        end
        for m in pairs(countedPumpkins) do
            if not m.Parent then countedPumpkins[m] = nil end
        end
    end
end)

-- ESP LOOP
task.spawn(function()
    while true do
        task.wait(1.5)
        if State.ItemESP then
            local items = scanItems()
            local cur = {}
            for _, d in ipairs(items) do cur[d.model] = d end
            for m in pairs(itemCache) do
                if not cur[m] or not m.Parent then removeESP(m); itemCache[m] = nil end
            end
            for m, d in pairs(cur) do
                if not itemCache[m] then
                    createHL(m, C.Pri, "ItemESP_HL")
                    createTag(d.part, m.Name, C.Pri, "ItemESP_Tag")
                    itemCache[m] = d
                end
            end
        elseif next(itemCache) then
            for m in pairs(itemCache) do removeESP(m) end
            itemCache = {}
        end
        if State.PumpkinESP then
            local pk = scanPumpkins()
            local cur = {}
            for _, d in ipairs(pk) do cur[d.model] = d end
            for m in pairs(pumpkinCache) do
                if not cur[m] or not m.Parent then removeESP(m); pumpkinCache[m] = nil end
            end
            for m, d in pairs(cur) do
                if not pumpkinCache[m] then
                    createHL(m, C.Orng, "PumpkinESP_HL")
                    createTag(d.part, m.Name, C.Orng, "PumpkinESP_Tag")
                    pumpkinCache[m] = d
                end
            end
        elseif next(pumpkinCache) then
            for m in pairs(pumpkinCache) do removeESP(m) end
            pumpkinCache = {}
        end
        if State.ReaperESP then
            local rs = scanReapers()
            StatsData.ReapersFound = #rs
            local cur = {}
            for _, d in ipairs(rs) do cur[d.model] = d end
            for m in pairs(reaperCache) do
                if not cur[m] or not m.Parent then removeESP(m); reaperCache[m] = nil end
            end
            for m, d in pairs(cur) do
                if not reaperCache[m] then
                    createHL(m, C.Red, "ReaperESP_HL")
                    createTag(d.part, m.Name, C.Red, "ReaperESP_Tag")
                    reaperCache[m] = d
                end
            end
        elseif next(reaperCache) then
            for m in pairs(reaperCache) do removeESP(m) end
            reaperCache = {}
        end
        if State.GhostESP then
            local gs = scanGhosts()
            StatsData.GhostsFound = #gs
            local cur = {}
            for _, d in ipairs(gs) do cur[d.model] = d end
            for m in pairs(ghostCache) do
                if not cur[m] or not m.Parent then removeESP(m); ghostCache[m] = nil end
            end
            for m, d in pairs(cur) do
                if not ghostCache[m] then
                    createHL(m, C.Pur, "GhostESP_HL")
                    createTag(d.part, d.name, C.Pur, "GhostESP_Tag")
                    ghostCache[m] = d
                end
            end
        elseif next(ghostCache) then
            for m in pairs(ghostCache) do removeESP(m) end
            ghostCache = {}
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.7)
        if State.ShowDistance and hasCharacter() then
            local hrp = getHRP()
            local function update(cache, tagName, baseColor)
                for m, d in pairs(cache) do
                    if d.part and d.part.Parent then
                        local dist = (d.part.Position - hrp.Position).Magnitude
                        local bb = d.part:FindFirstChild(tagName)
                        if bb then
                            local dl = bb:FindFirstChild("DistLbl")
                            if dl then
                                local c = baseColor
                                if dist > 200 then c = C.Yel
                                elseif dist > 500 then c = C.Red end
                                dl.Text = math.floor(dist) .. " studs"
                                dl.TextColor3 = c
                            end
                        end
                    end
                end
            end
            update(itemCache, "ItemESP_Tag", C.Grn)
            update(pumpkinCache, "PumpkinESP_Tag", C.Orng)
            update(reaperCache, "ReaperESP_Tag", C.Red)
            update(ghostCache, "GhostESP_Tag", C.Cyn)
        end
    end
end)

local function getEventInfo()
    local t = os.date("*t")
    local hour, min, sec = t.hour, t.min, t.sec
    local currentMin = hour * 60 + min
    local nextEventMin = (min < 30) and (hour * 60 + 30) or ((hour + 1) * 60)
    local secondsToEvent = (nextEventMin - currentMin) * 60 - sec
    local prevEventMin = (min < 30) and (hour * 60) or (hour * 60 + 30)
    local secondsSinceEvent = (currentMin - prevEventMin) * 60 + sec
    local cdH = math.floor(secondsToEvent / 3600)
    local cdM = math.floor((secondsToEvent % 3600) / 60)
    local cdS = secondsToEvent % 60
    local nextH = math.floor(nextEventMin / 60) % 24
    local nextM = nextEventMin % 60
    local nextH12 = nextH % 12; if nextH12 == 0 then nextH12 = 12 end
    local ap = nextH >= 12 and "PM" or "AM"
    return {
        countdownStr = string.format("%02d:%02d:%02d", cdH, cdM, cdS),
        nextEventStr = string.format("%02d:%02d %s", nextH12, nextM, ap),
        isEventActive = secondsSinceEvent <= 60,
        percent = 1 - (secondsToEvent / (30 * 60)),
    }
end

-- ═══════════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name = "Oc1DvHUB_UI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = pg

local NotifyContainer = Instance.new("Frame")
NotifyContainer.Size = UDim2.new(0, 300, 0, 400)
NotifyContainer.Position = UDim2.new(1, -310, 1, -410)
NotifyContainer.BackgroundTransparency = 1
NotifyContainer.ZIndex = 490
NotifyContainer.Parent = SG
local NotifyLayout = Instance.new("UIListLayout", NotifyContainer)
NotifyLayout.FillDirection = Enum.FillDirection.Vertical
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.Padding = UDim.new(0, 6)

NotifyUser = function(title, msg, tp)
    tp = tp or "info"
    local colors = {success=C.Grn, error=C.Red, warn=C.Yel, info=C.Cyn}
    local iconTxt = {success="OK", error="X", warn="!", info="i"}
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 290, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(22,22,28)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.ZIndex = 500
    card.Parent = NotifyContainer
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = colors[tp] or C.Pri
    stroke.Thickness = 1.5; stroke.Transparency = 0.2; stroke.Parent = card
    local accent = Instance.new("Frame", card)
    accent.Size = UDim2.new(0, 4, 1, -8); accent.Position = UDim2.new(0, 4, 0, 4)
    accent.BackgroundColor3 = colors[tp] or C.Pri
    accent.BorderSizePixel = 0; accent.ZIndex = 501
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1,0)
    local iconBox = Instance.new("Frame", card)
    iconBox.Size = UDim2.new(0, 32, 0, 32); iconBox.Position = UDim2.new(0, 16, 0.5, -16)
    iconBox.BackgroundColor3 = colors[tp] or C.Pri
    iconBox.BackgroundTransparency = 0.15; iconBox.BorderSizePixel = 0; iconBox.ZIndex = 501
    Instance.new("UICorner", iconBox).CornerRadius = UDim.new(1,0)
    local icon = Instance.new("TextLabel", iconBox)
    icon.Size = UDim2.new(1,0,1,0); icon.BackgroundTransparency = 1
    icon.Text = iconTxt[tp] or "i"; icon.TextColor3 = Color3.fromRGB(20,20,20)
    icon.TextSize = 16; icon.Font = Enum.Font.GothamBold; icon.ZIndex = 502
    local titleL = Instance.new("TextLabel", card)
    titleL.Size = UDim2.new(1, -64, 0, 20); titleL.Position = UDim2.new(0, 56, 0, 8)
    titleL.BackgroundTransparency = 1; titleL.Text = title
    titleL.TextColor3 = colors[tp] or C.Pri; titleL.TextSize = 14
    titleL.Font = Enum.Font.GothamBold; titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.TextTruncate = Enum.TextTruncate.AtEnd; titleL.ZIndex = 501
    local msgL = Instance.new("TextLabel", card)
    msgL.Size = UDim2.new(1, -64, 0, 22); msgL.Position = UDim2.new(0, 56, 0, 28)
    msgL.BackgroundTransparency = 1; msgL.Text = msg
    msgL.TextColor3 = C.Txt; msgL.TextSize = 12; msgL.Font = Enum.Font.Gotham
    msgL.TextXAlignment = Enum.TextXAlignment.Left; msgL.TextWrapped = true
    msgL.TextTruncate = Enum.TextTruncate.AtEnd; msgL.ZIndex = 501
    card.Position = UDim2.new(0, 340, 0, 0)
    TS:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    task.delay(3.5, function()
        pcall(function()
            TS:Create(card, TweenInfo.new(0.3), {
                Position = UDim2.new(0, 340, 0, 0), BackgroundTransparency = 1,
            }):Play()
            task.wait(0.3)
            card:Destroy()
        end)
    end)
end

Log = function(txt, tp) print("[Oc1DvHUB]["..(tp or "info"):upper().."] "..txt) end

local TW, TH = 480, 360
local TW_NORMAL, TH_NORMAL = 560, 440

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,TW,0,TH)
Main.Position = UDim2.new(0.5,-TW/2,0.5,-TH/2)
Main.BackgroundColor3 = C.Bg
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)

local bgI = Instance.new("ImageLabel", Main)
bgI.Size = UDim2.new(1,0,1,0)
bgI.BackgroundTransparency = 1
bgI.Image = BG_LIST[S.curBG].id
bgI.ImageTransparency = 0.15
bgI.ScaleType = Enum.ScaleType.Crop
bgI.ZIndex = 0
Instance.new("UICorner", bgI).CornerRadius = UDim.new(0,16)

local ovl = Instance.new("Frame", Main)
ovl.Size = UDim2.new(1,0,1,0)
ovl.BackgroundColor3 = C.Bg
ovl.BackgroundTransparency = S.BGBrightness
ovl.BorderSizePixel = 0
ovl.ZIndex = 1
Instance.new("UICorner", ovl).CornerRadius = UDim.new(0,16)

local mst = Instance.new("UIStroke", Main)
mst.Thickness = 1.5; mst.Color = C.Pri; mst.Transparency = 0.35; mst.Parent = Main
track(mst, "Color")

local TH_H = 40
local Title = Instance.new("Frame", Main)
Title.Size = UDim2.new(1,0,0,TH_H)
Title.BackgroundColor3 = C.PriDark
Title.BackgroundTransparency = 0.8
Title.BorderSizePixel = 0
Title.ZIndex = 20
Title.Active = true
Instance.new("UICorner", Title).CornerRadius = UDim.new(0,16)
track(Title, "BackgroundColor3")

local Ttl = Instance.new("TextLabel", Title)
Ttl.Size = UDim2.new(1,-140,1,0)
Ttl.Position = UDim2.new(0,118,0,0)
Ttl.BackgroundTransparency = 1
Ttl.RichText = true
Ttl.Text = '<font color="rgb(255,255,255)">Oc1Dv</font><font color="rgb(255,145,80)">HUB</font>'
Ttl.TextSize = 14
Ttl.Font = Enum.Font.GothamBold
Ttl.TextXAlignment = Enum.TextXAlignment.Left
Ttl.ZIndex = 21

local DOT_SIZE = 12
local GrnB = Instance.new("TextButton", Title)
GrnB.Size = UDim2.new(0,DOT_SIZE,0,DOT_SIZE)
GrnB.Position = UDim2.new(1,-72,0.5,-DOT_SIZE/2)
GrnB.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
GrnB.BorderSizePixel = 0; GrnB.Text = ""; GrnB.AutoButtonColor = false; GrnB.ZIndex = 22
Instance.new("UICorner", GrnB).CornerRadius = UDim.new(1,0)

local MinB = Instance.new("TextButton", Title)
MinB.Size = UDim2.new(0,DOT_SIZE,0,DOT_SIZE)
MinB.Position = UDim2.new(1,-52,0.5,-DOT_SIZE/2)
MinB.BackgroundColor3 = Color3.fromRGB(255,200,70)
MinB.BorderSizePixel = 0; MinB.Text = ""; MinB.AutoButtonColor = false; MinB.ZIndex = 22
Instance.new("UICorner", MinB).CornerRadius = UDim.new(1,0)

local ClsB = Instance.new("TextButton", Title)
ClsB.Size = UDim2.new(0,DOT_SIZE,0,DOT_SIZE)
ClsB.Position = UDim2.new(1,-32,0.5,-DOT_SIZE/2)
ClsB.BackgroundColor3 = Color3.fromRGB(255,95,90)
ClsB.BorderSizePixel = 0; ClsB.Text = ""; ClsB.AutoButtonColor = false; ClsB.ZIndex = 22
Instance.new("UICorner", ClsB).CornerRadius = UDim.new(1,0)

local FB = Instance.new("TextButton")
FB.Size = UDim2.new(0,52,0,52)
FB.Position = UDim2.new(0,15,0,150)
FB.BackgroundColor3 = C.Bg
FB.BackgroundTransparency = 0.15
FB.BorderSizePixel = 0
FB.Text = ""
FB.AutoButtonColor = false
FB.Visible = false
FB.ZIndex = 100
FB.Parent = SG
Instance.new("UICorner", FB).CornerRadius = UDim.new(0,12)
local fbs = Instance.new("UIStroke", FB)
fbs.Color = C.Pri; fbs.Thickness = 2; fbs.Transparency = 0.3; fbs.Parent = FB
track(fbs, "Color")
local fbi = Instance.new("ImageLabel", FB)
fbi.Size = UDim2.new(1,-10,1,-10)
fbi.Position = UDim2.new(0,5,0,5)
fbi.BackgroundTransparency = 1
fbi.Image = CONFIG.LOGO
fbi.ZIndex = 101

local drg, dst, spt
Title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drg=true; dst=i.Position; spt=Main.Position
    end
end)
Title.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drg=false end
end)
UIS.InputChanged:Connect(function(i)
    if drg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dst
        Main.Position = UDim2.new(spt.X.Scale, spt.X.Offset + d.X, spt.Y.Scale, spt.Y.Offset + d.Y)
    end
end)

local fdrg, fdst, fspt
FB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        fdrg=true; fdst=i.Position; fspt=FB.Position
    end
end)
FB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fdrg=false end
end)
UIS.InputChanged:Connect(function(i)
    if fdrg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fdst
        FB.Position = UDim2.new(fspt.X.Scale, fspt.X.Offset + d.X, fspt.Y.Scale, fspt.Y.Offset + d.Y)
    end
end)

local function doClose() sfx() Main.Visible=false; FB.Visible=true end
local function doShow() sfx() Main.Visible=true; FB.Visible=false end

ClsB.MouseButton1Click:Connect(doClose)
MinB.MouseButton1Click:Connect(function()
    sfx()
    local isMin = Main.AbsoluteSize.Y <= TH_H + 5
    TS:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
        Size = isMin and UDim2.new(0,TW,0,TH) or UDim2.new(0,TW,0,TH_H)
    }):Play()
end)
GrnB.MouseButton1Click:Connect(function()
    sfx()
    S.MiniMode = not S.MiniMode
    local tW, tH = (S.MiniMode and TW or TW_NORMAL), (S.MiniMode and TH or TH_NORMAL)
    TS:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Size = UDim2.new(0, tW, 0, tH) }):Play()
    NotifyUser("Size", S.MiniMode and "Mini" or "Normal", "info")
end)
FB.MouseButton1Click:Connect(doShow)

local SX, SY = 10, TH_H + 10
local SW = 110
local UH = 46
local CX = SX + SW + 8

local SB = Instance.new("Frame", Main)
SB.Size = UDim2.new(0,SW,1,-SY-UH-14)
SB.Position = UDim2.new(0,SX,0,SY)
SB.BackgroundColor3 = C.Panel
SB.BackgroundTransparency = 0.5
SB.BorderSizePixel = 0
SB.ZIndex = 10
SB.Active = true
Instance.new("UICorner", SB).CornerRadius = UDim.new(0,10)
local sbs = Instance.new("UIStroke", SB)
sbs.Color = C.Pri; sbs.Thickness = 1; sbs.Transparency = 0.7; sbs.Parent = SB
track(sbs, "Color")

local UI_ = Instance.new("Frame", Main)
UI_.Size = UDim2.new(0,SW,0,UH)
UI_.Position = UDim2.new(0,SX,1,-(UH+10))
UI_.BackgroundColor3 = C.Panel
UI_.BackgroundTransparency = 0.5
UI_.BorderSizePixel = 0
UI_.ZIndex = 10
Instance.new("UICorner", UI_).CornerRadius = UDim.new(0,10)
local uis = Instance.new("UIStroke", UI_)
uis.Color = C.Pri; uis.Thickness = 1; uis.Transparency = 0.7; uis.Parent = UI_
track(uis, "Color")

local AV = Instance.new("Frame", UI_)
AV.Size = UDim2.new(0,30,0,30)
AV.Position = UDim2.new(0,8,0.5,-15)
AV.BackgroundColor3 = Color3.fromRGB(50,50,58)
AV.BorderSizePixel = 0
AV.ZIndex = 11
Instance.new("UICorner", AV).CornerRadius = UDim.new(1,0)
local avs = Instance.new("UIStroke", AV)
avs.Color = C.Pri; avs.Thickness = 1.5; avs.Transparency = 0.35; avs.Parent = AV
track(avs, "Color")
local AVi = Instance.new("ImageLabel", AV)
AVi.Size = UDim2.new(1,-4,1,-4)
AVi.Position = UDim2.new(0,2,0,2)
AVi.BackgroundTransparency = 1
AVi.ZIndex = 12
Instance.new("UICorner", AVi).CornerRadius = UDim.new(1,0)
task.spawn(function()
    local ok, t = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and t then AVi.Image = t end
end)

local DN = Instance.new("TextLabel", UI_)
DN.Size = UDim2.new(1,-48,0,14); DN.Position = UDim2.new(0,44,0,8)
DN.BackgroundTransparency = 1; DN.Text = LP.DisplayName or LP.Name
DN.TextColor3 = C.Txt; DN.TextSize = 11; DN.Font = Enum.Font.GothamMedium
DN.TextXAlignment = Enum.TextXAlignment.Left; DN.TextTruncate = Enum.TextTruncate.AtEnd; DN.ZIndex = 11

local UN = Instance.new("TextLabel", UI_)
UN.Size = UDim2.new(1,-48,0,12); UN.Position = UDim2.new(0,44,0,24)
UN.BackgroundTransparency = 1; UN.Text = "@" .. LP.Name
UN.TextColor3 = C.Dim; UN.TextSize = 9; UN.Font = Enum.Font.Gotham
UN.TextXAlignment = Enum.TextXAlignment.Left; UN.TextTruncate = Enum.TextTruncate.AtEnd; UN.ZIndex = 11

local Cont = Instance.new("Frame", Main)
Cont.Size = UDim2.new(1,-(CX+10),1,-SY-10)
Cont.Position = UDim2.new(0,CX,0,SY)
Cont.BackgroundColor3 = C.Panel
Cont.BackgroundTransparency = 0.55
Cont.BorderSizePixel = 0
Cont.ZIndex = 10
Instance.new("UICorner", Cont).CornerRadius = UDim.new(0,10)
local cts = Instance.new("UIStroke", Cont)
cts.Color = C.Pri; cts.Thickness = 1; cts.Transparency = 0.7; cts.Parent = Cont
track(cts, "Color")

local SearchBar = Instance.new("Frame", Cont)
SearchBar.Size = UDim2.new(1,-16,0,26)
SearchBar.Position = UDim2.new(0,8,0,8)
SearchBar.BackgroundColor3 = Color3.fromRGB(52,52,60)
SearchBar.BackgroundTransparency = 0.25
SearchBar.BorderSizePixel = 0
SearchBar.ZIndex = 11
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0,8)

local SearchInput = Instance.new("TextBox", SearchBar)
SearchInput.Size = UDim2.new(1,-12,1,0)
SearchInput.Position = UDim2.new(0,6,0,0)
SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""
SearchInput.PlaceholderText = "Cari fitur..."
SearchInput.PlaceholderColor3 = C.Dim
SearchInput.TextColor3 = C.Txt
SearchInput.TextSize = 11
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false
SearchInput.ZIndex = 12

local THF = Instance.new("Frame", Cont)
THF.Size = UDim2.new(1,-16,0,22)
THF.Position = UDim2.new(0,8,0,40)
THF.BackgroundTransparency = 1
THF.ZIndex = 11

local THt = Instance.new("TextLabel", THF)
THt.Size = UDim2.new(1,-30,1,0)
THt.Position = UDim2.new(0,4,0,0)
THt.BackgroundTransparency = 1
THt.Text = "RUMAH"
THt.TextColor3 = C.Txt
THt.TextSize = 13
THt.Font = Enum.Font.GothamMedium
THt.TextXAlignment = Enum.TextXAlignment.Left
THt.ZIndex = 12

local tabData = {
    {name="RUMAH"}, {name="COLLECT"}, {name="ESP"}, {name="EVENT"},
    {name="MISC"}, {name="TEMA"}, {name="CREDITS"},
}

local tabContent = {}
local CONTENT_Y = 70
for i, t in ipairs(tabData) do
    local sc = Instance.new("ScrollingFrame", Cont)
    sc.Size = UDim2.new(1,-16,1,-CONTENT_Y-8)
    sc.Position = UDim2.new(0,8,0,CONTENT_Y)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = C.Pri
    sc.CanvasSize = UDim2.new(0,0,0,0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Visible = (i == 1)
    sc.ZIndex = 10
    tabContent[t.name] = sc
    track(sc, "ScrollBarImageColor3")
    local lay = Instance.new("UIListLayout", sc)
    lay.Padding = UDim.new(0,6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", sc)
    pad.PaddingRight = UDim.new(0,4)
end

local tabBtns = {}
local curTab = "RUMAH"
for i, t in ipairs(tabData) do
    local b = Instance.new("TextButton", SB)
    b.Size = UDim2.new(1,-16,0,24)
    b.Position = UDim2.new(0,8,0,4+(i-1)*26)
    b.BackgroundColor3 = (i==1) and C.Pri or Color3.fromRGB(50,50,58)
    b.BackgroundTransparency = (i==1) and 0.05 or 0.35
    b.BorderSizePixel = 0
    b.Text = t.name
    b.TextColor3 = (i==1) and Color3.fromRGB(255,255,255) or C.Txt
    b.TextSize = 9
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.ZIndex = 100
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    tabBtns[t.name] = b
    if i == 1 then track(b, "BackgroundColor3") end
    b.MouseButton1Click:Connect(function()
        if curTab == t.name then return end
        sfx()
        curTab = t.name
        for n, bb in pairs(tabBtns) do
            local on = (n == t.name)
            TS:Create(bb, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = on and C.Pri or Color3.fromRGB(50,50,58),
                BackgroundTransparency = on and 0.05 or 0.35,
            }):Play()
            TS:Create(bb, TweenInfo.new(0.2), {
                TextColor3 = on and Color3.fromRGB(255,255,255) or C.Txt
            }):Play()
        end
        THt.Text = t.name
        for n, c in pairs(tabContent) do c.Visible = (n == t.name) end
    end)
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local q = string.lower(SearchInput.Text)
    for _, el in ipairs(searchables) do
        if el and el.Parent then
            if q == "" then el.Visible = true
            else
                local txt = el:GetAttribute("SearchText") or ""
                el.Visible = (txt:find(q, 1, true) ~= nil)
            end
        end
    end
end)

local function Btn(parent, text, cb, col)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1,-4,0,32)
    b.BackgroundColor3 = col or C.Card
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = (col and Color3.fromRGB(255,255,255)) or C.Pri
    b.TextSize = 11
    b.Font = Enum.Font.GothamMedium
    b.AutoButtonColor = false
    b.ZIndex = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    if not col then track(b, "TextColor3") end
    trackSearch(b, text)
    b.MouseEnter:Connect(function() TS:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play() end)
    b.MouseButton1Click:Connect(function() sfx(); if cb then pcall(cb) end end)
    return b
end

local function Sect(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,-4,0,16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.Pri
    l.TextSize = 10
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 10
    track(l, "TextColor3")
    trackSearch(l, text)
end

local function Toggle(parent, title, initial, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-4,0,30)
    f.BackgroundColor3 = C.Card
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.ZIndex = 10
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    trackSearch(f, title)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title; lbl.TextColor3 = C.Txt
    lbl.TextSize = 11; lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    local bg = Instance.new("Frame", f)
    bg.Size = UDim2.new(0,40,0,22)
    bg.Position = UDim2.new(1,-50,0.5,-11)
    bg.BackgroundColor3 = initial and C.Grn or Color3.fromRGB(60,60,68)
    bg.BorderSizePixel = 0; bg.ZIndex = 11
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = initial and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0; knob.ZIndex = 12
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state = initial
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 13
    btn.MouseButton1Click:Connect(function()
        sfx()
        state = not state
        knob.Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        bg.BackgroundColor3 = state and C.Grn or Color3.fromRGB(60,60,68)
        if cb then pcall(cb, state) end
        if state then NotifyUser("Enabled", title, "success") end
    end)
    return f
end

local function Slider(parent, title, mn, mx, df, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-4,0,44)
    f.BackgroundColor3 = C.Card
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0
    f.ZIndex = 10
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    trackSearch(f, title)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-14,0,14)
    l.Position = UDim2.new(0,10,0,6)
    l.BackgroundTransparency = 1
    l.Text = title .. ": " .. df
    l.TextColor3 = C.Txt; l.TextSize = 11
    l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 11
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1,-20,0,8)
    bar.Position = UDim2.new(0,10,0,26)
    bar.BackgroundColor3 = Color3.fromRGB(60,60,68)
    bar.BorderSizePixel = 0; bar.ZIndex = 11
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
    local fl = Instance.new("Frame", bar)
    fl.Size = UDim2.new((df-mn)/(mx-mn),0,1,0)
    fl.BackgroundColor3 = C.Pri
    fl.BorderSizePixel = 0; fl.ZIndex = 12
    Instance.new("UICorner", fl).CornerRadius = UDim.new(1,0)
    track(fl, "BackgroundColor3")
    local knob = Instance.new("Frame", fl)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(1,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0; knob.ZIndex = 13
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dr = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dr = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local bs = bar.AbsoluteSize.X
            if bs <= 0 then return end
            local pct = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bs, 0, 1)
            local v = math.floor(mn + (mx-mn)*pct)
            fl.Size = UDim2.new(pct,0,1,0)
            l.Text = title .. ": " .. v
            if cb then pcall(cb, v) end
        end
    end)
end

local function Dropdown(parent, title, options, default, cb)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-4,0,30)
    f.BackgroundColor3 = C.Card
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.ZIndex = 10
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
    trackSearch(f, title)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.5,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = C.Txt
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 11
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.45,0,0,22)
    btn.Position = UDim2.new(0.53,0,0.5,-11)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,68)
    btn.BorderSizePixel = 0
    btn.Text = tostring(default)
    btn.TextColor3 = C.Pri
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i end end
    btn.MouseButton1Click:Connect(function()
        sfx()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = options[idx]
        if cb then pcall(cb, options[idx]) end
    end)
end

-- FILL RUMAH
local tr = tabContent.RUMAH
local welcomeCard = Instance.new("Frame", tr)
welcomeCard.Size = UDim2.new(1,-4,0,70)
welcomeCard.BackgroundColor3 = C.Card
welcomeCard.BackgroundTransparency = 0.25
welcomeCard.BorderSizePixel = 0
welcomeCard.ZIndex = 10
Instance.new("UICorner", welcomeCard).CornerRadius = UDim.new(0,12)
local bigAv = Instance.new("Frame", welcomeCard)
bigAv.Size = UDim2.new(0,52,0,52)
bigAv.Position = UDim2.new(0,10,0.5,-26)
bigAv.BackgroundColor3 = Color3.fromRGB(55,55,63)
bigAv.BorderSizePixel = 0; bigAv.ZIndex = 12
Instance.new("UICorner", bigAv).CornerRadius = UDim.new(1,0)
local bigAvS = Instance.new("UIStroke", bigAv)
bigAvS.Color = C.Pri; bigAvS.Thickness = 2; bigAvS.Transparency = 0.35; bigAvS.Parent = bigAv
track(bigAvS, "Color")
local bigAvI = Instance.new("ImageLabel", bigAv)
bigAvI.Size = UDim2.new(1,-6,1,-6)
bigAvI.Position = UDim2.new(0,3,0,3)
bigAvI.BackgroundTransparency = 1; bigAvI.ZIndex = 13
Instance.new("UICorner", bigAvI).CornerRadius = UDim.new(1,0)
task.spawn(function()
    local ok, t = pcall(function()
        return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and t then bigAvI.Image = t end
end)
local greetLbl = Instance.new("TextLabel", welcomeCard)
greetLbl.Size = UDim2.new(1,-74,0,18)
greetLbl.Position = UDim2.new(0,72,0,12)
greetLbl.BackgroundTransparency = 1
greetLbl.Text = "Halo, " .. (LP.DisplayName or LP.Name) .. "!"
greetLbl.TextColor3 = C.Txt; greetLbl.TextSize = 13
greetLbl.Font = Enum.Font.GothamMedium
greetLbl.TextXAlignment = Enum.TextXAlignment.Left; greetLbl.ZIndex = 12
local clockLbl = Instance.new("TextLabel", welcomeCard)
clockLbl.Size = UDim2.new(1,-74,0,14)
clockLbl.Position = UDim2.new(0,72,0,32)
clockLbl.BackgroundTransparency = 1
clockLbl.Text = "--"; clockLbl.TextColor3 = C.Dim
clockLbl.TextSize = 10; clockLbl.Font = Enum.Font.Gotham
clockLbl.TextXAlignment = Enum.TextXAlignment.Left; clockLbl.ZIndex = 12
local uptimeLbl = Instance.new("TextLabel", welcomeCard)
uptimeLbl.Size = UDim2.new(1,-74,0,14)
uptimeLbl.Position = UDim2.new(0,72,0,48)
uptimeLbl.BackgroundTransparency = 1
uptimeLbl.Text = "Playtime: 00:00:00"
uptimeLbl.TextColor3 = C.Dim; uptimeLbl.TextSize = 10
uptimeLbl.Font = Enum.Font.Gotham
uptimeLbl.TextXAlignment = Enum.TextXAlignment.Left; uptimeLbl.ZIndex = 12

Sect(tr, "LIVE STATS")
local statsCard = Instance.new("Frame", tr)
statsCard.Size = UDim2.new(1,-4,0,58)
statsCard.BackgroundColor3 = C.Card
statsCard.BackgroundTransparency = 0.25
statsCard.BorderSizePixel = 0
statsCard.ZIndex = 10
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0,12)
local function mkStatBox(parent, x, title)
    local box = Instance.new("Frame", parent)
    box.Size = UDim2.new(0,100,0,48)
    box.Position = UDim2.new(0,x,0.5,-24)
    box.BackgroundColor3 = Color3.fromRGB(52,52,60)
    box.BackgroundTransparency = 0.2
    box.BorderSizePixel = 0
    box.ZIndex = 11
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
    local tL = Instance.new("TextLabel", box)
    tL.Size = UDim2.new(1,0,0,12)
    tL.Position = UDim2.new(0,0,0,6)
    tL.BackgroundTransparency = 1
    tL.Text = title; tL.TextColor3 = C.Dim
    tL.TextSize = 9; tL.Font = Enum.Font.GothamMedium; tL.ZIndex = 12
    local vL = Instance.new("TextLabel", box)
    vL.Size = UDim2.new(1,0,0,20)
    vL.Position = UDim2.new(0,0,0,22)
    vL.BackgroundTransparency = 1
    vL.Text = "--"; vL.TextColor3 = C.Pri
    vL.TextSize = 14; vL.Font = Enum.Font.GothamBold; vL.ZIndex = 12
    track(vL, "TextColor3")
    return vL
end
local fpsVal = mkStatBox(statsCard, 8, "FPS")
local pingVal = mkStatBox(statsCard, 116, "PING")
local playerVal = mkStatBox(statsCard, 224, "PLAYERS")

local fpsCount, fpsTime, curFPS = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsTime = fpsTime + dt
    if fpsTime >= 1 then
        curFPS = math.floor(fpsCount / fpsTime)
        fpsCount = 0; fpsTime = 0
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(2)
        pcall(function()
            local t = os.date("*t")
            local h = t.hour
            local greet = (h<12 and "Selamat Pagi") or (h<15 and "Selamat Siang") or (h<18 and "Selamat Sore") or "Selamat Malam"
            clockLbl.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
            greetLbl.Text = greet .. ", " .. (LP.DisplayName or LP.Name) .. "!"
            local el = os.time() - S.StartTime
            uptimeLbl.Text = string.format("Playtime: %02d:%02d:%02d", math.floor(el/3600), math.floor((el%3600)/60), el%60)
            fpsVal.Text = tostring(curFPS)
            pcall(function() pingVal.Text = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms" end)
            playerVal.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
        end)
    end
end)

-- FILL COLLECT
local tcol = tabContent.COLLECT

Sect(tcol, "═══ WALK NATURAL (SMOOTH VERTICAL) ═══")
Toggle(tcol, "Enable Walk Natural", false, function(v)
    State.WalkNaturalEnabled = v
    if v then NotifyUser("Walk Natural", "Noclip + Smooth Vertical aktif", "success") end
end)
Slider(tcol, "Vertical Speed (stud/s)", 5, 100, 30, function(v) State.WalkVerticalSpeed = v end)
Slider(tcol, "Smoothness (ms)", 10, 300, 50, function(v) State.WalkVerticalSmoothness = v / 1000 end)
Slider(tcol, "Detect Range (stud)", 5, 60, 25, function(v) State.WalkHorizontalRange = v end)

Sect(tcol, "═══ COLLECT V1 ═══")
Toggle(tcol, "Enable Collect V1", false, function(v) State.CollectV1Enabled = v end)
Dropdown(tcol, "V1 Mode", {"walk"}, State.CollectMode, function(v)
    State.CollectMode = v
    NotifyUser("V1 Mode", v, "success")
end)
Slider(tcol, "V1 Interval", 1, 10, 2, function(v) State.CollectInterval = v end)
Slider(tcol, "V1 Walk Speed", 16, 80, 32, function(v) State.WalkSpeed = v end)

Sect(tcol, "═══ COLLECT V2 ═══")
Toggle(tcol, "Enable Collect V2", false, function(v) State.CollectV2Enabled = v end)
Dropdown(tcol, "V2 Mode", {"path", "move", "align", "walkpoint", "walkpart"}, State.CollectV2Mode, function(v)
    State.CollectV2Mode = v
    NotifyUser("V2 Mode", v, "success")
end)
Slider(tcol, "V2 Interval", 1, 10, 2, function(v) State.CollectV2Interval = v end)
Slider(tcol, "V2 Walk Speed", 16, 80, 32, function(v) State.CollectV2WalkSpeed = v end)
Slider(tcol, "V2 Timeout (s)", 30, 300, 120, function(v) State.CollectV2Timeout = v end)

Sect(tcol, "═══ PUMPKIN ═══")
Toggle(tcol, "Auto Collect Pumpkin", false, function(v) State.PumpkinEnabled = v end)
Slider(tcol, "Pumpkin Interval", 1, 10, 2, function(v) State.PumpkinInterval = v end)

Sect(tcol, "METHOD")
Toggle(tcol, "FirePrompt", false, function(v) State.FirePrompt = v end)
Toggle(tcol, "No Delay Button", false, function(v) State.NoDelay = v end)

-- FILL ESP
local te = tabContent.ESP
Sect(te, "ESP")
Toggle(te, "Item ESP", false, function(v)
    State.ItemESP = v
    if not v then for m in pairs(itemCache) do removeESP(m) end itemCache = {} end
end)
Toggle(te, "Pumpkin ESP", false, function(v)
    State.PumpkinESP = v
    if not v then for m in pairs(pumpkinCache) do removeESP(m) end pumpkinCache = {} end
end)
Toggle(te, "Reaper ESP", false, function(v)
    State.ReaperESP = v
    if not v then for m in pairs(reaperCache) do removeESP(m) end reaperCache = {} end
end)
Toggle(te, "Ghost ESP", false, function(v)
    State.GhostESP = v
    if not v then for m in pairs(ghostCache) do removeESP(m) end ghostCache = {} end
end)
Toggle(te, "Show Distance", false, function(v) State.ShowDistance = v end)

-- FILL EVENT
local tEv = tabContent.EVENT
Sect(tEv, "EVENT TIMER")
local eventCard = Instance.new("Frame", tEv)
eventCard.Size = UDim2.new(1,-4,0,80)
eventCard.BackgroundColor3 = C.Card
eventCard.BackgroundTransparency = 0.2
eventCard.BorderSizePixel = 0
eventCard.ZIndex = 10
Instance.new("UICorner", eventCard).CornerRadius = UDim.new(0,10)
local eventTimerLbl = Instance.new("TextLabel", eventCard)
eventTimerLbl.Size = UDim2.new(1,-10,0,32)
eventTimerLbl.Position = UDim2.new(0,5,0,8)
eventTimerLbl.BackgroundTransparency = 1
eventTimerLbl.Text = "00:00:00"
eventTimerLbl.TextColor3 = C.Pri
eventTimerLbl.TextSize = 24
eventTimerLbl.Font = Enum.Font.GothamBold
eventTimerLbl.TextXAlignment = Enum.TextXAlignment.Center
eventTimerLbl.ZIndex = 11
track(eventTimerLbl, "TextColor3")
local eventProgressBg = Instance.new("Frame", eventCard)
eventProgressBg.Size = UDim2.new(1,-16,0,6)
eventProgressBg.Position = UDim2.new(0,8,0,48)
eventProgressBg.BackgroundColor3 = Color3.fromRGB(60,60,68)
eventProgressBg.BorderSizePixel = 0
eventProgressBg.ZIndex = 11
Instance.new("UICorner", eventProgressBg).CornerRadius = UDim.new(1,0)
local eventProgressFill = Instance.new("Frame", eventProgressBg)
eventProgressFill.Size = UDim2.new(0, 0, 1, 0)
eventProgressFill.BackgroundColor3 = C.Pri
eventProgressFill.BorderSizePixel = 0
eventProgressFill.ZIndex = 12
Instance.new("UICorner", eventProgressFill).CornerRadius = UDim.new(1,0)
track(eventProgressFill, "BackgroundColor3")
local eventStatusLbl = Instance.new("TextLabel", eventCard)
eventStatusLbl.Size = UDim2.new(1,-10,0,14)
eventStatusLbl.Position = UDim2.new(0,5,0,60)
eventStatusLbl.BackgroundTransparency = 1
eventStatusLbl.Text = "Next: --"
eventStatusLbl.TextColor3 = C.Dim
eventStatusLbl.TextSize = 10
eventStatusLbl.Font = Enum.Font.GothamMedium
eventStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
eventStatusLbl.ZIndex = 11

Sect(tEv, "JAM DIGITAL")
local clockCard = Instance.new("Frame", tEv)
clockCard.Size = UDim2.new(1,-4,0,60)
clockCard.BackgroundColor3 = C.Card
clockCard.BackgroundTransparency = 0.2
clockCard.BorderSizePixel = 0
clockCard.ZIndex = 10
Instance.new("UICorner", clockCard).CornerRadius = UDim.new(0,10)
local clockLbl2 = Instance.new("TextLabel", clockCard)
clockLbl2.Size = UDim2.new(1,-10,0,30)
clockLbl2.Position = UDim2.new(0,5,0,6)
clockLbl2.BackgroundTransparency = 1
clockLbl2.Text = "--:--:--"
clockLbl2.TextColor3 = C.Cyn
clockLbl2.TextSize = 22
clockLbl2.Font = Enum.Font.GothamBold
clockLbl2.TextXAlignment = Enum.TextXAlignment.Center
clockLbl2.ZIndex = 11
local dateLbl2 = Instance.new("TextLabel", clockCard)
dateLbl2.Size = UDim2.new(1,-10,0,16)
dateLbl2.Position = UDim2.new(0,5,0,38)
dateLbl2.BackgroundTransparency = 1
dateLbl2.Text = "--"
dateLbl2.TextColor3 = C.Dim
dateLbl2.TextSize = 10
dateLbl2.Font = Enum.Font.Gotham
dateLbl2.TextXAlignment = Enum.TextXAlignment.Center
dateLbl2.ZIndex = 11

Sect(tEv, "STATISTIK")
local function mkStatRow(parent, title, color)
    local bx = Instance.new("Frame", parent)
    bx.Size = UDim2.new(1,-4,0,36)
    bx.BackgroundColor3 = C.Card
    bx.BackgroundTransparency = 0.2
    bx.BorderSizePixel = 0
    bx.ZIndex = 10
    Instance.new("UICorner", bx).CornerRadius = UDim.new(0,10)
    local t = Instance.new("TextLabel", bx)
    t.Size = UDim2.new(0.5,0,1,0)
    t.BackgroundTransparency = 1
    t.Text = title; t.TextColor3 = C.Dim
    t.TextSize = 10; t.Font = Enum.Font.GothamMedium
    t.TextXAlignment = Enum.TextXAlignment.Left; t.ZIndex = 11
    t.Position = UDim2.fromOffset(10,0)
    local v = Instance.new("TextLabel", bx)
    v.Size = UDim2.new(0.5,-10,1,0)
    v.Position = UDim2.new(0.5,0,0,0)
    v.BackgroundTransparency = 1
    v.Text = "0"; v.TextColor3 = color
    v.TextSize = 16; v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right; v.ZIndex = 11
    return v
end
local statCollectedVal = mkStatRow(tEv, "Item Collected", C.Grn)
local statSpawnVal = mkStatRow(tEv, "Item Spawn", C.Pri)
local statPumpkinColVal = mkStatRow(tEv, "Pumpkin Collected", C.Orng)
local statPumpkinSpawnVal = mkStatRow(tEv, "Pumpkin Spawn", C.Yel)
local statVertVal = mkStatRow(tEv, "Vertical Steps", C.Cyn)
local statMoveBlock = mkStatRow(tEv, "Movement Block", C.Red)

task.spawn(function()
    while SG.Parent do
        task.wait(1.5)
        pcall(function()
            local t = os.date("*t")
            local h12 = t.hour % 12; if h12 == 0 then h12 = 12 end
            local ap = t.hour >= 12 and "PM" or "AM"
            clockLbl2.Text = string.format("%02d:%02d:%02d %s", h12, t.min, t.sec, ap)
            dateLbl2.Text = os.date("%A, %d %B %Y")
            local ev = getEventInfo()
            eventTimerLbl.Text = ev.countdownStr
            eventStatusLbl.Text = "Next: " .. ev.nextEventStr
            eventProgressFill.Size = UDim2.new(math.clamp(ev.percent, 0, 1), 0, 1, 0)
            if ev.isEventActive then
                eventTimerLbl.TextColor3 = C.Grn
                eventStatusLbl.Text = "EVENT ACTIVE!"
                eventStatusLbl.TextColor3 = C.Grn
            else
                eventTimerLbl.TextColor3 = C.Pri
                eventStatusLbl.TextColor3 = C.Dim
            end
            statCollectedVal.Text = tostring(StatsData.ItemsCollected)
            statSpawnVal.Text = tostring(StatsData.ItemsSpawned)
            statPumpkinColVal.Text = tostring(StatsData.PumpkinsCollected)
            statPumpkinSpawnVal.Text = tostring(StatsData.PumpkinsSpawned)
            statVertVal.Text = tostring(StatsData.VerticalSteps)
            statMoveBlock.Text = tostring(AntiDetect.MovementBlocked)
        end)
    end
end)

-- FILL MISC
local tm = tabContent.MISC
Sect(tm, "ANTI-DETECT SYSTEM")
Toggle(tm, "Enable Anti-Detect", false, function(v)
    AntiDetect.Enabled = v
    NotifyUser("Anti-Detect", v and "ON" or "OFF", v and "success" or "warn")
end)
Slider(tm, "Max TP Distance", 10, 200, 80, function(v) AntiDetect.MaxTPDistance = v end)
Slider(tm, "Max Speed (stud/s)", 20, 200, 100, function(v) AntiDetect.MaxSpeed = v end)

Sect(tm, "WALKSPEED")
Toggle(tm, "Enable WalkSpeed", false, function(v)
    State.WalkSpeedEnabled = v
    if not v then
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
    end
end)
Slider(tm, "Speed", 16, 200, 16, function(v)
    State.WalkSpeedValue = v
    if State.WalkSpeedEnabled then
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
    end
end)

Sect(tm, "NOCLIP (Manual)")
Toggle(tm, "Noclip", false, function(v) State.Noclip = v end)

Sect(tm, "INVISIBLE")
Toggle(tm, "Invisible", false, function(v) State.Invisible = v end)

Sect(tm, "FLY MODE")
Toggle(tm, "Enable Fly", false, function(v)
    State.Fly = v
    if v then startFly() else stopFly() end
end)
Slider(tm, "Fly Speed", 20, 300, 80, function(v)
    State.FlySpeed = v
    if flyBV then flyBV.Velocity = flyBV.Velocity.Unit * v end
end)

Sect(tm, "GOD MODE / DESYNC")
Toggle(tm, "GodMode Desync", false, function(v) State.GodMode = v end)
Slider(tm, "Detect Radius", 10, 200, 30, function(v) State.DesyncRadius = v end)

Sect(tm, "ANTI-AFK")
Toggle(tm, "Anti-AFK", false, function(v) State.AntiAFK = v end)
Slider(tm, "AFK Interval", 15, 120, 90, function(v) State.AntiAFKInterval = v end)

Sect(tm, "UTILITY")
Btn(tm, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end, Color3.fromRGB(60, 120, 90))
Btn(tm, "Copy Discord Invite", function()
    if setclipboard then setclipboard(CONFIG.DISCORD) Log("Discord copied", "success") end
end)
Btn(tm, "Unload UI", function()
    task.wait(0.3)
    stopFly()
    SG:Destroy()
end, Color3.fromRGB(150, 60, 70))

-- FILL TEMA
local ttem = tabContent.TEMA
Sect(ttem, "BACKGROUND IMAGE")
local themeBtns = {}
for i, bg in ipairs(BG_LIST) do
    local b = Instance.new("TextButton", ttem)
    b.Size = UDim2.new(1,-4,0,44)
    b.BackgroundColor3 = C.Card
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 11
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke", b)
    s.Color = (i == S.selBG) and C.Pri or Color3.fromRGB(80,80,88)
    s.Thickness = (i == S.selBG) and 2 or 1
    s.Transparency = (i == S.selBG) and 0.2 or 0.6
    s.Parent = b
    trackSearch(b, "Theme " .. bg.name)
    local prev = Instance.new("ImageLabel", b)
    prev.Size = UDim2.new(0,36,0,36)
    prev.Position = UDim2.new(0,6,0.5,-18)
    prev.BackgroundColor3 = Color3.fromRGB(55,55,63)
    prev.BorderSizePixel = 0
    prev.Image = bg.id
    prev.ZIndex = 12
    Instance.new("UICorner", prev).CornerRadius = UDim.new(0,7)
    local lbl = Instance.new("TextLabel", b)
    lbl.Size = UDim2.new(1,-86,0,14)
    lbl.Position = UDim2.new(0,48,0,8)
    lbl.BackgroundTransparency = 1
    lbl.Text = i .. ". " .. bg.name
    lbl.TextColor3 = (i == S.selBG) and C.Pri or C.Txt
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 12
    local chk = Instance.new("TextLabel", b)
    chk.Size = UDim2.new(0,24,1,0)
    chk.Position = UDim2.new(1,-28,0,0)
    chk.BackgroundTransparency = 1
    chk.Text = (i == S.selBG) and "V" or ""
    chk.TextColor3 = C.Pri
    chk.TextSize = 16
    chk.Font = Enum.Font.GothamBold
    chk.ZIndex = 12
    themeBtns[i] = {btn=b, stroke=s, lbl=lbl, chk=chk}
    b.MouseButton1Click:Connect(function()
        sfx()
        S.selBG = i
        for j, item in pairs(themeBtns) do
            local isSel = (j == S.selBG)
            item.stroke.Color = isSel and C.Pri or Color3.fromRGB(80,80,88)
            item.stroke.Thickness = isSel and 2 or 1
            item.stroke.Transparency = isSel and 0.2 or 0.6
            item.lbl.TextColor3 = isSel and C.Pri or C.Txt
            item.chk.Text = isSel and "V" or ""
        end
    end)
end

Btn(ttem, "Ganti Background", function()
    if S.selBG == S.curBG then Log("Sama", "warn"); return end
    S.curBG = S.selBG
    bgI.Image = BG_LIST[S.curBG].id
    Log("BG: " .. BG_LIST[S.curBG].name, "success")
end, Color3.fromRGB(60,120,90))

Sect(ttem, "WARNA UI")
local hueFrame = Instance.new("Frame", ttem)
hueFrame.Size = UDim2.new(1,-4,0,60)
hueFrame.BackgroundColor3 = C.Card
hueFrame.BackgroundTransparency = 0.25
hueFrame.BorderSizePixel = 0
hueFrame.ZIndex = 10
Instance.new("UICorner", hueFrame).CornerRadius = UDim.new(0,10)
local huePrev = Instance.new("Frame", hueFrame)
huePrev.Size = UDim2.new(0,18,0,18)
huePrev.Position = UDim2.new(1,-30,0,4)
huePrev.BackgroundColor3 = Color3.fromHSV(0.08, 0.65, 0.95)
huePrev.BorderSizePixel = 0
huePrev.ZIndex = 12
Instance.new("UICorner", huePrev).CornerRadius = UDim.new(1,0)
local hueBar = Instance.new("Frame", hueFrame)
hueBar.Size = UDim2.new(1,-20,0,22)
hueBar.Position = UDim2.new(0,10,0,28)
hueBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
hueBar.BorderSizePixel = 0
hueBar.ZIndex = 11
Instance.new("UICorner", hueBar).CornerRadius = UDim.new(1,0)
local hueGrad = Instance.new("UIGradient", hueBar)
hueGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 90, 90)),
    ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 170, 90)),
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 230, 110)),
    ColorSequenceKeypoint.new(0.42, Color3.fromRGB(150, 230, 130)),
    ColorSequenceKeypoint.new(0.56, Color3.fromRGB(110, 210, 240)),
    ColorSequenceKeypoint.new(0.70, Color3.fromRGB(120, 150, 250)),
    ColorSequenceKeypoint.new(0.85, Color3.fromRGB(210, 130, 250)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 90)),
})
local hueKnob = Instance.new("Frame", hueBar)
hueKnob.Size = UDim2.new(0,24,0,24)
hueKnob.Position = UDim2.new(0.08, -12, 0.5, -12)
hueKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
hueKnob.BorderSizePixel = 0
hueKnob.ZIndex = 13
Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(1,0)

local hueDrag = false
local function updateHue(px)
    local bs = hueBar.AbsoluteSize.X
    if bs <= 0 then return end
    local pct = math.clamp((px - hueBar.AbsolutePosition.X)/bs, 0, 1)
    hueKnob.Position = UDim2.new(pct, -12, 0.5, -12)
    local col = Color3.fromHSV(pct, 0.65, 0.98)
    huePrev.BackgroundColor3 = col
    S.HueColor = col
    applyColor(col)
end
hueBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        hueDrag = true; updateHue(i.Position.X)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then hueDrag = false end
end)
UIS.InputChanged:Connect(function(i)
    if hueDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        updateHue(i.Position.X)
    end
end)

Btn(ttem, "Reset Warna (Orange)", function()
    S.HueColor = Color3.fromRGB(255, 145, 80)
    applyColor(S.HueColor)
end, Color3.fromRGB(140, 70, 50))

Sect(ttem, "BG BRIGHTNESS")
Slider(ttem, "Kegelapan BG", 0, 80, math.floor(S.BGBrightness*100), function(v)
    S.BGBrightness = v/100
    ovl.BackgroundTransparency = S.BGBrightness
end)

-- FILL CREDITS
local tcr = tabContent.CREDITS
local creditCard = Instance.new("Frame", tcr)
creditCard.Size = UDim2.new(1,-4,0,130)
creditCard.BackgroundColor3 = C.Card
creditCard.BackgroundTransparency = 0.25
creditCard.BorderSizePixel = 0
creditCard.ZIndex = 10
Instance.new("UICorner", creditCard).CornerRadius = UDim.new(0,12)
local ccS = Instance.new("UIStroke", creditCard)
ccS.Color = C.Pri; ccS.Thickness = 1; ccS.Transparency = 0.7; ccS.Parent = creditCard
track(ccS, "Color")
local creditLogo = Instance.new("ImageLabel", creditCard)
creditLogo.Size = UDim2.new(0, 56, 0, 56)
creditLogo.Position = UDim2.new(0.5, -28, 0, 10)
creditLogo.BackgroundTransparency = 1
creditLogo.Image = CONFIG.LOGO
creditLogo.ZIndex = 12
local creditTitle = Instance.new("TextLabel", creditCard)
creditTitle.Size = UDim2.new(1, -20, 0, 22)
creditTitle.Position = UDim2.new(0, 10, 0, 70)
creditTitle.BackgroundTransparency = 1
creditTitle.RichText = true
creditTitle.Text = '<font color="rgb(255,255,255)">Oc1Dv</font><font color="rgb(255,145,80)">HUB</font>'
creditTitle.TextSize = 18
creditTitle.Font = Enum.Font.GothamBlack
creditTitle.TextXAlignment = Enum.TextXAlignment.Center
creditTitle.ZIndex = 12
local creditSub = Instance.new("TextLabel", creditCard)
creditSub.Size = UDim2.new(1, -20, 0, 16)
creditSub.Position = UDim2.new(0, 10, 0, 94)
creditSub.BackgroundTransparency = 1
creditSub.Text = "MOURGE SHIFT HALLOWEEN EDITION"
creditSub.TextColor3 = C.Dim
creditSub.TextSize = 10
creditSub.Font = Enum.Font.GothamMedium
creditSub.TextXAlignment = Enum.TextXAlignment.Center
creditSub.ZIndex = 12
local creditMade = Instance.new("TextLabel", creditCard)
creditMade.Size = UDim2.new(1, -20, 0, 14)
creditMade.Position = UDim2.new(0, 10, 0, 112)
creditMade.BackgroundTransparency = 1
creditMade.Text = "(c) 2026 - All rights reserved"
creditMade.TextColor3 = C.Dim
creditMade.TextSize = 9
creditMade.Font = Enum.Font.Gotham
creditMade.TextXAlignment = Enum.TextXAlignment.Center
creditMade.ZIndex = 12

Sect(tcr, "SOCIAL MEDIA")
local function mkSocBtn(name, handle, color, url)
    local b = Instance.new("TextButton", tcr)
    b.Size = UDim2.new(1,-4,0,36)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = 0.15
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 10
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    trackSearch(b, name)
    local t = Instance.new("TextLabel", b)
    t.Size = UDim2.new(0.4,0,1,0)
    t.Position = UDim2.fromOffset(12,0)
    t.BackgroundTransparency = 1
    t.Text = name:upper()
    t.TextColor3 = Color3.fromRGB(255,255,255)
    t.TextSize = 11
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 11
    local v = Instance.new("TextLabel", b)
    v.Size = UDim2.new(0.6,-12,1,0)
    v.Position = UDim2.new(0.4,0,0,0)
    v.BackgroundTransparency = 1
    v.Text = handle
    v.TextColor3 = Color3.fromRGB(230,230,240)
    v.TextSize = 10
    v.Font = Enum.Font.GothamMedium
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.TextTruncate = Enum.TextTruncate.AtEnd
    v.ZIndex = 11
    b.MouseButton1Click:Connect(function()
        sfx()
        if setclipboard then setclipboard(url) end
        NotifyUser(name, "Link copied!", "success")
    end)
end

mkSocBtn("Discord", "discord.gg/wtVKkDvyz", Color3.fromRGB(88, 101, 242), "https://discord.gg/wtVKkDvyz")
mkSocBtn("Instagram", "@mfrsyddd", Color3.fromRGB(225, 48, 108), "https://www.instagram.com/mfrsyddd")
mkSocBtn("TikTok", "@mfrsydqt", Color3.fromRGB(0,0,0), "tiktok.com/@mfrsydqt")
mkSocBtn("WhatsApp", "Saluran WA", Color3.fromRGB(37, 211, 102), "https://whatsapp.com/channel/0029VbBXI1lJZg45TdQXq129")

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if Main.Visible then doClose() else doShow() end
    end
end)

Log("FINAL V4 loaded", "success")
NotifyUser("Oc1DvHUB", "FINAL V4 loaded!", "success")
print("[Oc1DvHUB] FINAL V4 loaded ✅")
