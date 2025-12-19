local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

_G.IY_JERK_ENABLED = false

local tool
local track
local humanoid
local loopThread

local function isR15(char)
	return char:FindFirstChild("UpperTorso") ~= nil
end

local function cleanup()
	_G.IY_JERK_ENABLED = false

	if track then
		pcall(function() track:Stop() end)
		track = nil
	end

	if loopThread then
		task.cancel(loopThread)
		loopThread = nil
	end

	if tool then
		pcall(function() tool:Destroy() end)
		tool = nil
	end
end

function _G.EnableJerk()
	if _G.IY_JERK_ENABLED then return end
	_G.IY_JERK_ENABLED = true

	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	tool = Instance.new("Tool")
	tool.Name = "Jerk Off"
	tool.RequiresHandle = false
	tool.ToolTip =
		'in the stripped club. straight up "jorking it". and by "it", haha, well. lets just say. My peanits.'
	tool.Parent = backpack

	local active = false

	tool.Equipped:Connect(function()
		active = true
	end)

	tool.Unequipped:Connect(function()
		active = false
		if track then
			track:Stop()
			track = nil
		end
	end)

	humanoid.Died:Connect(cleanup)

	loopThread = task.spawn(function()
		while _G.IY_JERK_ENABLED do
			if not active then
				task.wait(0.1)
				continue
			end

			if not track then
				local anim = Instance.new("Animation")
				local r15 = isR15(char)

				anim.AnimationId = r15
					and "rbxassetid://698251653"
					or "rbxassetid://72042024"

				track = humanoid:LoadAnimation(anim)
			end

			track:Play()
			track:AdjustSpeed(r15 and 0.7 or 0.65)
			track.TimePosition = 0.6

			task.wait(0.1)
			while track and track.TimePosition < (r15 and 0.7 or 0.65) do
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
	cleanup()
end
