-- Source by Infinite Yield (i modified)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

_G.IY_JERK_RUNNING = false
_G.IY_JERK_TOOL = nil

local function r15(player)
	local char = player.Character
	return char and char:FindFirstChild("UpperTorso") ~= nil
end

function _G.EnableJerk()
	if _G.IY_JERK_RUNNING then return end
	_G.IY_JERK_RUNNING = true

	local speaker = LocalPlayer
	local humanoid = speaker.Character:FindFirstChildWhichIsA("Humanoid")
	local backpack = speaker:FindFirstChildWhichIsA("Backpack")
	if not humanoid or not backpack then return end

	local tool = Instance.new("Tool")
	tool.Name = "Jerk Off"
	tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
	tool.RequiresHandle = false
	tool.Parent = backpack
	_G.IY_JERK_TOOL = tool

	local jorkin = false
	local track = nil

	local function stopTomfoolery()
		jorkin = false
		if track then
			track:Stop()
			track = nil
		end
	end

	tool.Equipped:Connect(function()
		jorkin = true
	end)

	tool.Unequipped:Connect(stopTomfoolery)
	humanoid.Died:Connect(stopTomfoolery)

	task.spawn(function()
		while _G.IY_JERK_RUNNING and task.wait() do
			if not jorkin then
				continue
			end

			local isR15 = r15(speaker)

			if not track then
				local anim = Instance.new("Animation")
				anim.AnimationId = (not isR15)
					and "rbxassetid://72042024"
					or "rbxassetid://698251653"

				track = humanoid:LoadAnimation(anim)
			end

			track:Play()
			track:AdjustSpeed(isR15 and 0.7 or 0.65)
			track.TimePosition = 0.6

			task.wait(0.1)

			while track
				and track.TimePosition < ((not isR15) and 0.65 or 0.7)
				and _G.IY_JERK_RUNNING
			do
				task.wait(0.1)
			end

			if track then
				track:Stop()
				track = nil
			end
		end
	end)
end

function _G.DisableJerk()
	_G.IY_JERK_RUNNING = false

	if _G.IY_JERK_TOOL then
		pcall(function()
			_G.IY_JERK_TOOL:Destroy()
		end)
		_G.IY_JERK_TOOL = nil
	end
end