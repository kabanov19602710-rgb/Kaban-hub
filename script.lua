-- KABAN MM2 HUB v5.0 | MEGA PACK
-- Basic:  KabanTest   (бесплатно)
-- Premium: KabanPrem  (всё крутое)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- ===== КЛЮЧИ =====
local BASIC_KEY = "KabanTest"
local PREMIUM_KEY = "KabanPrem"
local USER_TIER = "basic"

local SCRIPT_NAME = "KABAN MM2 HUB v5.0"

local config = {
    ESP = false,
    Speed = false,
    Noclip = false,
    Fly = false,
    AutoJump = false,
    InfiniteJump = false,
    AntiFling = false,
    AutoDodge = false,
    SpeedValue = 50,
    FlySpeed = 50,
    FPS = 60,
    XRay = false,
    Aim = false,
    SilentAim = false,
    AimFOV = 120,
    AimSmooth = 0.5,
    ShowFOV = false,
    AimTarget = "Murderer",
    AimWallCheck = true,
    AimLockTarget = true,
    AutoKill = false,
    AutoKillRange = 30,
    AutoKillCooldown = 0.3,
    ItemESP = false,
    TrapESP = false,
    FootstepTracker = false,
    PlayerTracker = false,
    BulletTracer = false,
    Crosshair = false,
    AntiBlind = false,
    KillFeed = false,
    ChatSpam = false,
    Stretch43 = false,
    NoFog = false
}

-- ===== МЕНЕДЖЕР СОЕДИНЕНИЙ =====
local Connections = {}
local function Track(name, conn)
    if Connections[name] then pcall(function() Connections[name]:Disconnect() end) end
    Connections[name] = conn
    return conn
end
local function Untrack(name)
    if Connections[name] then
        pcall(function() Connections[name]:Disconnect() end)
        Connections[name] = nil
    end
end
local function DisconnectAll()
    for name, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

local function ProtectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
        if protect_gui then protect_gui(gui) end
    end)
end

local espObjects = {}
local itemEspObjects = {}
local trapEspObjects = {}
local snowflakes = {}
local activeTab = "Main"
local isMinimized = false
local currentFPS = 0
local originalFOV = nil
local OriginalLighting = nil
local originalParticles = {}
local killFeedLog = {}
local footstepParts = {}

-- ===== РОЛИ =====
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 100, 255),
    Innocent = Color3.fromRGB(0, 255, 0),
    Unknown  = Color3.fromRGB(150, 150, 150)
}

local function GetRole(player)
    local char = player.Character
    if not char then return "Unknown" end
    local function checkTool(tool)
        if not tool or not tool:IsA("Tool") then return nil end
        local n = tool.Name:lower()
        if n:find("revolver") or n:find("pistol") or n:find("sheriff") or n:find("gun") then return "Sheriff" end
        if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then return "Murderer" end
        return nil
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            local r = checkTool(tool)
            if r then return r end
        end
    end
    local r = checkTool(char:FindFirstChildOfClass("Tool"))
    if r then return r end
    if player.Team then
        local tn = player.Team.Name:lower()
        if tn:find("murder") or tn:find("kill") then return "Murderer" end
        if tn:find("sheriff") or tn:find("cop") then return "Sheriff" end
    end
    return "Innocent"
end

-- ===== ГРАФИКА =====
local function SaveOriginalLighting()
    if OriginalLighting then return end
    OriginalLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        Ambient = Lighting.Ambient,
        Outlines = Lighting.Outlines,
    }
end

local function RestoreLighting()
    if not OriginalLighting then return end
    pcall(function()
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Outlines = OriginalLighting.Outlines
    end)
    OriginalLighting = nil
end

local function ApplyFPSBoost(fps)
    config.FPS = fps
    pcall(function()
        if setfpscap then setfpscap(fps) end
    end)
    SaveOriginalLighting()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect")
               or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
    end)
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                if originalParticles[v] == nil then
                    originalParticles[v] = v.Enabled
                end
                v.Enabled = false
            end
        end
    end)
end

local function RestoreGraphics()
    RestoreLighting()
    pcall(function()
        for v, orig in pairs(originalParticles) do
            if v and v.Parent then
                pcall(function() v.Enabled = orig end)
            end
        end
    end)
    originalParticles = {}
end

local function ApplyOptimization()
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("MeshPart") then
                v.RenderFidelity = Enum.RenderFidelity.Performance
            end
        end
        Lighting.ShadowSoftness = 0
        if Workspace:FindFirstChild("Terrain") then
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 1
        end
    end)
end

local function ApplyStretch43(state)
    config.Stretch43 = state
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if state then
        if originalFOV == nil then originalFOV = cam.FieldOfView end
        cam.FieldOfView = 100
    else
        if originalFOV then
            cam.FieldOfView = originalFOV
            originalFOV = nil
        end
    end
end

local function ApplyFullbright(state)
    if state then
        SaveOriginalLighting()
        Lighting.Brightness = 5
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.Outlines = false
    else
        RestoreLighting()
    end
end

local function ApplyNoFog(state)
    config.NoFog = state
    if state then
        SaveOriginalLighting()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    else
        RestoreLighting()
    end
end

local function ApplyTimeChange(time)
    pcall(function()
        Lighting.ClockTime = time
    end)
end

-- ===== FPS СЧЁТЧИК =====
local frameCount, lastFPSTime = 0, tick()
Track("fps_counter", RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastFPSTime >= 0.5 then
        currentFPS = math.floor(frameCount / (now - lastFPSTime))
        frameCount = 0
        lastFPSTime = now
    end
end))

-- ===== X-RAY =====
local xrayParts = setmetatable({}, {__mode = "k"})
local xrayConn = nil

local function ApplyXRay(state)
    if USER_TIER ~= "premium" then return end
    config.XRay = state
    if state then
        local playerParts = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character then
                for _, part in ipairs(pl.Character:GetDescendants()) do
                    playerParts[part] = true
                end
            end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not playerParts[obj] then
                if xrayParts[obj] == nil then xrayParts[obj] = obj.Transparency end
                obj.Transparency = 0.7
            end
        end
        if xrayConn then xrayConn:Disconnect() end
        xrayConn = Workspace.DescendantAdded:Connect(function(obj)
            if not config.XRay then return end
            if obj:IsA("BasePart") then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and obj:IsDescendantOf(pl.Character) then return end
                end
                xrayParts[obj] = obj.Transparency
                obj.Transparency = 0.7
            end
        end)
    else
        for obj, orig in pairs(xrayParts) do
            pcall(function()
                if obj and obj.Parent then obj.Transparency = orig end
            end)
        end
        xrayParts = setmetatable({}, {__mode = "k"})
        if xrayConn then xrayConn:Disconnect(); xrayConn = nil end
    end
end

