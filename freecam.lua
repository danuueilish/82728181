if _G.__IY_FREECAM_LOADED then return end
_G.__IY_FREECAM_LOADED = true

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local localPlayer   = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        currentCamera = workspace.CurrentCamera
    end
end)

-- Spring
local Spring = {}
Spring.__index = Spring
local exp = math.exp

function Spring.new(freq, pos)
    return setmetatable({ f = freq, p = pos, v = 0 }, Spring)
end
function Spring:Update(dt, goal)
    local f = self.f * 2 * math.pi
    self.v = (f * dt * ((goal - self.p) * f - self.v) + self.v) * exp(-f * dt)
    self.p = goal + (self.v * dt - (goal - self.p) * (f * dt + 1)) * exp(-f * dt)
    return self.p
end
function Spring:Reset(pos)
    self.p = pos
    self.v = 0
end

local SPEED  = 30
local v19    = 0
local v16    = 0
local v17    = 0
local v57    = 70

local clamp = math.clamp
local rad   = math.rad
local deg   = math.deg

local velSpring = Spring.new(1,   Vector3.new(0, 0, 0))
local panSpring = Spring.new(0.7, Vector2.zero)

local fcRunning  = false
local v20        = nil
local isDragging = false
local hiddenGuis = {}

local v51 = {}
local v50 = {
    [Enum.KeyCode.W] = true,
    [Enum.KeyCode.S] = true,
    [Enum.KeyCode.A] = true,
    [Enum.KeyCode.D] = true,
    [Enum.KeyCode.Q] = true,
    [Enum.KeyCode.E] = true,
}

task.spawn(function()
    pcall(function()
        local ps = localPlayer:WaitForChild("PlayerScripts", 10)
        if ps then
            require(ps:WaitForChild("PlayerModule", 10)):GetControls()
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if v50[input.KeyCode] then
        v51[input.KeyCode] = true
    end
    if fcRunning and input.UserInputType == Enum.UserInputType.MouseButton2 then
        isDragging = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if v50[input.KeyCode] then
        v51[input.KeyCode] = nil
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isDragging = false
        if fcRunning then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)

local function updateZoom(delta)
    v57 = clamp(v57 - delta * 0.1, 20, 100)
    TweenService:Create(currentCamera, TweenInfo.new(0.15, Enum.EasingStyle.Sine), { FieldOfView = v57 }):Play()
end

UserInputService.InputChanged:Connect(function(input, gp)
    if not fcRunning then return end
    if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        v16 = v16 - input.Delta.X * 0.18
        v17 = clamp(v17 - input.Delta.Y * 0.18, -89, 89)
    end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        updateZoom(input.Position.Z * 10)
    end
end)

local function getMoveVec()
    return Vector3.new(
        (v51[Enum.KeyCode.D] and 1 or 0) - (v51[Enum.KeyCode.A] and 1 or 0),
        (v51[Enum.KeyCode.E] and 1 or 0) - (v51[Enum.KeyCode.Q] and 1 or 0),
        (v51[Enum.KeyCode.S] and 1 or 0) - (v51[Enum.KeyCode.W] and 1 or 0)
    )
end

local function update(dt)
    -- force scriptable every frame so game camera script can't override
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
    currentCamera.CFrame = CFrame.new(pos) * cf
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
    for k in pairs(v51) do v51[k] = nil end

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
    for k in pairs(v51) do v51[k] = nil end
    isDragging = false
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
