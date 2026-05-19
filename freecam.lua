if _G.__IY_FREECAM_LOADED then return end
_G.__IY_FREECAM_LOADED = true

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local localPlayer   = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then currentCamera = workspace.CurrentCamera end
end)

-- Spring (proven implementation)
local Spring = {}
Spring.__index = Spring

function Spring.new(freq, pos)
    local self = setmetatable({}, Spring)
    self.f = freq
    self.p = pos
    self.v = pos * 0
    return self
end

function Spring:Update(dt, goal)
    local f      = self.f * 2 * math.pi
    local p0     = self.p
    local v0     = self.v
    local offset = goal - p0
    local decay  = math.exp(-f * dt)
    local p1     = goal + (v0 * dt - offset * (f * dt + 1)) * decay
    local v1     = (f * dt * (offset * f - v0) + v0) * decay
    self.p = p1
    self.v = v1
    return p1
end

function Spring:Reset(pos)
    self.p = pos
    self.v = pos * 0
end

-- State
local SPEED      = 30
local v19        = 0       -- auto-forward
local v16        = 0       -- yaw
local v17        = 0       -- pitch
local v57        = 70      -- fov

local clamp = math.clamp
local rad   = math.rad
local deg   = math.deg

local velSpring  = Spring.new(1,   Vector3.new(0, 0, 0))
local panSpring  = Spring.new(0.7, Vector2.zero)

local fcRunning  = false
local v20        = nil
local hiddenGuis = {}

-- PlayerModule controls (joystick mobile + WASD PC)
local controls = nil
task.spawn(function()
    pcall(function()
        local ps = localPlayer:WaitForChild("PlayerScripts", 10)
        if ps then
            controls = require(ps:WaitForChild("PlayerModule", 10)):GetControls()
        end
    end)
end)

-- PC keyboard fallback
local held = {}
local KEYS = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.S] = true,
    [Enum.KeyCode.A] = true, [Enum.KeyCode.D] = true,
    [Enum.KeyCode.Q] = true, [Enum.KeyCode.E] = true,
}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if KEYS[input.KeyCode] then held[input.KeyCode] = true end
    if fcRunning and input.UserInputType == Enum.UserInputType.MouseButton2 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if KEYS[input.KeyCode] then held[input.KeyCode] = nil end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and fcRunning then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- Mouse rotation (PC - RMB drag)
UserInputService.InputChanged:Connect(function(input, gp)
    if not fcRunning then return end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        and input.UserInputType == Enum.UserInputType.MouseMovement then
        v16 = v16 - input.Delta.X * 0.18
        v17 = clamp(v17 - input.Delta.Y * 0.18, -89, 89)
    end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        v57 = clamp(v57 - input.Position.Z * 3, 20, 100)
    end
end)

-- Touch rotation (mobile - single finger drag)
local touchId = nil
UserInputService.TouchStarted:Connect(function(input, gp)
    if not fcRunning or gp then return end
    if touchId == nil then touchId = input end
end)

UserInputService.TouchMoved:Connect(function(input, gp)
    if not fcRunning or input ~= touchId then return end
    v16 = v16 - input.Delta.X * 0.18
    v17 = clamp(v17 - input.Delta.Y * 0.18, -89, 89)
end)

UserInputService.TouchEnded:Connect(function(input, gp)
    if input == touchId then touchId = nil end
end)

-- Touch pinch zoom (mobile)
local pinchDist = nil
UserInputService.TouchPinch:Connect(function(positions, dist, velocity, state, gp)
    if not fcRunning or gp then return end
    if state == Enum.UserInputState.Begin then
        pinchDist = dist
    elseif state == Enum.UserInputState.Change and pinchDist then
        v57 = clamp(v57 - (dist - pinchDist) * 0.05, 20, 100)
        pinchDist = dist
    else
        pinchDist = nil
    end
end)

local function getMoveVec()
    -- PlayerModule GetMoveVector: works for mobile joystick + PC WASD
    if controls and controls.GetMoveVector then
        local mv = controls:GetMoveVector()
        if mv.Magnitude > 0.01 then
            return Vector3.new(mv.X, 0, mv.Z)
        end
    end
    -- keyboard fallback (Q/E for up/down not in GetMoveVector)
    return Vector3.new(
        (held[Enum.KeyCode.D] and 1 or 0) - (held[Enum.KeyCode.A] and 1 or 0),
        (held[Enum.KeyCode.E] and 1 or 0) - (held[Enum.KeyCode.Q] and 1 or 0),
        (held[Enum.KeyCode.S] and 1 or 0) - (held[Enum.KeyCode.W] and 1 or 0)
    )
end

local function update(dt)
    if currentCamera.CameraType ~= Enum.CameraType.Scriptable then
        currentCamera.CameraType = Enum.CameraType.Scriptable
    end

    local pan = panSpring:Update(dt, Vector2.new(v17, v16))
    local vel = velSpring:Update(dt, getMoveVec())
    local cf  = CFrame.Angles(0, rad(pan.Y), 0) * CFrame.Angles(rad(pan.X), 0, 0)
    local pos = currentCamera.CFrame.Position
        + (cf.RightVector * vel.X
        +  cf.UpVector    * vel.Y
        -  cf.LookVector  * vel.Z) * SPEED * dt
        +  cf.LookVector  * SPEED * v19 * dt
    currentCamera.CFrame    = CFrame.new(pos) * cf
    currentCamera.FieldOfView = v57
end

local function hideAllGuis()
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            gui.Enabled = false
            hiddenGuis[gui] = true
        end
    end
end

local function restoreAllGuis()
    for gui in pairs(hiddenGuis) do
        pcall(function() gui.Enabled = true end)
    end
    hiddenGuis = {}
end

function _G.EnableFreecam()
    if fcRunning then return end
    fcRunning = true

    local o1, o2 = currentCamera.CFrame:ToOrientation()
    v17 = deg(o1)
    v16 = deg(o2)
    v57 = currentCamera.FieldOfView

    velSpring:Reset(Vector3.new(0, 0, 0))
    panSpring:Reset(Vector2.new(v17, v16))
    for k in pairs(held) do held[k] = nil end

    if localPlayer.Character then
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetAttribute("__Saved_WalkSpeed", hum.WalkSpeed)
            hum:SetAttribute("__Saved_JumpPower",  hum.JumpPower)
            hum.WalkSpeed  = 0
            hum.JumpPower  = 0
            hum.AutoRotate = false
        end
    end

    currentCamera.CameraType = Enum.CameraType.Scriptable
    hideAllGuis()
    v20 = RunService.RenderStepped:Connect(update)
end

function _G.DisableFreecam()
    if not fcRunning then return end
    fcRunning = false

    if v20 then v20:Disconnect(); v20 = nil end
    for k in pairs(held) do held[k] = nil end
    touchId   = nil
    pinchDist = nil
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    if localPlayer.Character then
        local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local ws = hum:GetAttribute("__Saved_WalkSpeed")
            local jp = hum:GetAttribute("__Saved_JumpPower")
            if ws then hum.WalkSpeed  = ws end
            if jp then hum.JumpPower  = jp end
            hum.AutoRotate = true
        end
    end

    currentCamera.CameraType = Enum.CameraType.Custom
    restoreAllGuis()
end

_G.__RealFreecam_Enable  = _G.EnableFreecam
_G.__RealFreecam_Disable = _G.DisableFreecam

localPlayer.CharacterAdded:Connect(function()
    if fcRunning then _G.DisableFreecam() end
end)
