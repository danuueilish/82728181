local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

FLYING = false
QEfly = true
iyflyspeed = 1
vehicleflyspeed = 1

local flyKeyDown, flyKeyUp

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
end

local function randomString()
    return tostring(math.random(100000,999999))
end

local IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Dekstop
function sFLY(vfly)
    local plr = Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local root = getRoot(char)
    local camera = workspace.CurrentCamera

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end

    local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local lCONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
    local SPEED = 0

    FLYING = true

    local BG = Instance.new("BodyGyro", root)
    local BV = Instance.new("BodyVelocity", root)

    BG.P = 9e4
    BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)

    RunService.RenderStepped:Connect(function()
        if not FLYING then return end

        if not vfly then humanoid.PlatformStand = true end

        if CONTROL.F + CONTROL.B + CONTROL.L + CONTROL.R + CONTROL.Q + CONTROL.E ~= 0 then
            SPEED = 50
        else
            SPEED = 0
        end

        if SPEED ~= 0 then
            BV.Velocity =
                (camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
                ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R,
                (CONTROL.Q + CONTROL.E) * 0.2, 0)).p - camera.CFrame.p)
                * SPEED
            lCONTROL = table.clone(CONTROL)
        else
            BV.Velocity = Vector3.zero
        end

        BG.CFrame = camera.CFrame
    end)

    flyKeyDown = UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        local spd = vfly and vehicleflyspeed or iyflyspeed
        if i.KeyCode == Enum.KeyCode.W then CONTROL.F = spd end
        if i.KeyCode == Enum.KeyCode.S then CONTROL.B = -spd end
        if i.KeyCode == Enum.KeyCode.A then CONTROL.L = -spd end
        if i.KeyCode == Enum.KeyCode.D then CONTROL.R = spd end
        if QEfly and i.KeyCode == Enum.KeyCode.E then CONTROL.Q = spd*2 end
        if QEfly and i.KeyCode == Enum.KeyCode.Q then CONTROL.E = -spd*2 end
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then CONTROL.F = 0 end
        if i.KeyCode == Enum.KeyCode.S then CONTROL.B = 0 end
        if i.KeyCode == Enum.KeyCode.A then CONTROL.L = 0 end
        if i.KeyCode == Enum.KeyCode.D then CONTROL.R = 0 end
        if i.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0 end
        if i.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0 end
    end)
end

function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

-- Mobile
local velocityHandlerName = randomString()
local gyroHandlerName = randomString()
local mfly1, mfly2

function mobilefly(speaker,vfly)
    unmobilefly(speaker)
    FLYING = true

    local root = getRoot(speaker.Character)
    local camera = workspace.CurrentCamera
    local controlModule = require(speaker.PlayerScripts.PlayerModule.ControlModule)

    local bv = Instance.new("BodyVelocity",root)
    bv.Name = velocityHandlerName
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)

    local bg = Instance.new("BodyGyro",root)
    bg.Name = gyroHandlerName
    bg.MaxTorque = Vector3.new(9e9,9e9,9e9)

    mfly2 = RunService.RenderStepped:Connect(function()
        if not FLYING then return end
        local hum = speaker.Character:FindFirstChildOfClass("Humanoid")
        if not vfly then hum.PlatformStand = true end
        bg.CFrame = camera.CFrame
        bv.Velocity = Vector3.zero

        local dir = controlModule:GetMoveVector()
        bv.Velocity += camera.CFrame.RightVector * dir.X * iyflyspeed * 50
        bv.Velocity -= camera.CFrame.LookVector * dir.Z * iyflyspeed * 50
    end)
end

function unmobilefly(speaker)
    FLYING = false
    local root = speaker.Character and getRoot(speaker.Character)
    if root then
        pcall(function() root[velocityHandlerName]:Destroy() end)
        pcall(function() root[gyroHandlerName]:Destroy() end)
    end
    if mfly2 then mfly2:Disconnect() end
end

_G.EnableFly = function()
    if IsOnMobile then
        mobilefly(Players.LocalPlayer)
    else
        NOFLY()
        task.wait()
        sFLY()
    end
end

_G.DisableFly = function()
    if IsOnMobile then
        unmobilefly(Players.LocalPlayer)
    else
        NOFLY()
    end
end

_G.SetFlySpeed = function(v)
    if tonumber(v) then iyflyspeed = tonumber(v) end
end