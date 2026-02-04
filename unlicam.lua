if _G.__UNLIMITED_CAMERA_LOADED then return end
_G.__UNLIMITED_CAMERA_LOADED = true
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local LP = Players.LocalPlayer
local DEFAULT_MAX = StarterPlayer.CameraMaxZoomDistance
local DEFAULT_MIN = StarterPlayer.CameraMinZoomDistance
local MAX_ZOOM = 1e9
local MIN_ZOOM = 0.5

local function applyUnlimited()
    if not LP then return end
    if LP.CameraMaxZoomDistance ~= MAX_ZOOM then
        LP.CameraMaxZoomDistance = MAX_ZOOM
    end
    if LP.CameraMinZoomDistance ~= MIN_ZOOM then
        LP.CameraMinZoomDistance = MIN_ZOOM
    end
end

local function restoreDefault()
    if not LP then return end
    LP.CameraMaxZoomDistance = DEFAULT_MAX
    LP.CameraMinZoomDistance = DEFAULT_MIN
end

function _G.EnableUnlimitedCamera()
    _G.__UnlimitedCameraEnabled = true
    applyUnlimited()
end

function _G.DisableUnlimitedCamera()
    _G.__UnlimitedCameraEnabled = false
    restoreDefault()
end

if LP then
    local reapplying = false
    local function safeApply()
        if not _G.__UnlimitedCameraEnabled then return end
        if reapplying then return end
        reapplying = true
        applyUnlimited()
        reapplying = false
    end
    LP:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(safeApply)
    LP:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(safeApply)
end
