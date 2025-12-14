if _G.__WALK_ON_WATER_LOADED then return end
_G.__WALK_ON_WATER_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

_G.WalkOnWaterEnabled = _G.WalkOnWaterEnabled or false
_G.WaterPlatform = _G.WaterPlatform or nil
_G.WaterConnection = _G.WaterConnection or nil

local function createPlatform()
    if _G.WaterPlatform then
        _G.WaterPlatform:Destroy()
    end

    local p = Instance.new("Part")
    p.Name = "WaterPlatform"
    p.Size = Vector3.new(15, 1, 15)
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 1
    p.Material = Enum.Material.SmoothPlastic
    p.CastShadow = false
    p.CanTouch = false
    p.CanQuery = false
    p.Parent = workspace

    _G.WaterPlatform = p
end

function _G.EnableWalkOnWater()
    if _G.WalkOnWaterEnabled then return end
    _G.WalkOnWaterEnabled = true

    createPlatform()

    if _G.WaterConnection then
        _G.WaterConnection:Disconnect()
        _G.WaterConnection = nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    _G.WaterConnection = RunService.Heartbeat:Connect(function()
        if not _G.WalkOnWaterEnabled then return end

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local platform = _G.WaterPlatform
        if not hrp or not platform then return end

        rayParams.FilterDescendantsInstances = { char }

        local origin = hrp.Position + Vector3.new(0, 10, 0)
        local direction = Vector3.new(0, -80, 0)

        local result = workspace:Raycast(origin, direction, rayParams)
        if result and result.Material == Enum.Material.Water then
            platform.Position = Vector3.new(
                hrp.Position.X,
                result.Position.Y - (platform.Size.Y / 2) - 0.15,
                hrp.Position.Z
            )
        else
            platform.Position = Vector3.new(0, -5000, 0)
        end
    end)
end

function _G.DisableWalkOnWater()
    _G.WalkOnWaterEnabled = false

    if _G.WaterConnection then
        _G.WaterConnection:Disconnect()
        _G.WaterConnection = nil
    end

    if _G.WaterPlatform then
        _G.WaterPlatform:Destroy()
        _G.WaterPlatform = nil
    end
end

if _G.ShiftlockLoaded then return end
_G.ShiftlockLoaded = true

local ShiftLockScreenGui = Instance.new("ScreenGui")
local ShiftLockButton = Instance.new("ImageButton")
local ShiftlockCursor = Instance.new("ImageLabel")
local ShiftlockActive

ShiftLockScreenGui.Name = "Shiftlock (CoreGui)"
ShiftLockScreenGui.Parent = game.CoreGui
ShiftLockScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ShiftLockScreenGui.ResetOnSpawn = false
ShiftLockScreenGui.Enabled = false

ShiftLockButton.Parent = ShiftLockScreenGui
ShiftLockButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ShiftLockButton.BackgroundTransparency = 1
ShiftLockButton.Position = UDim2.new(0.7, 0, 0.75, 0)
ShiftLockButton.Size = UDim2.new(0.0636147112, 0, 0.0661305636, 0)
ShiftLockButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
ShiftLockButton.Image = "rbxasset://textures/ui/mouseLock_off@2x.png"

ShiftlockCursor.Name = "Shiftlock Cursor"
ShiftlockCursor.Parent = ShiftLockScreenGui
ShiftlockCursor.Image = "rbxasset://textures/MouseLockedCursor.png"
ShiftlockCursor.Size = UDim2.new(0.03, 0, 0.03, 0)
ShiftlockCursor.Position = UDim2.new(0.5, 0, 0.5, 0)
ShiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
ShiftlockCursor.SizeConstraint = Enum.SizeConstraint.RelativeXX
ShiftlockCursor.BackgroundTransparency = 1
ShiftlockCursor.Visible = false

local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPosition
    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
        TweenService:Create(object, TweenInfo.new(0.15), {Position = pos}):Play()
    end
    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

MakeDraggable(ShiftLockButton, ShiftLockButton)

local function DisableShiftlock()
    if ShiftlockActive then
        LP.Character.Humanoid.AutoRotate = true
        ShiftLockButton.Image = "rbxasset://textures/ui/mouseLock_off@2x.png"
        ShiftlockCursor.Visible = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        pcall(function()
            ShiftlockActive:Disconnect()
            ShiftlockActive = nil
        end)
    end
end

ShiftLockButton.MouseButton1Click:Connect(function()
    if not ShiftlockActive then
        ShiftlockActive = RunService.RenderStepped:Connect(function()
            if LP.Character
                and LP.Character:FindFirstChild("Humanoid")
                and LP.Character:FindFirstChild("HumanoidRootPart") then

                LP.Character.Humanoid.AutoRotate = false
                ShiftLockButton.Image = "rbxasset://textures/ui/mouseLock_on@2x.png"
                ShiftlockCursor.Visible = true

                local camera = workspace.CurrentCamera
                local lookVector = camera.CFrame.LookVector
                local characterCF = LP.Character.HumanoidRootPart.CFrame

                LP.Character.HumanoidRootPart.CFrame =
                    CFrame.new(characterCF.Position,
                    characterCF.Position + Vector3.new(lookVector.X, 0, lookVector.Z))

                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        end)
    else
        DisableShiftlock()
    end
end)

LP.CharacterAdded:Connect(function()
    DisableShiftlock()
end)

-- GLOBAL WRAPPER (NO LOGIC CHANGE)
_G.EnableShiftC = function()
    ShiftLockScreenGui.Enabled = true
end

_G.DisableC = function()
    ShiftLockScreenGui.Enabled = false
    DisableShiftlock()
end
