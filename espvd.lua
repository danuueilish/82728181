local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui   = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local COREGUI    = CoreGui

ESPenabled    = false
CHMSenabled   = false
espTransparency = 0.5

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

function ESP(plr, logic)
    task.spawn(function()
        for _, v in pairs(COREGUI:GetChildren()) do
            if v.Name == plr.Name .. "_ESP" then
                v:Destroy()
            end
        end
        task.wait()

        if plr.Character
            and plr.Name ~= LocalPlayer.Name
            and not COREGUI:FindFirstChild(plr.Name .. "_ESP")
        then
            local ESPholder = Instance.new("Folder")
            ESPholder.Name = plr.Name .. "_ESP"
            ESPholder.Parent = COREGUI

            repeat
                task.wait(1)
            until plr.Character
                and getRoot(plr.Character)
                and plr.Character:FindFirstChildOfClass("Humanoid")

            for _, n in pairs(plr.Character:GetChildren()) do
                if n:IsA("BasePart") then
                    local a = Instance.new("BoxHandleAdornment")
                    a.Name = plr.Name
                    a.Parent = ESPholder
                    a.Adornee = n
                    a.AlwaysOnTop = true
                    a.ZIndex = 10
                    a.Size = n.Size
                    a.Transparency = espTransparency

                    local teamName = tostring(plr.Team)
                    local color3

                    if logic == true then
                        if plr.TeamColor == LocalPlayer.TeamColor then
                            color3 = Color3.new(1, 1, 1)
                        else
                            color3 = Color3.new(1, 0, 0)
                        end
                    else
                        if teamName == "Survivors" then
                            color3 = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                        elseif teamName == "Killer" then
                            color3 = _G.ESP_KILLER_COLOR or Color3.new(1, 0, 0)
                        else
                            color3 = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                        end
                    end

                    a.Color = BrickColor.new(color3)
                end
            end

            -- teks di atas head
            if plr.Character:FindFirstChild("Head") then
                local BillboardGui = Instance.new("BillboardGui")
                local TextLabel = Instance.new("TextLabel")

                BillboardGui.Adornee = plr.Character.Head
                BillboardGui.Name = plr.Name
                BillboardGui.Parent = ESPholder
                BillboardGui.Size = UDim2.new(0, 100, 0, 150)
                BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
                BillboardGui.AlwaysOnTop = true

                TextLabel.Parent = BillboardGui
                TextLabel.BackgroundTransparency = 1
                TextLabel.Position = UDim2.new(0, 0, 0, -50)
                TextLabel.Size = UDim2.new(0, 100, 0, 100)
                TextLabel.Font = Enum.Font.SourceSansSemibold
                TextLabel.TextSize = 20
                TextLabel.TextColor3 = Color3.new(1, 1, 1)
                TextLabel.TextStrokeTransparency = 0
                TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
                TextLabel.Text = "Name: " .. plr.Name
                TextLabel.ZIndex = 10

                local espLoopFunc
                local teamChange
                local addedFunc

                addedFunc = plr.CharacterAdded:Connect(function()
                    if ESPenabled then
                        espLoopFunc:Disconnect()
                        teamChange:Disconnect()
                        ESPholder:Destroy()
                        repeat
                            task.wait(1)
                        until getRoot(plr.Character)
                            and plr.Character:FindFirstChildOfClass("Humanoid")
                        ESP(plr, logic)
                        addedFunc:Disconnect()
                    else
                        teamChange:Disconnect()
                        addedFunc:Disconnect()
                    end
                end)

                teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
                    if ESPenabled then
                        espLoopFunc:Disconnect()
                        addedFunc:Disconnect()
                        ESPholder:Destroy()
                        repeat
                            task.wait(1)
                        until getRoot(plr.Character)
                            and plr.Character:FindFirstChildOfClass("Humanoid")
                        ESP(plr, logic)
                        teamChange:Disconnect()
                    else
                        teamChange:Disconnect()
                    end
                end)

                local function espLoop()
                    if COREGUI:FindFirstChild(plr.Name .. "_ESP") then
                        if plr.Character
                            and getRoot(plr.Character)
                            and plr.Character:FindFirstChildOfClass("Humanoid")
                            and LocalPlayer.Character
                            and getRoot(LocalPlayer.Character)
                        then
                            local pos = math.floor(
                                (getRoot(LocalPlayer.Character).Position
                                - getRoot(plr.Character).Position).Magnitude
                            )
                            TextLabel.Text =
                                "Name: " .. plr.Name ..
                                " | Health: " .. round(plr.Character:FindFirstChildOfClass("Humanoid").Health, 1) ..
                                " | Studs: " .. pos
                        end
                    else
                        teamChange:Disconnect()
                        addedFunc:Disconnect()
                        espLoopFunc:Disconnect()
                    end
                end

                espLoopFunc = RunService.RenderStepped:Connect(espLoop)
            end
        end
    end)
end

-- ==== TRACER (auto ikut ESP) ====
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local playerTrackers = {}
local tracerConn

local function clearTracerForPlayer(plr)
    local line = playerTrackers[plr]
    if line then
        line.Visible = false
        pcall(function()
            line:Remove()
        end)
        playerTrackers[plr] = nil
    end
end

Players.PlayerRemoving:Connect(function(plr)
    clearTracerForPlayer(plr)
end)

-- loop tracer (jalan terus, tapi cuma gambar kalau ESPenabled = true)
if not tracerConn then
    tracerConn = RunService.RenderStepped:Connect(function()
        if not Camera then return end

        if not ESPenabled then
            -- ESP off → sembunyiin semua tracer, tapi nggak dihapus
            for _, line in pairs(playerTrackers) do
                if line then
                    line.Visible = false
                end
            end
            return
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")

                if hrp then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    local line = playerTrackers[plr]

                    if onScreen then
                        if not line then
                            line = Drawing.new("Line")
                            line.Thickness = 1.5
                            line.Transparency = 1
                            playerTrackers[plr] = line
                        end

                        line.Visible = true
                        -- dari tengah bawah layar (kaki kamera)
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To   = Vector2.new(screenPos.X, screenPos.Y)

                        local teamName = plr.Team and plr.Team.Name or ""

                        if teamName == "Survivors" then
                            line.Color = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                        elseif teamName == "Killer" then
                            line.Color = _G.ESP_KILLER_COLOR   or Color3.new(1, 0, 0)
                        else
                            line.Color = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                        end
                    else
                        if line then
                            line.Visible = false
                        end
                    end
                else
                    if playerTrackers[plr] then
                        playerTrackers[plr].Visible = false
                    end
                end
            end
        end
    end)
end

function _G.EnableESP()
    if CHMSenabled then return end
    ESPenabled = true
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            ESP(v)
        end
    end
end

function _G.DisableESP()
    ESPenabled = false
    for _, c in pairs(COREGUI:GetChildren()) do
        if string.sub(c.Name, -4) == "_ESP" then
            c:Destroy()
        end
    end

    -- hapus tracer juga
    for plr, line in pairs(playerTrackers) do
        if line then
            pcall(function()
                line:Remove()
            end)
        end
        playerTrackers[plr] = nil
    end
end
