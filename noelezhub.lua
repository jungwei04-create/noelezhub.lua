--=====================================================
-- NOEL EZ | SPEEDHUB X STYLE
-- Universal | Pantalla de carga + Efecto agua carmesí
--=====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--=====================================================
-- CONFIG (TODO APAGADO)
--=====================================================

local Config = {
    Speed = false,
    WalkSpeed = 90,
    Fly = false,
    FlySpeed = 60,
    Noclip = false,
    ESP = false,
    ESPRange = 1000,
    ShowFPS = true,
    AntiFling = false,
    Tracers = false,
    AntiAFK = false,
    FPSBoost = false,
    RemoveFog = false,
}

local Character, Humanoid, Root

local FlyConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local FlyUpDown = 0

local NoclipConnection = nil
local ESPObjects = {}
local ESPConnection = nil
local FPSConnection = nil
local AntiFlingConnection = nil
local TracersConnection = nil
local TracersObjects = {}
local AntiAFKConnection = nil

local OriginalFog = nil
local OriginalFogEnd = nil
local OriginalFogStart = nil

local FlyUpBtn = nil
local FlyDownBtn = nil

--=====================================================
-- HELPERS
--=====================================================

local function RefreshCharacter()
    Character = Player.Character
    if Character then
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Root = Character:FindFirstChild("HumanoidRootPart")
    end
end

local function IsAlive()
    return Character and Character.Parent and Humanoid and Humanoid.Health > 0 and Root
end

RefreshCharacter()
Player.CharacterAdded:Connect(function()
    task.wait(1)
    RefreshCharacter()
end)

--=====================================================
-- FLY
--=====================================================

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if FlyBodyVelocity then pcall(function() FlyBodyVelocity:Destroy() end) FlyBodyVelocity = nil end
    if FlyBodyGyro then pcall(function() FlyBodyGyro:Destroy() end) FlyBodyGyro = nil end
    if Humanoid then pcall(function() Humanoid.PlatformStand = false end) end
    FlyUpDown = 0
end

local function StartFly()
    RefreshCharacter()
    if not IsAlive() then
        task.wait(1)
        RefreshCharacter()
        if not IsAlive() then
            print("⚠ Fly: personaje no listo")
            return
        end
    end

    StopFly()

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Name = "NoelEZ_FlyVelocity"
    FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.Parent = Root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.Name = "NoelEZ_FlyGyro"
    FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyGyro.P = 1e4
    FlyBodyGyro.D = 100
    FlyBodyGyro.CFrame = Root.CFrame
    FlyBodyGyro.Parent = Root

    Humanoid.PlatformStand = true

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Config.Fly then return end
        if not IsAlive() then StopFly() return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local pcMove = Vector3.zero
        pcall(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then pcMove = pcMove + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then pcMove = pcMove - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then pcMove = pcMove + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then pcMove = pcMove - cam.CFrame.RightVector end
        end)

        local mobileMove = Vector3.zero
        if UserInputService.TouchEnabled then
            local md = Humanoid.MoveDirection
            if md and md.Magnitude > 0.05 then
                mobileMove = md
            end
        end

        local moveDir
        if pcMove.Magnitude > 0.05 then
            moveDir = pcMove
        elseif mobileMove.Magnitude > 0.05 then
            moveDir = mobileMove
        else
            moveDir = Vector3.zero
        end

        local upDown = 0
        pcall(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = upDown + 1 end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDown = upDown - 1 end
        end)
        upDown = upDown + FlyUpDown

        local finalVel = Vector3.zero
        if moveDir.Magnitude > 0.05 then
            finalVel = moveDir.Unit * Config.FlySpeed
        end
        if upDown ~= 0 then
            finalVel = finalVel + Vector3.new(0, upDown * Config.FlySpeed, 0)
        end

        if FlyBodyVelocity then
            FlyBodyVelocity.Velocity = finalVel
        end

        if FlyBodyGyro then
            local camLook = cam.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
            if flatLook.Magnitude > 0.01 then
                FlyBodyGyro.CFrame = CFrame.lookAt(Root.Position, Root.Position + flatLook.Unit)
            else
                FlyBodyGyro.CFrame = CFrame.new(Root.Position)
            end
        end
    end)
    print("🕊 Fly ON")
end

local function ToggleFly(state)
    Config.Fly = state
    if state then
        StartFly()
    else
        StopFly()
        print("🕊 Fly OFF")
    end
    if FlyUpBtn then FlyUpBtn.Visible = state end
    if FlyDownBtn then FlyDownBtn.Visible = state end
end

--=====================================================
-- SPEED
--=====================================================