-- ===== ESP =====
local function BuildESPForPlayer(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if espObjects[player] then
        if espObjects[player].highlight then espObjects[player].highlight:Destroy() end
        if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
        espObjects[player] = nil
    end
    local role = GetRole(player)
    local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown

    local highlight = Instance.new("Highlight")
    highlight.Name = "KABAN_ESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = char
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KABAN_ROLE"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = hrp
    billboard.Parent = char

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    roleLabel.Position = UDim2.new(0, 0, 0.5, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = role
    roleLabel.TextColor3 = color
    roleLabel.TextStrokeTransparency = 0
    roleLabel.TextScaled = true
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.Parent = billboard

    espObjects[player] = {highlight = highlight, billboard = billboard}
end

local function RemoveESPForPlayer(player)
    if espObjects[player] then
        if espObjects[player].highlight then espObjects[player].highlight:Destroy() end
        if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
        espObjects[player] = nil
    end
end

local function ToggleESP(state)
    config.ESP = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            BuildESPForPlayer(player)
        end
    else
        for player, _ in pairs(espObjects) do
            RemoveESPForPlayer(player)
        end
    end
end

Track("esp_update", RunService.Heartbeat:Connect(function()
    if not config.ESP then return end
    for player, objs in pairs(espObjects) do
        if player.Character and objs.highlight and objs.highlight.Parent then
            local role = GetRole(player)
            local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
            objs.highlight.FillColor = color
            if objs.billboard then
                local rl = objs.billboard:FindFirstChild("RoleLabel")
                if rl then
                    rl.Text = role
                    rl.TextColor3 = color
                end
            end
        end
    end
end))

local function HookPlayer(player)
    Track("char_" .. player.Name, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if config.ESP then BuildESPForPlayer(player) end
    end))
end

for _, p in ipairs(Players:GetPlayers()) do HookPlayer(p) end
Players.PlayerAdded:Connect(function(p) HookPlayer(p) end)
Players.PlayerRemoving:Connect(function(player)
    RemoveESPForPlayer(player)
    Untrack("char_" .. player.Name)
end)

-- ===== AIMBOT =====
local aimConnection = nil
local aimLockedTarget = nil
local fovCircle = nil
local silentAimConn = nil

local function GetFOVCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2.new(0, 0) end
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

local function GetScreenPos(worldPos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local sp, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function HasLineOfSight(targetPart)
    if not config.AimWallCheck then return true end
    local cam = Workspace.CurrentCamera
    if not cam or not targetPart then return false end
    local origin = cam.CFrame.Position
    local direction = (targetPart.Position - origin)
    if direction.Magnitude > 500 then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = {}
    if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
    if targetPart and targetPart.Parent then table.insert(filterList, targetPart.Parent) end
    rayParams.FilterDescendantsInstances = filterList
    rayParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function FindAimTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = GetFOVCenter()
    local bestTarget = nil
    local bestDist = config.AimFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local role = GetRole(player)
                    local wanted = false
                    if config.AimTarget == "Both" then
                        wanted = (role == "Murderer" or role == "Sheriff")
                    else
                        wanted = (role == config.AimTarget)
                    end
                    if wanted then
                        local targetPart = head or hrp
                        if HasLineOfSight(targetPart) then
                            local screenPos = GetScreenPos(targetPart.Position)
                            if screenPos then
                                local dist = (screenPos - center).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    bestTarget = {player = player, part = targetPart}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function AimAt(targetPart)
    local cam = Workspace.CurrentCamera
    if not cam or not targetPart then return end
    local desiredCF = CFrame.new(cam.CFrame.Position, targetPart.Position)
    if config.AimSmooth > 0 then
        cam.CFrame = cam.CFrame:Lerp(desiredCF, 1 - config.AimSmooth)
    else
        cam.CFrame = desiredCF
    end
end

local function ToggleAim(state)
    if USER_TIER ~= "premium" then return end
    config.Aim = state
    if state then
        if aimConnection then aimConnection:Disconnect() end
        aimConnection = RunService.RenderStepped:Connect(function()
            if not config.Aim then return end
            local cam = Workspace.CurrentCamera
            if not cam then return end

            if aimLockedTarget then
                local p = aimLockedTarget.player
                local part = aimLockedTarget.part
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if not p.Character or not part or not part.Parent or not hum or hum.Health <= 0 then
                    aimLockedTarget = nil
                end
            end

            if not aimLockedTarget then
                local found = FindAimTarget()
                if found then
                    aimLockedTarget = {player = found.player, part = found.part}
                end
            end

            if aimLockedTarget and aimLockedTarget.part and aimLockedTarget.part.Parent then
                AimAt(aimLockedTarget.part)
            end
        end)
    else
        if aimConnection then aimConnection:Disconnect(); aimConnection = nil end
        aimLockedTarget = nil
    end
end

local function ToggleSilentAim(state)
    if USER_TIER ~= "premium" then return end
    config.SilentAim = state
    if state then
        if silentAimConn then silentAimConn:Disconnect() end
        silentAimConn = RunService.RenderStepped:Connect(function()
            if not config.SilentAim then return end
            local target = FindAimTarget()
            if target then
                local mouse = LocalPlayer:GetMouse()
                if mouse then
                    pcall(function()
                        mouse.Hit = CFrame.new(target.part.Position)
                    end)
                end
            end
        end)
    else
        if silentAimConn then silentAimConn:Disconnect(); silentAimConn = nil end
    end
end

-- ===== FOV КРУГ =====
local function CreateFOVCircle()
    if fovCircle then fovCircle.gui:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KABAN_FOV"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ProtectGui(ScreenGui)

    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Size = UDim2.new(0, config.AimFOV * 2, 0, config.AimFOV * 2)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 0, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = circle

    fovCircle = {gui = ScreenGui, frame = circle, stroke = stroke}
end

local function UpdateFOVCircle()
    if fovCircle then
        fovCircle.frame.Size = UDim2.new(0, config.AimFOV * 2, 0, config.AimFOV * 2)
        fovCircle.frame.Visible = config.ShowFOV
    end
end

-- ===== SPEED / FLY / AUTO-JUMP / INF-JUMP =====
local speedConnection, flyConnection, autoJumpConnection, infJumpConn

local function ToggleSpeed(state)
    config.Speed = state
    if state then
        if speedConnection then speedConnection:Disconnect() end
        local speedVal = config.SpeedValue
        if USER_TIER == "premium" then speedVal = speedVal * 2 end
        speedConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = speedVal end
        end)
    else
        if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
end

local function ToggleFly(state)
    config.Fly = state
    if state then
        local bg = Instance.new("BodyGyro")
        bg.Name = "KABAN_FLY_BG"
        local bv = Instance.new("BodyVelocity")
        bv.Name = "KABAN_FLY_BV"
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp then return end
            hum.PlatformStand = true
            if not char:FindFirstChild("KABAN_FLY_BG") then
                bg.Parent = hrp
                bv.Parent = hrp
            end
            local cam = Workspace.CurrentCamera
            if cam then
                bg.CFrame = cam.CFrame
            end
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.new(0, 0, 0)
            -- движение
            local move = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                move = move + Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                move = move - Workspace.CurrentCamera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                move = move - Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                move = move + Workspace.CurrentCamera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                move = move + Vector3.new(0, 1, 0)
            end
            bv.Velocity = move * config.FlySpeed
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            if hrp then
                local bg = hrp:FindFirstChild("KABAN_FLY_BG")
                local bv = hrp:FindFirstChild("KABAN_FLY_BV")
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
            end
        end
    end
end

local function ToggleAutoJump(state)
    config.AutoJump = state
    if state then
        if autoJumpConnection then autoJumpConnection:Disconnect() end
        autoJumpConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Jump = true
            end
        end)
    else
        if autoJumpConnection then autoJumpConnection:Disconnect(); autoJumpConnection = nil end
    end
end

local function ToggleInfiniteJump(state)
    if USER_TIER ~= "premium" then return end
    config.InfiniteJump = state
    if state then
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if not config.InfiniteJump then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end
end

-- ===== NOCLIP =====
local noclipConnection
local function ToggleNoclip(state)
    if USER_TIER ~= "premium" then return end
    config.Noclip = state
    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- ===== ANTI-FLING =====
local antiflingConn
local function ToggleAntiFling(state)
    if USER_TIER ~= "premium" then return end
    config.AntiFling = state
    if state then
        if antiflingConn then antiflingConn:Disconnect() end
        antiflingConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > 100 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        if antiflingConn then antiflingConn:Disconnect(); antiflingConn = nil end
    end
end

-- ===== ТЕЛЕПОРТЫ =====
local function TeleportToRole(role)
    if USER_TIER ~= "premium" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and GetRole(player) == role then
            local tHrp = player.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then hrp.CFrame = tHrp.CFrame + Vector3.new(0, 3, 0) return end
        end
    end
end

local function TeleportToGun()
    if USER_TIER ~= "premium" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("revolver") or n:find("pistol") or n:find("gun") then
                hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                return
            end
        end
    end
end

local function TeleportToSpawn()
    if USER_TIER ~= "premium" then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
    end
end

-- ===== ITEM ESP =====
local function ToggleItemESP(state)
    if USER_TIER ~= "premium" then return end
    config.ItemESP = state
    if state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") then
                local handle = obj:FindFirstChild("Handle")
                if handle then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "KABAN_ITEM"
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 2, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = handle
                    bb.Parent = handle
                    local tl = Instance.new("TextLabel")
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.Text = obj.Name
                    tl.TextColor3 = Color3.fromRGB(255, 220, 100)
                    tl.TextStrokeTransparency = 0
                    tl.TextScaled = true
                    tl.Font = Enum.Font.GothamBold
                    tl.Parent = bb
                    itemEspObjects[obj] = bb
                end
            end
        end
    else
        for obj, bb in pairs(itemEspObjects) do
            pcall(function() bb:Destroy() end)
        end
        itemEspObjects = {}
    end
