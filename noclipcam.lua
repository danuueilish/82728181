if _G.__CAMERA_NOCLIP_LOADED then
    return
end
_G.__CAMERA_NOCLIP_LOADED = true
local Players       = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local LP            = Players.LocalPlayer
local DEFAULT_OCCLUSION =
    LP and LP.DevCameraOcclusionMode
    or StarterPlayer.DevCameraOcclusionMode
    or Enum.DevCameraOcclusionMode.Zoom
local function applyNoclip()
    if not LP then
        return
    end
    LP.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end
local function restoreOcclusion()
    if not LP then
        return
    end
    LP.DevCameraOcclusionMode = DEFAULT_OCCLUSION
end
function _G.EnableCameraNoclip()
    _G.__CameraNoclipEnabled = true
    applyNoclip()
end
function _G.DisableCameraNoclip()
    _G.__CameraNoclipEnabled = false
    restoreOcclusion()
end
