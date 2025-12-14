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