end

-- ===== TRAP ESP =====
local function ToggleTrapESP(state)
    if USER_TIER ~= "premium" then return end
    config.TrapESP = state
    if state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("trap") or n:find("bear") or n:find("mine") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "KABAN_TRAP"
                    hl.FillColor = Color3.fromRGB(255, 100, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.FillTransparency = 0.5
                    hl.Adornee = obj
                    hl.Parent = obj
                    trapEspObjects[obj] = hl
                end
            end
        end
    else
        for obj, hl in pairs(trapEspObjects) do
            pcall(function() hl:Destroy() end)
        end
        trapEspObjects = {}
    end
end

-- ===== PLAYER TRACKER (стрелка к убийце) =====
local trackerArrow = nil
local trackerConn = nil

local function TogglePlayerTracker(state)
    if USER_TIER ~= "premium" then return end
    config.PlayerTracker = state
    if state then
        if not trackerArrow then
            local gui = Instance.new("ScreenGui")
            gui.Name = "KABAN_TRACKER"
            gui.Parent = CoreGui
            gui.ResetOnSpawn = false
            ProtectGui(gui)
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 60, 0, 60)
            arrow.BackgroundTransparency = 1
            arrow.Text = "➤"
            arrow.TextColor3 = Color3.fromRGB(255, 0, 0)
            arrow.TextSize = 50
            arrow.Font = Enum.Font.GothamBold
            arrow.Parent = gui
            trackerArrow = {gui = gui, label = arrow}
        end
        trackerArrow.gui.Enabled = true
        if trackerConn then trackerConn:Disconnect() end
        trackerConn = RunService.RenderStepped:Connect(function()
            if not config.PlayerTracker or not trackerArrow then return end
            local murder = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and GetRole(p) == "Murderer" then
                    murder = p
                    break
                end
            end
            if not murder or not murder.Character then
                trackerArrow.label.Visible = false
                return
            end
            local hrp = murder.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then trackerArrow.label.Visible = false return end
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                trackerArrow.label.Visible = true
                trackerArrow.label.Position = UDim2.new(0, sp.X - 30, 0, sp.Y - 30)
            else
                trackerArrow.label.Visible = false
            end
        end)
    else
        if trackerArrow then trackerArrow.gui.Enabled = false end
        if trackerConn then trackerConn:Disconnect(); trackerConn = nil end
    end
end

-- ===== CROSSHAIR =====
local crosshairGui = nil
local function ToggleCrosshair(state)
    if USER_TIER ~= "premium" then return end
    config.Crosshair = state
    if state then
        if crosshairGui then crosshairGui:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "KABAN_CROSSHAIR"
        gui.Parent = CoreGui
        gui.ResetOnSpawn = false
        ProtectGui(gui)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        dot.BorderSizePixel = 0
        dot.Parent = gui
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot
        crosshairGui = gui
    else
        if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
end

-- ===== ANTI-BLIND =====
local antiblindConn = nil
local function ToggleAntiBlind(state)
    if USER_TIER ~= "premium" then return end
    config.AntiBlind = state
    if state then
        if antiblindConn then antiblindConn:Disconnect() end
        antiblindConn = RunService.Heartbeat:Connect(function()
            if not config.AntiBlind then return end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                    v.Enabled = false
                end
            end
        end)
    else
        if antiblindConn then antiblindConn:Disconnect(); antiblindConn = nil end
    end
end

-- ===== FOOTSTEP TRACKER =====
local function ToggleFootstepTracker(state)
    if USER_TIER ~= "premium" then return end
    config.FootstepTracker = state
    if state then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local stepConn = RunService.Heartbeat:Connect(function()
                    if not config.FootstepTracker then return end
                    local c = LocalPlayer.Character
                    if not c then return end
                    local h = c:FindFirstChild("HumanoidRootPart")
                    if not h then return end
                    local mark = Instance.new("Part")
                    mark.Size = Vector3.new(0.5, 0.1, 0.5)
                    mark.Position = h.Position - Vector3.new(0, 2.5, 0)
                    mark.Anchored = true
                    mark.CanCollide = false
                    mark.Material = Enum.Material.Neon
                    mark.Color = Color3.fromRGB(0, 255, 0)
                    mark.Transparency = 0.3
                    mark.Parent = Workspace
                    table.insert(footstepParts, mark)
                    task.delay(3, function()
                        if mark and mark.Parent then mark:Destroy() end
                    end)
                end)
                Track("footstep_conn", stepConn)
            end
        end
    else
        Untrack("footstep_conn")
        for _, p in ipairs(footstepParts) do
            pcall(function() if p and p.Parent then p:Destroy() end end)
        end
        footstepParts = {}
    end
end

-- ===== AUTO-KILL =====
local autoKillConnection = nil
local lastAutoKillTime = 0

local function GetMyRole()
    return GetRole(LocalPlayer)
end

local function FindMyWeapon()
    local myChar = LocalPlayer.Character
    if not myChar then return nil, nil end
    local tool = myChar:FindFirstChildOfClass("Tool")
    if tool then return tool, true end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") or n:find("revolver") or n:find("pistol") or n:find("gun") then
                    return item, false
                end
            end
        end
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return item, false
            end
        end
    end
    return nil, nil
end

local function FindAutoKillTarget()
    local myRole = GetMyRole()
    if myRole ~= "Murderer" and myRole ~= "Sheriff" then return nil end
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local myPos = myHrp.Position
    local bestTarget, bestDist = nil, config.AutoKillRange
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local targetRole = GetRole(player)
                local shouldKill = false
                if myRole == "Murderer" then
                    shouldKill = (targetRole ~= "Murderer")
                elseif myRole == "Sheriff" then
                    shouldKill = (targetRole == "Murderer")
                end
                if shouldKill then
                    local targetPart = head or hrp
                    local dist = (targetPart.Position - myPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestTarget = {player = player, part = targetPart}
                    end
                end
            end
        end
    end
    return bestTarget
end

local function ToggleAutoKill(state)
    if USER_TIER ~= "premium" then return end
    config.AutoKill = state
    if state then
        if autoKillConnection then autoKillConnection:Disconnect() end
        autoKillConnection = RunService.Heartbeat:Connect(function()
            if not config.AutoKill then return end
            if tick() - lastAutoKillTime < config.AutoKillCooldown then return end
            local target = FindAutoKillTarget()
            if not target then return end
            local myChar = LocalPlayer.Character
            if not myChar then return end
            local myHrp = myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end
            local targetPos = target.part.Position
            local behind = targetPos + (target.part.CFrame.LookVector * -3)
            pcall(function()
                myHrp.CFrame = CFrame.new(behind, targetPos)
            end)
            local tool, inHands = FindMyWeapon()
            if tool and not inHands then
                local hum = myChar:FindFirstChildOfClass("Humanoid")
                if hum then hum:EquipTool(tool) end
                task.wait(0.05)
            end
            if tool then
                pcall(function() tool:Activate() end)
            end
            lastAutoKillTime = tick()
        end)
    else
        if autoKillConnection then autoKillConnection:Disconnect(); autoKillConnection = nil end
    end
end

-- ===== CHAT SPAMMER =====
local spamConn = nil
local function ToggleChatSpam(state)
    if USER_TIER ~= "premium" then return end
    config.ChatSpam = state
    if state then
        if spamConn then spamConn:Disconnect() end
        spamConn = task.spawn(function()
            while config.ChatSpam do
                pcall(function()
                    local txt = "KABAN HUB ON TOP | t.me/kabanhub"
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(txt, "All")
                end)
                task.wait(5)
            end
        end)
    else
        -- просто останавливаем цикл
    end
end

-- ===== KILL FEED =====
local killFeedGui = nil
local function ToggleKillFeed(state)
    if USER_TIER ~= "premium" then return end
    config.KillFeed = state
    if state then
        if killFeedGui then killFeedGui:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "KABAN_KILLFEED"
        gui.Parent = CoreGui
        gui.ResetOnSpawn = false
        ProtectGui(gui)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 200)
        frame.Position = UDim2.new(1, -310, 0, 100)
        frame.BackgroundTransparency = 0.5
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = frame
        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 4)
        list.Parent = frame
        killFeedGui = {gui = gui, frame = frame}
    else
        if killFeedGui then killFeedGui.gui:Destroy(); killFeedGui = nil end
    end