local function ToggleSpeed(state)
    Config.Speed = state
    RefreshCharacter()
    if Humanoid then
        if state then
            Humanoid.WalkSpeed = Config.WalkSpeed
        else
            Humanoid.WalkSpeed = 16
        end
    end
    print(state and "🚀 Speed ON" or "🚀 Speed OFF")
end

--=====================================================
-- NOCLIP
--=====================================================

local function StopNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
end

local function StartNoclip()
    StopNoclip()
    NoclipConnection = RunService.Stepped:Connect(function()
        if not Config.Noclip or not IsAlive() then return end
        for _, part in ipairs(Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

local function ToggleNoclip(state)
    Config.Noclip = state
    if state then
        StartNoclip()
        print("👻 Noclip ON")
    else
        StopNoclip()
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
        print("👻 Noclip OFF")
    end
end

--=====================================================
-- ESP
--=====================================================

local function CreateESP(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    if targetPlayer == Player then return end

    local targetChar = targetPlayer.Character
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "NoelEZ_ESP"
    highlight.Adornee = targetChar
    highlight.FillColor = Color3.fromRGB(220, 20, 60)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = targetChar

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NoelEZ_Billboard"
    billboard.Adornee = targetRoot
    billboard.Size = UDim2.new(0, 250, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = Config.ESPRange
    billboard.Parent = targetRoot

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 12
    distLabel.Parent = billboard

    ESPObjects[targetPlayer] = {
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        DistLabel = distLabel,
    }
end

local function RemoveESP(targetPlayer)
    if ESPObjects[targetPlayer] then
        pcall(function()
            if ESPObjects[targetPlayer].Highlight then ESPObjects[targetPlayer].Highlight:Destroy() end
            if ESPObjects[targetPlayer].Billboard then ESPObjects[targetPlayer].Billboard:Destroy() end
        end)
        ESPObjects[targetPlayer] = nil
    end
end

local function StopESP()
    for plr, _ in pairs(ESPObjects) do RemoveESP(plr) end
    ESPObjects = {}
    if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
end

local function StartESP()
    StopESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then CreateESP(plr) end
    end
    ESPConnection = Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Config.ESP then CreateESP(plr) end
        end)
    end)
end

local function ToggleESP(state)
    Config.ESP = state
    if state then StartESP() else StopESP() end
end

RunService.RenderStepped:Connect(function()
    if not Config.ESP or not IsAlive() then return end
    for plr, esp in pairs(ESPObjects) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = plr.Character.HumanoidRootPart
            local dist = (Root.Position - targetRoot.Position).Magnitude
            if esp.DistLabel then
                esp.DistLabel.Text = string.format("%.0fm", dist)
            end
            local visible = dist <= Config.ESPRange
            if esp.Billboard then esp.Billboard.Enabled = visible end
            if esp.Highlight then esp.Highlight.Enabled = visible end
        end
    end
end)

--=====================================================
-- ANTI-FLING
--=====================================================

local function StopAntiFling()
    if AntiFlingConnection then AntiFlingConnection:Disconnect() AntiFlingConnection = nil end
end

local function StartAntiFling()
    StopAntiFling()
    AntiFlingConnection = RunService.Heartbeat:Connect(function()
        if not Config.AntiFling then return end
        if not IsAlive() then return end

        for _, obj in ipairs(Root:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity")
               or obj:IsA("BodyThrust") or obj:IsA("BodyForce") then
                if obj.Name ~= "NoelEZ_FlyVelocity" then
                    obj:Destroy()
                end
            end
        end

        pcall(function()
            local angVel = Root.AssemblyAngularVelocity
            if angVel.Magnitude > 100 then
                Root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end)
end

local function ToggleAntiFling(state)
    Config.AntiFling = state
    if state then StartAntiFling() else StopAntiFling() end
end

--=====================================================
-- TRACERS
--=====================================================

local function CreateTracer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    if targetPlayer == Player then return end

    if TracersObjects[targetPlayer] then
        RemoveTracer(targetPlayer)
    end

    local myAttachment = Instance.new("Attachment")
    myAttachment.Name = "NoelEZ_TracerMyAttach"
    myAttachment.Parent = Root

    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        myAttachment:Destroy()
        return
    end

    local targetAttachment = Instance.new("Attachment")
    targetAttachment.Name = "NoelEZ_TracerTargetAttach"
    targetAttachment.Parent = targetRoot

    local beam = Instance.new("Beam")
    beam.Name = "NoelEZ_TracerBeam"
    beam.Attachment0 = myAttachment
    beam.Attachment1 = targetAttachment
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.Color = ColorSequence.new(Color3.fromRGB(220, 20, 60))
    beam.Transparency = NumberSequence.new(0.3)
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Enabled = true
    beam.Parent = myAttachment

    TracersObjects[targetPlayer] = {
        Beam = beam,
        MyAttachment = myAttachment,
        TargetAttachment = targetAttachment,
    }
end

local function RemoveTracer(targetPlayer)
    if TracersObjects[targetPlayer] then
        pcall(function()
            local data = TracersObjects[targetPlayer]
            if data.Beam then data.Beam:Destroy() end
            if data.MyAttachment then data.MyAttachment:Destroy() end
            if data.TargetAttachment then data.TargetAttachment:Destroy() end
        end)
        TracersObjects[targetPlayer] = nil
    end
end

local function StopTracers()
    for plr, _ in pairs(TracersObjects) do RemoveTracer(plr) end
    TracersObjects = {}
    if TracersConnection then TracersConnection:Disconnect() TracersConnection = nil end
end

local function StartTracers()
    StopTracers()
    RefreshCharacter()
    if not IsAlive() then
        task.wait(1)
        RefreshCharacter()
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then CreateTracer(plr) end
    end

    TracersConnection = RunService.Heartbeat:Connect(function()
        if not Config.Tracers then return end
        if not IsAlive() then return end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    if not TracersObjects[plr] then
                        CreateTracer(plr)
                    else
                        local data = TracersObjects[plr]
                        if not data.Beam or not data.Beam.Parent
                        or not data.MyAttachment or not data.MyAttachment.Parent
                        or not data.TargetAttachment or not data.TargetAttachment.Parent then
                            RemoveTracer(plr)
                            CreateTracer(plr)
                        end
                    end
                end
            end
        end
    end)

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Config.Tracers then CreateTracer(plr) end
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        RemoveTracer(plr)
    end)
end

local function ToggleTracers(state)
    Config.Tracers = state
    if state then StartTracers() else StopTracers() end
end

--=====================================================
-- ANTI-AFK
--=====================================================

local function StopAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() AntiAFKConnection = nil end
end

local function StartAntiAFK()
    StopAntiAFK()
    AntiAFKConnection = Player.Idled:Connect(function()
        if not Config.AntiAFK then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function ToggleAntiAFK(state)
    Config.AntiAFK = state
    if state then StartAntiAFK() else StopAntiAFK() end
end

--=====================================================
-- FPS BOOST
--=====================================================

local FPSBoostSettings = {}
local FPSBoostChanged = false

local function StartFPSBoost()
    if FPSBoostChanged then return end
    FPSBoostChanged = true

    pcall(function()
        FPSBoostSettings.RenderQuality = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        FPSBoostSettings.GlobalShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
    end)

    FPSBoostSettings.RemovedEffects = {}
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BlurEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect")
           or obj:IsA("ColorCorrectionEffect") or obj:IsA("DepthOfFieldEffect") then
            table.insert(FPSBoostSettings.RemovedEffects, {Obj = obj, Enabled = obj.Enabled})
            obj.Enabled = false
        end
    end
end

local function StopFPSBoost()
    if not FPSBoostChanged then return end
    FPSBoostChanged = false

    pcall(function()
        if FPSBoostSettings.RenderQuality then
            settings().Rendering.QualityLevel = FPSBoostSettings.RenderQuality
        end
    end)
    pcall(function()
        if FPSBoostSettings.GlobalShadows ~= nil then
            Lighting.GlobalShadows = FPSBoostSettings.GlobalShadows
        end
    end)
    if FPSBoostSettings.RemovedEffects then
        for _, data in ipairs(FPSBoostSettings.RemovedEffects) do
            pcall(function()
                if data.Obj and data.Obj.Parent then data.Obj.Enabled = data.Enabled end
            end)
        end
    end
end

local function ToggleFPSBoost(state)
    Config.FPSBoost = state
    if state then StartFPSBoost() else StopFPSBoost() end
end

--=====================================================
-- REMOVE FOG
--=====================================================

local function StartRemoveFog()
    pcall(function()
        OriginalFog = Lighting.FogColor
        OriginalFogEnd = Lighting.FogEnd
        OriginalFogStart = Lighting.FogStart
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    end)
end

local function StopRemoveFog()
    pcall(function()
        if OriginalFog then Lighting.FogColor = OriginalFog end
        if OriginalFogEnd then Lighting.FogEnd = OriginalFogEnd end
        if OriginalFogStart then Lighting.FogStart = OriginalFogStart end
    end)
end

local function ToggleRemoveFog(state)
    Config.RemoveFog = state
    if state then StartRemoveFog() else StopRemoveFog() end
end

--=====================================================
-- CONTADOR DE FPS
--=====================================================

local FPSLabel = nil
local frameCount = 0
local lastTime = tick()

local function StartFPS()
    if FPSConnection then FPSConnection:Disconnect() end
    frameCount = 0
    lastTime = tick()
    FPSConnection = RunService.RenderStepped:Connect(function()
        frameCount = 
