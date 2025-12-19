-- fly.lua (IY-style, desktop + mobile)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

_G.FlyEnabled = false
_G.FlySpeed = 1

local BG, BV
local mBG, mBV, mConn
local keyDown, keyUp

local function getRoot(char)
    return char:WaitForChild("HumanoidRootPart")
end

local function isMobile()
    return UIS.TouchEnabled and not UIS.KeyboardEnabled
end

-- ================= DESKTOP FLY =================
local function startDesktopFly()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local root = getRoot(char)

    BG = Instance.new("BodyGyro", root)
    BV = Instance.new("BodyVelocity", root)

    BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)

    keyDown = UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.W then
            BV.Velocity = workspace.CurrentCamera.CFrame.LookVector * (_G.FlySpeed * 50)
        end
    end)

    keyUp = UIS.InputEnded:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.W then
            BV.Velocity = Vector3.zero
        end
    end)
end

-- ================= MOBILE FLY =================
local function startMobileFly()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = getRoot(char)

    mBV = Instance.new("BodyVelocity", root)
    mBG = Instance.new("BodyGyro", root)

    mBV.MaxForce = Vector3.new(9e9,9e9,9e9)
    mBG.MaxTorque = Vector3.new(9e9,9e9,9e9)

    local controlModule =
        require(LocalPlayer.PlayerScripts.PlayerModule.ControlModule)

    mConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local move = controlModule:GetMoveVector()

        mBV.Velocity =
            cam.LookVector * move.Z * _G.FlySpeed * 50 +
            cam.RightVector * move.X * _G.FlySpeed * 50

        mBG.CFrame = cam.CFrame
    end)
end

-- ================= API =================
function _G.EnableFly()
    if _G.FlyEnabled then return end
    _G.FlyEnabled = true

    if isMobile() then
        startMobileFly()
    else
        startDesktopFly()
    end
end

function _G.DisableFly()
    _G.FlyEnabled = false

    if keyDown then keyDown:Disconnect() end
    if keyUp then keyUp:Disconnect() end
    if mConn then mConn:Disconnect() end

    if BG then BG:Destroy() end
    if BV then BV:Destroy() end
    if mBG then mBG:Destroy() end
    if mBV then mBV:Destroy() end
end

function _G.SetFlySpeed(v)
    _G.FlySpeed = tonumber(v) or 1
end