end

-- хук на убийства
Track("killfeed_hook", RunService.Heartbeat:Connect(function()
    if not config.KillFeed or not killFeedGui then return end
    -- проверим что кто-то умер
    for _, pl in ipairs(Players:GetPlayers()) do
        local char = pl.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 and not pl:GetAttribute("KABAN_DEAD_LOGGED") then
                pl:SetAttribute("KABAN_DEAD_LOGGED", true)
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 20)
                lbl.BackgroundTransparency = 1
                lbl.Text = "💀 " .. pl.Name .. " (" .. GetRole(pl) .. ")"
                lbl.TextColor3 = ROLE_COLORS[GetRole(pl)] or Color3.fromRGB(255, 255, 255)
                lbl.TextSize = 12
                lbl.Font = Enum.Font.GothamBold
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = killFeedGui.frame
                task.delay(5, function()
                    if lbl and lbl.Parent then lbl:Destroy() end
                end)
            elseif hum and hum.Health > 0 then
                pl:SetAttribute("KABAN_DEAD_LOGGED", false)
            end
        end
    end
end))

-- ===== SERVER HOP =====
local function ServerHop()
    if USER_TIER ~= "premium" then return end
    pcall(function()
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return end
        local res = req({
            Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        })
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            for _, srv in ipairs(data.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    return
                end
            end
        end
    end)
end

local function Rejoin()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- ===== СНЕГ =====
local function CreateSnow(parent)
    for i = 1, 50 do
        local sf = Instance.new("Frame")
        sf.Name = "Snowflake" .. i
        sf.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        sf.Position = UDim2.new(math.random(), 0, math.random() - 1, 0)
        sf.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sf.BackgroundTransparency = math.random(30, 70)/100
        sf.BorderSizePixel = 0
        sf.ZIndex = 10
        sf.Parent = parent
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = sf
        table.insert(snowflakes, {
            frame = sf,
            speed = math.random(60, 160),
            drift = math.random(-20, 20)
        })
    end
end

Track("snow_anim", RunService.RenderStepped:Connect(function(dt)
    for _, snow in ipairs(snowflakes) do
        if snow.frame and snow.frame.Parent then
            local pos = snow.frame.Position
            local newY = pos.Y.Scale + snow.speed * dt * 0.01
            local newX = pos.X.Scale + snow.drift * dt * 0.001
            if newY > 1 then
                newY = -0.05
                newX = math.random()
            end
            if newX > 1 then newX = 0 end
            if newX < 0 then newX = 1 end
            snow.frame.Position = UDim2.new(newX, 0, newY, 0)
        end
    end
end))

-- ===== МЕНЮ =====
local function CreateMM2Hub()
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "KABAN_MM2" then child:Destroy() end
    end
    snowflakes = {}
    for player, _ in pairs(espObjects) do
        RemoveESPForPlayer(player)
    end

    local isPremium = (USER_TIER == "premium")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KABAN_MM2"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ProtectGui(ScreenGui)

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 620, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = isPremium and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(150, 200, 255)
    MainStroke.Thickness = 2
    MainStroke.Transparency = 0.2
    MainStroke.Parent = MainFrame

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 10, 25))
    })
    MainGradient.Rotation = 45
    MainGradient.Parent = MainFrame

    CreateSnow(MainFrame)

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 35, 65)
    TitleBar.BackgroundTransparency = 0.2
    TitleBar.BorderSizePixel = 0
    TitleBar.ZIndex = 100
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 16)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -280, 1, 0)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = SCRIPT_NAME
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 20
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 101
    TitleLabel.Parent = TitleBar

    local tierBadge = Instance.new("TextLabel")
    tierBadge.Size = UDim2.new(0, 90, 0, 22)
    tierBadge.Position = UDim2.new(1, -265, 0.5, -11)
    tierBadge.BackgroundColor3 = isPremium and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(0, 150, 80)
    tierBadge.BackgroundTransparency = 0.2
    tierBadge.Text = isPremium and "PREMIUM" or "BASIC"
    tierBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    tierBadge.TextSize = 12
    tierBadge.Font = Enum.Font.GothamBold
    tierBadge.ZIndex = 101
    tierBadge.Parent = TitleBar

    local tierCorner = Instance.new("UICorner")
    tierCorner.CornerRadius = UDim.new(0, 6)
    tierCorner.Parent = tierBadge

    local FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(0, 80, 0, 30)
    FPSLabel.Position = UDim2.new(1, -175, 0.5, -15)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.Text = "FPS: 60"
    FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    FPSLabel.TextSize = 13
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.ZIndex = 101
    FPSLabel.Parent = TitleBar

    Track("fps_update", RunService.RenderStepped:Connect(function()
        if FPSLabel and FPSLabel.Parent then
            FPSLabel.Text = "FPS: " .. currentFPS
        end
    end))

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    MinimizeBtn.Position = UDim2.new(1, -85, 0, 8)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 170)
    MinimizeBtn.BackgroundTransparency = 0.3
    MinimizeBtn.Text = "⇕"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 22
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.ZIndex = 101
    MinimizeBtn.Parent = TitleBar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 8)
    MinCorner.Parent = MinimizeBtn

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -45, 0, 8)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.BackgroundTransparency = 0.3
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.ZIndex = 101
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn

    CloseBtn.MouseButton1Click:Connect(function()
        if config.ESP then ToggleESP(false) end
        if config.Speed then ToggleSpeed(false) end
        if config.Noclip then ToggleNoclip(false) end
        if config.Fly then ToggleFly(false) end
        if config.AutoJump then ToggleAutoJump(false) end
        if config.InfiniteJump then ToggleInfiniteJump(false) end
        if config.AntiFling then ToggleAntiFling(false) end
        if config.XRay then ApplyXRay(false) end
        if config.Aim then ToggleAim(false) end
        if config.SilentAim then ToggleSilentAim(false) end
        if config.AutoKill then ToggleAutoKill(false) end
        if config.ItemESP then ToggleItemESP(false) end
        if config.TrapESP then ToggleTrapESP(false) end
        if config.PlayerTracker then TogglePlayerTracker(false) end
        if config.Crosshair then ToggleCrosshair(false) end
        if config.AntiBlind then ToggleAntiBlind(false) end
        if config.KillFeed then ToggleKillFeed(false) end
        if config.Stretch43 then ApplyStretch43(false) end
        if fovCircle then fovCircle.gui:Destroy(); fovCircle = nil end
        RestoreGraphics()
        DisconnectAll()
        snowflakes = {}
        ScreenGui:Destroy()
    end)

    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 120, 1, -60)
    SideBar.Position = UDim2.new(0, 0, 0, 50)
    SideBar.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
    SideBar.BackgroundTransparency = 0.3
    SideBar.BorderSizePixel = 0
    SideBar.ZIndex = 100
    SideBar.Parent = MainFrame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -130, 1, -70)
    ContentFrame.Position = UDim2.new(0, 125, 0, 60)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 100
    ContentFrame.Parent = MainFrame

    local MainSlide = Instance.new("ScrollingFrame")
    MainSlide.Size = UDim2.new(1, 0, 1, 0)
    MainSlide.BackgroundTransparency = 1
    MainSlide.CanvasSize = UDim2.new(0, 0, 0, 900)
    MainSlide.ScrollBarThickness = 6
    MainSlide.ScrollBarImageColor3 = Color3.fromRGB(180, 220, 255)
    MainSlide.ZIndex = 101
    MainSlide.Visible = true
    MainSlide.Parent = ContentFrame

    local VisualSlide = Instance.new("ScrollingFrame")
    VisualSlide.Size = UDim2.new(1, 0, 1, 0)
    VisualSlide.BackgroundTransparency = 1
    VisualSlide.CanvasSize = UDim2.new(0, 0, 0, 900)
    VisualSlide.ScrollBarThickness = 6
    VisualSlide.ScrollBarImageColor3 = Color3.fromRGB(180, 220, 255)
    VisualSlide.ZIndex = 101
    VisualSlide.Visible = false
    VisualSlide.Parent = ContentFrame

    local ExtraSlide = Instance.new("ScrollingFrame")
    ExtraSlide.Size = UDim2.new(1, 0, 1, 0)
    ExtraSlide.BackgroundTransparency = 1
    ExtraSlide.CanvasSize = UDim2.new(0, 0, 0, 900)
    ExtraSlide.ScrollBarThickness = 6
    ExtraSlide.ScrollBarImageColor3 = Color3.fromRGB(180, 220, 255)
    ExtraSlide.ZIndex = 101
    ExtraSlide.Visible = false
    ExtraSlide.Parent = ContentFrame

    local tabButtons = {}
    local function CreateTabButton(name, y)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = (name == "Main") and Color3.fromRGB(60, 100, 180) or Color3.fromRGB(30, 50, 80)
        btn.BackgroundTransparency = 0.2
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 101
        btn.Parent = SideBar
        table.insert(tabButtons, btn)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 170, 220)
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            activeTab = name
            MainSlide.Visible = (name == "Main")
            VisualSlide.Visible = (name == "Visual")
            ExtraSlide.Visible = (name == "Extra")
            for _, b in ipairs(tabButtons) do
                b.BackgroundColor3 = (b.Text == name) and Color3.fromRGB(60, 100, 180) or Color3.fromRGB(30, 50, 80)
            end
        end)
    end

    CreateTabButton("Main", 10)
    CreateTabButton("Visual", 60)
    CreateTabButton("Extra", 110)

    local function CreateToggle(name, parent, x, y, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.48, 0, 0, 45)
        container.Position = UDim2.new(x, 0, 0, y)
        container.BackgroundColor3 = Color3.fromRGB(20, 35, 65)
        container.BackgroundTransparency = 0.2
        container.BorderSizePixel = 0
        container.ZIndex = 102
        container.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = container

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 170, 220)
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.62, 0, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(230, 245, 255)
        label.TextSize = 11
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 103
        label.Parent = container

        local toggleBg = Instance.new("Frame")
        toggleBg.Size = UDim2.new(0, 40, 0, 20)
        toggleBg.Position = UDim2.new(1, -50, 0.5, -10)
        toggleBg.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
        toggleBg.BorderSizePixel = 0
        toggleBg.ZIndex = 103
        toggleBg.Parent = container

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 10)
        toggleCorner.Parent = toggleBg

        local toggleCircle = Instance.new("Frame")
        toggleCircle.Size = UDim2.new(0, 16, 0, 16)
        toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
        toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleCircle.BorderSizePixel = 0
        toggleCircle.ZIndex = 104
        toggleCircle.Parent = toggleBg

        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = toggleCircle

        local state = false
        local function UpdateVisual()
            if state then
                toggleBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                toggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
                stroke.Color = Color3.fromRGB(0, 255, 150)
            else
                toggleBg.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
                toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
                stroke.Color = Color3.fromRGB(120, 170, 220)
            end
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 105
        btn.Parent = container

        btn.MouseButton1Click:Connect(function()
            state = not state
            UpdateVisual()
            callback(state)
        end)

        UpdateVisual()
        return container
    end

    local function CreateButton(name, parent, x, y, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 0, 40)
        btn.Position = UDim2.new(x, 0, 0, y)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 80, 140)
        btn.BackgroundTransparency = 0.2
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 102
        btn.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 170, 220)
        stroke.Thickness = 1
        stroke.Transparency = 0.4
        stroke.Parent = btn

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- ===== MAIN SLIDE =====
    CreateToggle("ESP (Roles)", MainSlide, 0, 0, ToggleESP)
    CreateToggle("SPEED", MainSlide, 0.52, 0, ToggleSpeed)
    CreateToggle("FLY", MainSlide, 0, 50, ToggleFly)
    CreateToggle("AUTO-JUMP", MainSlide, 0.52, 50, ToggleAutoJump)
    CreateToggle("FULLBRIGHT", MainSlide, 0, 100, ApplyFullbright)
    CreateToggle("NO-FOG", MainSlide, 0.52, 100, ApplyNoFog)

    if isPremium then
        CreateToggle("NOCLIP", MainSlide, 0, 150, ToggleNoclip)
        CreateToggle("INF-JUMP", MainSlide, 0.52, 150, ToggleInfiniteJump)
        CreateToggle("ANTI-FLING", MainSlide, 0, 200, ToggleAntiFling)
        CreateButton("→ К ШЕРИФУ", MainSlide, 0.52, 200, Color3.fromRGB(30, 80, 180), function() TeleportToRole("Sheriff") end)
        CreateButton("→ К УБИЙЦЕ", MainSlide, 0, 250, Color3.fromRGB(180, 30, 30), function() TeleportToRole("Murderer") end)
        CreateButton("→ К ПИСТОЛЕТУ", MainSlide, 0.52, 250, Color3.fromRGB(180, 140, 30), TeleportToGun)
        CreateButton("→ НА СПАВН", MainSlide, 0, 300, Color3.fromRGB(80, 120, 180), TeleportToSpawn)
        CreateToggle("AIMBOT", MainSlide, 0.52, 300, ToggleAim)
        CreateToggle("SILENT AIM", MainSlide, 0, 350, ToggleSilentAim)
        CreateToggle("AUTO-KILL", MainSlide, 0.52, 350, ToggleAutoKill)
        CreateToggle("SHOW FOV", MainSlide, 0, 400, function(state)
            config.ShowFOV = state
            UpdateFOVCircle()
        end)

        -- выбор цели
        local targetLabel = Instance.new("TextLabel")
        targetLabel.Size = UDim2.new(1, 0, 0, 20)
        targetLabel.Position = UDim2.new(0, 0, 0, 450)
        targetLabel.BackgroundTransparency = 1
        targetLabel.Text = "ЦЕЛЬ AIMBOT: Murderer"
        targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        targetLabel.TextSize = 12
        targetLabel.Font = Enum.Font.GothamBold
        targetLabel.TextXAlignment = Enum.TextXAlignment.Left
        targetLabel.ZIndex = 102
        targetLabel.Parent = MainSlide

        local targetButtons = {}
        local function SetTarget(t)
            config.AimTarget = t
            targetLabel.Text = "ЦЕЛЬ AIMBOT: " .. t
            for _, b in ipairs(targetButtons) do
                b.BackgroundColor3 = (b:GetAttribute("target") == t) and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(30, 50, 80)
            end
        end

        for i, t in ipairs({"Murderer", "Sheriff", "Both"}) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.31, 0, 0, 32)
            btn.Position = UDim2.new((i-1)*0.33, 0, 0, 472)
            btn.BackgroundColor3 = (t == "Murderer") and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(30, 50, 80)
            btn.BackgroundTransparency = 0.2
            btn.Text = t
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 11
            btn.Font = Enum.Font.GothamBold
            btn.ZIndex = 102
            btn.Parent = MainSlide
            btn:SetAttribute("target", t)

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = btn

            btn.MouseButton1Click:Connect(function() SetTarget(t) end)
            table.insert(targetButtons, btn)
        end

        -- FOV слайдер
        local FOVLabel = Instance.new("TextLabel")
        FOVLabel.Size = UDim2.new(0.48, 0, 0, 20)
        FOVLabel.Position = UDim2.new(0, 0, 0, 510)
        FOVLabel.BackgroundTransparency = 1
        FOVLabel.Text = "FOV: 120"
        FOVLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
        FOVLabel.TextSize = 12
        FOVLabel.Font = Enum.Font.GothamBold
        FOVLabel.ZIndex = 102
        FOVLabel.Parent = MainSlide

        local FOVSlider = Instance.new("TextButton")
        FOVSlider.Size = UDim2.new(0.48, 0, 0, 20)
        FOVSlider.Position = UDim2.new(0, 0, 0, 530)
        FOVSlider.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
        FOVSlider.Text = ""
        FOVSlider.ZIndex = 102
        FOVSlider.Parent = MainSlide

        local FOVCorner = Instance.new("UICorner")
        FOVCorner.CornerRadius = UDim.new(0, 5)
        FOVCorner.Parent = FOVSlider

        local FOVFill = Instance.new("Frame")
        FOVFill.Size = UDim2.new(0.5, 0, 1, 0)
        FOVFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
        FOVFill.BorderSizePixel = 0
        FOVFill.ZIndex = 103
        FOVFill.Parent = FOVSlider

        local FOVFillCorner = Instance.new("UICorner")
        FOVFillCorner.CornerRadius = UDim.new(0, 5)
        FOVFillCorner.Parent = FOVFill

        local fovSliderActive = false
        local function UpdateFOVFromX(x)
            local percent = math.clamp(x / FOVSlider.AbsoluteSize.X, 0, 1)
            config.AimFOV = math.floor(50 + percent * 250)
            FOVFill.Size = UDim2.new(percent, 0, 1, 0)
            FOVLabel.Text = "FOV: " .. config.AimFOV
            UpdateFOVCircle()
        end

        FOVSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fovSliderActive = true
                UpdateFOVFromX(input.Position.X - FOVSlider.AbsolutePosition.X)
            end
        end)

        Track("fov_move", UserInputService.InputChanged:Connect(function(input)
            if fovSliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateFOVFromX(input.Position.X - FOVSlider.AbsolutePosition.X)
            end
        end))

        Track("fov_end", UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fovSliderActive = false
            end
        end))

        -- Smooth
        local SmoothLabel = Instance.new("TextLabel")
        SmoothLabel.Size = UDim2.new(0.48, 0, 0, 20)
        SmoothLabel.Position = UDim2.new(0.52, 0, 0, 510)
        SmoothLabel.BackgroundTransparency = 1
        SmoothLabel.Text = "SMOOTH: 0.5"
        SmoothLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
        SmoothLabel.TextSize = 12
        SmoothLabel.Font = Enum.Font.GothamBold
        SmoothLabel.ZIndex = 102
        SmoothLabel.Parent = MainSlide

        local SmoothSlider = Instance.new("TextButton")
        SmoothSlider.Size = UDim2.new(0.48, 0, 0, 20)
        SmoothSlider.Position = UDim2.new(0.52, 0, 0, 530)
        SmoothSlider.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
        SmoothSlider.Text = ""
        SmoothSlider.ZIndex = 102
        SmoothSlider.Parent = MainSlide

        local SmoothCorner = Instance.new("UICorner")
        SmoothCorner.CornerRadius = UDim.new(0, 5)
        SmoothCorner.Parent = SmoothSlider

        local SmoothFill = Instance.new("Frame")
        SmoothFill.Size = UDim2.new(0.5, 0, 1, 0)
        SmoothFill.BackgroundColor3 = Color3.fromRGB(255, 150, 100)
        SmoothFill.BorderSizePixel = 0
        SmoothFill.ZIndex = 103
        SmoothFill.Parent = SmoothSlider

        local SmoothFillCorner = Instance.new("UICorner")
        SmoothFillCorner.CornerRadius = UDim.new(0, 5)
        SmoothFillCorner.Parent = SmoothFill

        local smoothSliderActive = false
        local function UpdateSmoothFromX(x)
            local percent = math.clamp(x / SmoothSlider.AbsoluteSize.X, 0, 1)
            config.AimSmooth = math.floor(percent * 100) / 100
            SmoothFill.Size = UDim2.new(percent, 0, 1, 0)
            SmoothLabel.Text = "SMOOTH: " .. config.AimSmooth
        end

        SmoothSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                smoothSliderActive = true
                UpdateSmoothFromX(input.Position.X - SmoothSlider.AbsolutePosition.X)
            end
        end)

        Track("smooth_move", UserInputService.InputChanged:Connect(function(input)
            if smoothSliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                UpdateSmoothFromX(input.Position.X - SmoothSlider.AbsolutePosition.X)
            end
        end))

        Track("smooth_end", UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                smoothSliderActive = false
            end
        end))
    else
        local basicBadge = Instance.new("TextLabel")
        basicBadge.Size = UDim2.new(1, 0, 0, 140)
        basicBadge.Position = UDim2.new(0, 0, 0, 150)
        basicBadge.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
        basicBadge.BackgroundTransparency = 0.4
        basicBadge.Text = "🟢 BASIC ТАРИФ\n\nДоступно: ESP, Speed, Fly, Auto-Jump,\nFullbright, No-Fog, FPS, Оптимизация, Растяг\n\n🔴 В PREMIUM: Noclip, AimBot, Silent-Aim,\nAutoKill, X-Ray, TP, Anti-Fling, Item ESP,\nTrap ESP, Player Tracker, Crosshair, KillFeed,\nAnti-Blind, Footstep, Inf-Jump, Server Hop"
        basicBadge.TextColor3 = Color3.fromRGB(150, 255, 200)
        basicBadge.TextSize = 11
        basicBadge.Font = Enum.Font.GothamBold
        basicBadge.TextWrapped = true
        basicBadge.ZIndex = 102
        basicBadge.Parent = MainSlide

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 10)
        badgeCorner.Parent = basicBadge

        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Color = Color3.fromRGB(0, 200, 120)
        badgeStroke.Thickness = 1
        badgeStroke.Transparency = 0.4
        badgeStroke.Parent = basicBadge
    end

    -- Speed слайдер
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0.48, 0, 0, 20)
    SpeedLabel.Position = UDim2.new(0, 0, 0, isPremium and 570 or 310)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "SPEED: 50"
    SpeedLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
    SpeedLabel.TextSize = 12
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.ZIndex = 102
    SpeedLabel.Parent = MainSlide

    local SpeedSlider = Instance.new("TextButton")
    SpeedSlider.Size = UDim2.new(0.48, 0, 0, 20)
    SpeedSlider.Position = UDim2.new(0, 0, 0, isPremium and 590 or 330)
    SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
    SpeedSlider.Text = ""
    SpeedSlider.ZIndex = 102
    SpeedSlider.Parent = MainSlide

    local SpeedCorner = Instance.new("UICorner")
    SpeedCorner.CornerRadius = UDim.new(0, 5)
    SpeedCorner.Parent = SpeedSlider

    local SpeedFill = Instance.new("Frame")
    SpeedFill.Size = UDim2.new(0.3, 0, 1, 0)
    SpeedFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    SpeedFill.BorderSizePixel = 0
    SpeedFill.ZIndex = 103
    SpeedFill.Parent = SpeedSlider

    local SpeedFillCorner = Instance.new("UICorner")
    SpeedFillCorner.CornerRadius = UDim.new(0, 5)
    SpeedFillCorner.Parent = SpeedFill

    local sliderActive = false
    local function UpdateSpeedFromX(x)
        local percent = math.clamp(x / SpeedSlider.AbsoluteSize.X, 0, 1)
        config.SpeedValue = math.floor(16 + percent * 184)
        SpeedFill.Size = UDim2.new(percent, 0, 1, 0)
        SpeedLabel.Text = "SPEED: " .. config.SpeedValue
    end

    SpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderActive = true
            UpdateSpeedFromX(input.Position.X - SpeedSlider.AbsolutePosition.X)
        end
    end)

    Track("speed_move", UserInputService.InputChanged:Connect(function(input)
        if sliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSpeedFromX(input.Position.X - SpeedSlider.AbsolutePosition.X)
        end
    end))

    Track("speed_end", UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderActive = false
        end
    end))

    -- Легенда
    local legendY = isPremium and 630 or 370
    local legendData = {
        {"Sheriff", Color3.fromRGB(0, 100, 255)},
        {"Murderer", Color3.fromRGB(255, 0, 0)},
        {"Innocent", Color3.fromRGB(0, 255, 0)}
    }
    for i, data in ipairs(legendData) do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, 10, 0, legendY + (i-1)*18)
        dot.BackgroundColor3 = data[2]
        dot.BorderSizePixel = 0
        dot.ZIndex = 102
        dot.Parent = MainSlide

        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 0, 18)
        lbl.Position = UDim2.new(0, 28, 0, legendY + (i-1)*18)
        lbl.BackgroundTransparency = 1
        lbl.Text = data[1]
        lbl.TextColor3 = data[2]
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 102
        lbl.Parent = MainSlide
    end

    -- ===== VISUAL SLIDE =====
    local VisualTitle = Instance.new("TextLabel")
    VisualTitle.Size = UDim2.new(1, 0, 0, 25)
    VisualTitle.BackgroundTransparency = 1
    VisualTitle.Text = "VISUAL / FPS / OPTIMIZATION"
    VisualTitle.TextColor3 = Color3.fromRGB(180, 220, 255)
    VisualTitle.TextSize = 14
    VisualTitle.Font = Enum.Font.GothamBold
    VisualTitle.TextXAlignment = Enum.TextXAlignment.Left
    VisualTitle.ZIndex = 102
    VisualTitle.Parent = VisualSlide

    local FPSValueLabel = Instance.new("TextLabel")
    FPSValueLabel.Size = UDim2.new(1, 0, 0, 20)
    FPSValueLabel.Position = UDim2.new(0, 0, 0, 30)
    FPSValueLabel.BackgroundTransparency = 1
    FPSValueLabel.Text = "Реальный: 60 FPS"
    FPSValueLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
    FPSValueLabel.TextSize = 12
    FPSValueLabel.Font = Enum.Font.Gotham
    FPSValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSValueLabel.ZIndex = 102
    FPSValueLabel.Parent = VisualSlide

    Track("fps_visual_update", RunService.RenderStepped:Connect(function()
        if FPSValueLabel and FPSValueLabel.Parent then
            FPSValueLabel.Text = "Реальный: " .. currentFPS .. " FPS (лимит: " .. config.FPS .. ")"
        end
    end))

    for i, fps in ipairs({30, 60, 90, 120, 240}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.18, 0, 0, 35)
        btn.Position = UDim2.new((i-1)*0.20, 0, 0, 60)
        btn.BackgroundColor3 = (fps == 60) and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(30, 50, 80)
        btn.BackgroundTransparency = 0.2
        btn.Text = fps .. " FPS"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 102
        btn.Parent = VisualSlide

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            ApplyFPSBoost(fps)
        end)
    end

    CreateButton("⚡ ОПТИМИЗАЦИЯ", VisualSlide, 0, 110, Color3.fromRGB(200, 100, 0), ApplyOptimization)

    local stretchTitle = Instance.new("TextLabel")
    stretchTitle.Size = UDim2.new(1, 0, 0, 20)
    stretchTitle.Position = UDim2.new(0, 0, 0, 160)
    stretchTitle.BackgroundTransparency = 1
    stretchTitle.Text = "РАСТЯГ ЭКРАНА"
    stretchTitle.TextColor3 = Color3.fromRGB(150, 255, 200)
    stretchTitle.TextSize = 13
    stretchTitle.Font = Enum.Font.GothamBold
    stretchTitle.TextXAlignment = Enum.TextXAlignment.Left
    stretchTitle.ZIndex = 102
    stretchTitle.Parent = VisualSlide

    CreateToggle("РАСТЯГ 4:3", VisualSlide, 0, 182, ApplyStretch43)

    -- Время суток
    local timeTitle = Instance.new("TextLabel")
    timeTitle.Size = UDim2.new(1, 0, 0, 20)
    timeTitle.Position = UDim2.new(0, 0, 0, 235)
    timeTitle.BackgroundTransparency = 1
    timeTitle.Text = "ВРЕМЯ СУТОК"
    timeTitle.TextColor3 = Color3.fromRGB(150, 200, 255)
    timeTitle.TextSize = 13
    timeTitle.Font = Enum.Font.GothamBold
    timeTitle.TextXAlignment = Enum.TextXAlignment.Left
    timeTitle.ZIndex = 102
    timeTitle.Parent = VisualSlide

    CreateButton("УТРО", VisualSlide, 0, 258, Color3.fromRGB(255, 180, 80), function() ApplyTimeChange(6) end)
    CreateButton("ДЕНЬ", VisualSlide, 0.52, 258, Color3.fromRGB(100, 180, 255), function() ApplyTimeChange(14) end)
    CreateButton("ВЕЧЕР", VisualSlide, 0, 305, Color3.fromRGB(200, 100, 80), function() ApplyTimeChange(19) end)
    CreateButton("НОЧЬ", VisualSlide, 0.52, 305, Color3.fromRGB(50, 50, 100), function() ApplyTimeChange(0) end)

    if isPremium then
        CreateToggle("X-RAY", VisualSlide, 0, 355, ApplyXRay)
        CreateToggle("ITEM ESP", VisualSlide, 0.52, 355, ToggleItemESP)
        CreateToggle("TRAP ESP", VisualSlide, 0, 405, ToggleTrapESP)
        CreateToggle("PLAYER TRACKER", VisualSlide, 0.52, 405, TogglePlayerTracker)
        CreateToggle("CROSSHAIR", VisualSlide, 0, 455, ToggleCrosshair)
        CreateToggle("ANTI-BLIND", VisualSlide, 0.52, 455, ToggleAntiBlind)
        CreateToggle("FOOTSTEP TRACKER", VisualSlide, 0, 505, ToggleFootstepTracker)
        CreateToggle("KILL FEED", VisualSlide, 0.52, 505, ToggleKillFeed)
        CreateButton("RESTORE GRAPHICS", VisualSlide, 0, 555, Color3.fromRGB(80, 120, 180), RestoreGraphics)
    else
        local visualBadge = Instance.new("TextLabel")
        visualBadge.Size = UDim2.new(1, 0, 0, 100)
        visualBadge.Position = UDim2.new(0, 0, 0, 355)
        visualBadge.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
        visualBadge.BackgroundTransparency = 0.4
        visualBadge.Text = "🟢 BASIC\n\nX-Ray, Item ESP, Trap ESP, Player Tracker,\nCrosshair, Anti-Blind, Footstep, KillFeed\nдоступны только в PREMIUM"
        visualBadge.TextColor3 = Color3.fromRGB(150, 255, 200)
        visualBadge.TextSize = 11
        visualBadge.Font = Enum.Font.GothamBold
        visualBadge.TextWrapped = true
        visualBadge.ZIndex = 102
        visualBadge.Parent = VisualSlide

        local vbCorner = Instance.new("UICorner")
        vbCorner.CornerRadius = UDim.new(0, 10)
        vbCorner.Parent = visualBadge

        local vbStroke = Instance.new("UIStroke")
        vbStroke.Color = Color3.fromRGB(0, 200, 120)
        vbStroke.Thickness = 1
        vbStroke.Transparency = 0.4
        vbStroke.Parent = visualBadge
    end

    -- ===== EXTRA SLIDE =====
    local ExtraTitle = Instance.new("TextLabel")
    ExtraTitle.Size = UDim2.new(1, 0, 0, 25)
    ExtraTitle.BackgroundTransparency = 1
    ExtraTitle.Text = "EXTRA / UTILITIES"
    ExtraTitle.TextColor3 = Color3.fromRGB(255, 180, 100)
    ExtraTitle.TextSize = 14
    ExtraTitle.Font = Enum.Font.GothamBold
    ExtraTitle.TextXAlignment = Enum.TextXAlignment.Left
    ExtraTitle.ZIndex = 102
    ExtraTitle.Parent = ExtraSlide

    -- Player List
    local listY = 35
    local listTitle = Instance.new("TextLabel")
    listTitle.Size = UDim2.new(1, 0, 0, 20)
    listTitle.Position = UDim2.new(0, 0, 0, listY)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "PLAYER LIST"
    listTitle.TextColor3 = Color3.fromRGB(180, 220, 255)
    listTitle.TextSize = 13
    listTitle.Font = Enum.Font.GothamBold
    listTitle.TextXAlignment = Enum.TextXAlignment.Left
    listTitle.ZIndex = 102
    listTitle.Parent = ExtraSlide

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, 0, 0, 200)
    listFrame.Position = UDim2.new(0, 0, 0, listY + 25)
    listFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
    listFrame.BackgroundTransparency = 0.3
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ZIndex = 102
    listFrame.Parent = ExtraSlide

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = listFrame

    local function UpdatePlayerList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        local allPlayers = Players:GetPlayers()
        local count = 0
        for _, pl in ipairs(allPlayers) do
            local role = GetRole(pl)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 22)
            lbl.BackgroundTransparency = 1
            lbl.Text = "  " .. pl.Name .. "  -  " .. role
            lbl.TextColor3 = ROLE_COLORS[role] or Color3.fromRGB(255, 255, 255)
            lbl.TextSize = 11
            lbl.Font = Enum.Font.GothamBold
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 103
            lbl.Parent = listFrame
            count = count + 1
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, count * 25 + 5)
    end

    UpdatePlayerList()
    Track("playerlist_update", RunService.Heartbeat:Connect(function()
        UpdatePlayerList()
    end))

    if isPremium then
        -- Server hop + rejoin
        local hopY = listY + 240
        local hopTitle = Instance.new("TextLabel")
        hopTitle.Size = UDim2.new(1, 0, 0, 20)
        hopTitle.Position = UDim2.new(0, 0, 0, hopY)
        hopTitle.BackgroundTransparency = 1
        hopTitle.Text = "SERVER"
        hopTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
        hopTitle.TextSize = 13
        hopTitle.Font = Enum.Font.GothamBold
        hopTitle.TextXAlignment = Enum.TextXAlignment.Left
        hopTitle.ZIndex = 102
        hopTitle.Parent = ExtraSlide

        CreateButton("SERVER HOP", ExtraSlide, 0, hopY + 25, Color3.fromRGB(180, 60, 60), ServerHop)
        CreateButton("REJOIN", ExtraSlide, 0.52, hopY + 25, Color3.fromRGB(80, 120, 180), Rejoin)

        CreateToggle("CHAT SPAMMER", ExtraSlide, 0, hopY + 75, ToggleChatSpam)
    else
        local extraBadge = Instance.new("TextLabel")
        extraBadge.Size = UDim2.new(1, 0, 0, 100)
        extraBadge.Position = UDim2.new(0, 0, 0, listY + 240)
        extraBadge.BackgroundColor3 = Color3.fromRGB(0, 100, 60)
        extraBadge.BackgroundTransparency = 0.4
        extraBadge.Text = "🟢 BASIC\n\nServer Hop, Rejoin, Chat Spammer\nдоступны только в PREMIUM"
        extraBadge.TextColor3 = Color3.fromRGB(150, 255, 200)
        extraBadge.TextSize = 11
        extraBadge.Font = Enum.Font.GothamBold
        extraBadge.TextWrapped = true
        extraBadge.ZIndex = 102
        extraBadge.Parent = ExtraSlide

        local ebCorner = Instance.new("UICorner")
        ebCorner.CornerRadius = UDim.new(0, 10)
        ebCorner.Parent = extraBadge
    end

    -- ===== ПЕРЕТАСКИВАНИЕ =====
    local dragging = false
    local dragStart, startPos

    local function StartDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end

    MainFrame.InputBegan:Connect(StartDrag)
    TitleBar.InputBegan:Connect(StartDrag)
    SideBar.InputBegan:Connect(StartDrag)
    ContentFrame.InputBegan:Connect(StartDrag)
    MainSlide.InputBegan:Connect(StartDrag)
    VisualSlide.InputBegan:Connect(StartDrag)
    ExtraSlide.InputBegan:Connect(StartDrag)

    Track("global_drag_move", UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    Track("global_drag_end", UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    -- ===== СВОРАЧИВАНИЕ =====
    local restoreBtn = nil
    local ExpandMenu

    ExpandMenu = function()
        if not isMinimized then return end
        isMinimized = false
        MainFrame.Size = UDim2.new(0, 620, 0, 500)
        TitleBar.Visible = true
        SideBar.Visible = true
        ContentFrame.Visible = true
        if restoreBtn then
            restoreBtn:Destroy()
            restoreBtn = nil
        end
        Untrack("mini_move")
        Untrack("mini_end")
        Untrack("mini_begin")
    end

    MinimizeBtn.MouseButton1Click:Connect(function()
        if isMinimized then return end
        isMinimized = true
        MainFrame.Size = UDim2.new(0, 50, 0, 50)
        TitleBar.Visible = false
        SideBar.Visible = false
        ContentFrame.Visible = false

        restoreBtn = Instance.new("TextButton")
        restoreBtn.Name = "RestoreBtn"
        restoreBtn.Size = UDim2.new(1, 0, 1, 0)
        restoreBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
        restoreBtn.Text = "K"
        restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        restoreBtn.TextSize = 22
        restoreBtn.Font = Enum.Font.GothamBold
        restoreBtn.ZIndex = 200
        restoreBtn.Parent = MainFrame

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 16)
        rc.Parent = restoreBtn

        local draggingSquare = false
        local squareMoved = false
        local dragStart, startPos

        Track("mini_begin", restoreBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then                draggingSquare = true
                squareMoved = false
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end))

        Track("mini_move", UserInputService.InputChanged:Connect(function(input)
            if draggingSquare and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                if delta.Magnitude > 5 then
                    squareMoved = true
                    MainFrame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end))

        Track("mini_end", UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if draggingSquare and not squareMoved then
                    ExpandMenu()
                end
                draggingSquare = false
            end
        end))
    end)

    Track("hotkey", UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if isMinimized then
                ExpandMenu()
            else
                MainFrame.Visible = not MainFrame.Visible
            end
        end
    end))

    if isPremium then
        CreateFOVCircle()
        UpdateFOVCircle()
    end

    print("[KABAN] MM2 HUB v5.0 загружен! Тариф: " .. USER_TIER)
