if not _G.__ANTI_LAG_FISHING_LOADED then
    _G.__ANTI_LAG_FISHING_LOADED = true

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local StarterPlayer = game:GetService("StarterPlayer")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local LP = Players.LocalPlayer
    local cam = workspace.CurrentCamera

    local DEFAULT_MAX_ZOOM = StarterPlayer.CameraMaxZoomDistance
    local DEFAULT_MIN_ZOOM = StarterPlayer.CameraMinZoomDistance
    local DEFAULT_FOV = cam and cam.FieldOfView or 70

    local DEFAULT_LIGHTING = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        GlobalShadows = Lighting.GlobalShadows,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
    }

    local function findRodRemote()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then
            return nil
        end
        local remotes = events:FindFirstChild("RemoteEvent")
        if not remotes then
            return nil
        end
        return remotes:FindFirstChild("Rod")
    end

    _G.AntiLagEnabled = _G.AntiLagEnabled or false
    _G.AntiLagZoomLoopConn = _G.AntiLagZoomLoopConn or nil
    _G.AntiLagRodConn = _G.AntiLagRodConn or nil
    _G.AntiLagOriginalAttr = _G.AntiLagOriginalAttr
    _G.AntiLagZoomActive = _G.AntiLagZoomActive or false
    _G.AntiLagOverlayGui = _G.AntiLagOverlayGui or nil
    _G.__ANTI_LAG_STATIC_DONE = _G.__ANTI_LAG_STATIC_DONE or false

    local function startZoomLoop()
        if _G.AntiLagZoomLoopConn then
            return
        end
        _G.AntiLagZoomLoopConn = RunService.RenderStepped:Connect(function()
            if not _G.AntiLagEnabled or not _G.AntiLagZoomActive then
                return
            end
            cam = workspace.CurrentCamera or cam
            if not cam then
                return
            end
            LP.CameraMaxZoomDistance = DEFAULT_MAX_ZOOM
            LP.CameraMinZoomDistance = DEFAULT_MIN_ZOOM
            cam.FieldOfView = DEFAULT_FOV
        end)
    end

    local function stopZoomLoop()
        if _G.AntiLagZoomLoopConn then
            _G.AntiLagZoomLoopConn:Disconnect()
            _G.AntiLagZoomLoopConn = nil
        end
        cam = workspace.CurrentCamera or cam
        if cam then
            LP.CameraMaxZoomDistance = DEFAULT_MAX_ZOOM
            LP.CameraMinZoomDistance = DEFAULT_MIN_ZOOM
            cam.FieldOfView = DEFAULT_FOV
        end
    end

    local function applyLowLighting()
        Lighting.Brightness = 70
        Lighting.ClockTime = 0
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        Lighting.GlobalShadows = false
        Lighting.FogStart = 0
        Lighting.FogEnd = 30
    end

    local function restoreLighting()
        Lighting.Brightness = DEFAULT_LIGHTING.Brightness
        Lighting.ClockTime = DEFAULT_LIGHTING.ClockTime
        Lighting.Ambient = DEFAULT_LIGHTING.Ambient
        Lighting.OutdoorAmbient = DEFAULT_LIGHTING.OutdoorAmbient
        Lighting.GlobalShadows = DEFAULT_LIGHTING.GlobalShadows
        Lighting.FogStart = DEFAULT_LIGHTING.FogStart
        Lighting.FogEnd = DEFAULT_LIGHTING.FogEnd
        Lighting.ColorShift_Top = DEFAULT_LIGHTING.ColorShift_Top
        Lighting.ColorShift_Bottom = DEFAULT_LIGHTING.ColorShift_Bottom
    end

    local function createOverlay()
        if _G.AntiLagOverlayGui and _G.AntiLagOverlayGui.Parent then
            return
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "AntiLagDarkOverlay"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999999
        gui.Parent = game.CoreGui

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.BackgroundTransparency = 0.35
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Position = UDim2.new(0, 0, 0, 0)
        frame.Parent = gui

        _G.AntiLagOverlayGui = gui
    end

    local function destroyOverlay()
        if _G.AntiLagOverlayGui then
            _G.AntiLagOverlayGui:Destroy()
            _G.AntiLagOverlayGui = nil
        end
    end

    local function runStaticCleanup()
        if _G.__ANTI_LAG_STATIC_DONE then
            return
        end
        _G.__ANTI_LAG_STATIC_DONE = true

        local ws = workspace
        local mapFolder = ws:FindFirstChild("MapContent")

        for _, obj in ipairs(ws:GetDescendants()) do
            if obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Fire")
            or obj:IsA("Smoke")
            or obj:IsA("Sparkles")
            or obj:IsA("Beam")
            or obj:IsA("Explosion") then
                obj.Enabled = false
            elseif obj:IsA("SurfaceAppearance")
            or obj:IsA("Decal")
            or obj:IsA("Texture") then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end

        local character = LP.Character
        if not character then
            character = Instance.new("Folder")
        end

        for _, part in ipairs(ws:GetDescendants()) do
            if part:IsA("BasePart") then
                if part:IsDescendantOf(character) then
                    continue
                end
                if mapFolder and part:IsDescendantOf(mapFolder) then
                    pcall(function()
                        part:Destroy()
                    end)
                else
                    part.Material = Enum.Material.SmoothPlastic
                    part.CastShadow = false
                    part.Reflectance = 0
                    part.Transparency = 1
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                end
            end
        end
    end

    local function hookRod()
        if _G.AntiLagRodConn then
            return
        end
        local Rod = findRodRemote()
        if not Rod then
            task.spawn(function()
                local r = Rod
                while _G.AntiLagEnabled and not r do
                    r = findRodRemote()
                    task.wait(1)
                end
                if r and not _G.AntiLagRodConn and _G.AntiLagEnabled then
                    _G.AntiLagRodConn = r.OnClientEvent:Connect(function(arg1, arg2)
                        if not _G.AntiLagEnabled then
                            return
                        end
                        if arg1 == "Zoom" then
                            _G.AntiLagZoomActive = true
                            startZoomLoop()
                        elseif arg1 == "StopShake" then
                            _G.AntiLagZoomActive = false
                            stopZoomLoop()
                        end
                    end)
                end
            end)
        else
            _G.AntiLagRodConn = Rod.OnClientEvent:Connect(function(arg1, arg2)
                if not _G.AntiLagEnabled then
                    return
                end
                if arg1 == "Zoom" then
                    _G.AntiLagZoomActive = true
                    startZoomLoop()
                elseif arg1 == "StopShake" then
                    _G.AntiLagZoomActive = false
                    stopZoomLoop()
                end
            end)
        end
    end

    function _G.EnableAntiLag()
        if _G.AntiLagEnabled then
            return
        end
        _G.AntiLagEnabled = true

        _G.AntiLagOriginalAttr = LP:GetAttribute("DisableFishingAnimation")
        LP:SetAttribute("DisableFishingAnimation", true)

        hookRod()
        applyLowLighting()
        createOverlay()
        runStaticCleanup()
    end

    function _G.DisableAntiLag()
        if not _G.AntiLagEnabled then
            return
        end
        _G.AntiLagEnabled = false

        if _G.AntiLagOriginalAttr ~= nil then
            LP:SetAttribute("DisableFishingAnimation", _G.AntiLagOriginalAttr)
        else
            LP:SetAttribute("DisableFishingAnimation", nil)
        end
        _G.AntiLagOriginalAttr = nil

        _G.AntiLagZoomActive = false
        stopZoomLoop()

        if _G.AntiLagRodConn then
            _G.AntiLagRodConn:Disconnect()
            _G.AntiLagRodConn = nil
        end

        restoreLighting()
        destroyOverlay()
    end
end
