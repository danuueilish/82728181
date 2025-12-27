local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local COREGUI = CoreGui

ESPenabled = false
CHMSenabled = false
espTransparency = 0.5

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function getRoot(char)
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

function ESP(plr, logic)
	task.spawn(function()
		for _,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_ESP' then
				v:Destroy()
			end
		end
		task.wait()

		if plr.Character
			and plr.Name ~= LocalPlayer.Name
			and not COREGUI:FindFirstChild(plr.Name..'_ESP')
		then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_ESP'
			ESPholder.Parent = COREGUI

			repeat task.wait(1)
			until plr.Character
				and getRoot(plr.Character)
				and plr.Character:FindFirstChildOfClass("Humanoid")

			for _,n in pairs(plr.Character:GetChildren()) do
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
                    if teamName == "Survivors" then
                        color3 = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                    elseif teamName == "Killer" then
                        color3 = _G.ESP_KILLER_COLOR or Color3.new(1, 0, 0)
                    else
                        color3 = _G.ESP_SURVIVOR_COLOR or Color3.new(1, 1, 1)
                    end

                    a.Color = BrickColor.new(color3
				end
			end

			if plr.Character:FindFirstChild("Head") then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")

				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0,100,0,150)
				BillboardGui.StudsOffset = Vector3.new(0,1,0)
				BillboardGui.AlwaysOnTop = true

				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0,0,0,-50)
				TextLabel.Size = UDim2.new(0,100,0,100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1,1,1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = "Name: "..plr.Name
				TextLabel.ZIndex = 10

				local espLoopFunc
				local teamChange
				local addedFunc

				addedFunc = plr.CharacterAdded:Connect(function()
					if ESPenabled then
						espLoopFunc:Disconnect()
						teamChange:Disconnect()
						ESPholder:Destroy()
						repeat task.wait(1)
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
						repeat task.wait(1)
						until getRoot(plr.Character)
							and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr, logic)
						teamChange:Disconnect()
					else
						teamChange:Disconnect()
					end
				end)

				local function espLoop()
					if COREGUI:FindFirstChild(plr.Name..'_ESP') then
						if plr.Character
							and getRoot(plr.Character)
							and plr.Character:FindFirstChildOfClass("Humanoid")
							and LocalPlayer.Character
							and getRoot(LocalPlayer.Character)
						then
							local pos = math.floor(
								(getRoot(LocalPlayer.Character).Position -
								getRoot(plr.Character).Position).Magnitude
							)
							TextLabel.Text =
								"Name: "..plr.Name..
								" | Health: "..round(plr.Character:FindFirstChildOfClass("Humanoid").Health,1)..
								" | Studs: "..pos
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

function _G.EnableESP()
	if CHMSenabled then return end
	ESPenabled = true
	for _,v in pairs(Players:GetPlayers()) do
		if v ~= LocalPlayer then
			ESP(v)
		end
	end
end

function _G.DisableESP()
	ESPenabled = false
	for _,c in pairs(COREGUI:GetChildren()) do
		if string.sub(c.Name, -4) == "_ESP" then
			c:Destroy()
		end
	end
end