end

-- ===== ОКНО КЛЮЧА =====
local function CreateKeyGUI(onSuccess)
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child.Name == "KABAN_KEY" then child:Destroy() end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KABAN_KEY"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    ProtectGui(screenGui)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 280)
    frame.Position = UDim2.new(0.5, -200, 0.5, -140)
    frame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 16)
    frameCorner.Parent = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(150, 200, 240)
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.2
    frameStroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🔑 " .. SCRIPT_NAME
    title.TextColor3 = Color3.fromRGB(220, 240, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 25)
    subtitle.Position = UDim2.new(0, 20, 0, 55)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Введите ключ для доступа"
    subtitle.TextColor3 = Color3.fromRGB(180, 200, 220)
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = frame

    local tierInfo = Instance.new("TextLabel")
    tierInfo.Size = UDim2.new(1, -40, 0, 30)
    tierInfo.Position = UDim2.new(0, 20, 0, 78)
    tierInfo.BackgroundTransparency = 1
    tierInfo.Text = "BASIC: ~15 функций  |  PREMIUM: 30+ функций"
    tierInfo.TextColor3 = Color3.fromRGB(130, 150, 180)
    tierInfo.TextSize = 11
    tierInfo.Font = Enum.Font.Gotham
    tierInfo.Parent = frame

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -40, 0, 45)
    inputFrame.Position = UDim2.new(0, 20, 0, 110)
    inputFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 10)
    inputCorner.Parent = inputFrame

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(100, 140, 180)
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.3
    inputStroke.Parent = inputFrame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Введите ключ..."
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 120, 150)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 16
    textBox.Font = Enum.Font.Gotham
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(1, -40, 0, 45)
    submitBtn.Position = UDim2.new(0, 20, 0, 170)
    submitBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
    submitBtn.BackgroundTransparency = 0.15
    submitBtn.Text = "🔓 АКТИВИРОВАТЬ"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 16
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.Parent = frame

    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 10)
    submitCorner.Parent = submitBtn

    local submitStroke = Instance.new("UIStroke")
    submitStroke.Color = Color3.fromRGB(150, 200, 255)
    submitStroke.Thickness = 1
    submitStroke.Transparency = 0.3
    submitStroke.Parent = submitBtn

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 25)
    statusLabel.Position = UDim2.new(0, 20, 0, 230)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = frame

    local attempts = 0
    local maxAttempts = 5

    submitBtn.MouseButton1Click:Connect(function()
        local key = textBox.Text
        if key == "" then
            statusLabel.Text = "❌ Введите ключ!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end

        local matched = false
        if key == BASIC_KEY then
            USER_TIER = "basic"
            matched = true
        elseif key == PREMIUM_KEY then
            USER_TIER = "premium"
            matched = true
        end

        if matched then
            local isPrem = (USER_TIER == "premium")
            statusLabel.Text = isPrem and "✅ PREMIUM! Загрузка..." or "✅ BASIC! Загрузка..."
            statusLabel.TextColor3 = isPrem and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(100, 255, 150)
            submitBtn.BackgroundColor3 = isPrem and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(0, 180, 80)
            submitBtn.Text = isPrem and "✅ PREMIUM" or "✅ BASIC"
            task.delay(1, function()
                screenGui:Destroy()
                onSuccess()
            end)
        else
            attempts = attempts + 1
            statusLabel.Text = "❌ Неверный ключ! Попытка " .. attempts .. "/" .. maxAttempts
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            textBox.Text = ""
            if attempts >= maxAttempts then
                statusLabel.Text = "❌ Превышено число попыток!"
                submitBtn.Text = "❌ ЗАБЛОКИРОВАНО"
                submitBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                submitBtn.Active = false
            end
        end
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then submitBtn:Activate() end
    end)
end

-- ===== ЗАПУСК =====
CreateKeyGUI(function()
    CreateMM2Hub()
end)
