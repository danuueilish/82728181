--// Infinite Yield Fly (Fixed)
--// Desktop + Mobile
--// Author: IY (patched)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- globals supaya bisa dipanggil toggle / slider
_G.IY_FLYING = false
_G.iyflyspeed = 1
_G.vehicleflyspeed = 1
_G.QEfly = true

local flyKeyDown, flyKeyUp

local function getRoot(char)
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

-- ===================== DESKTOP FLY =====================
function _G.EnableFly(vfly)
	if _G.IY_FLYING then return end
	_G.IY_FLYING = true

	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local root = getRoot(char)
	local camera = workspace.CurrentCamera

	local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
	local lCONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
	local SPEED = 0

	local BG = Instance.new("BodyGyro")
	local BV = Instance.new("BodyVelocity")

	BG.P = 9e4
	BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	BG.CFrame = root.CFrame
	BG.Parent = root

	BV.Velocity = Vector3.zero
	BV.MaxForce = Vector3.new(9e9,9e9,9e9)
	BV.Parent = root

	flyKeyDown = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = _G.iyflyspeed end
		if input.KeyCode == Enum.KeyCode.S then CONTROL.B = -_G.iyflyspeed end
		if input.KeyCode == Enum.KeyCode.A then CONTROL.L = -_G.iyflyspeed end
		if input.KeyCode == Enum.KeyCode.D then CONTROL.R = _G.iyflyspeed end
		if input.KeyCode == Enum.KeyCode.E and _G.QEfly then CONTROL.E = _G.iyflyspeed*2 end
		if input.KeyCode == Enum.KeyCode.Q and _G.QEfly then CONTROL.Q = -_G.iyflyspeed*2 end
	end)

	flyKeyUp = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0 end
		if input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0 end
		if input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0 end
		if input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0 end
		if input.KeyCode == Enum.KeyCode.E then CONTROL.E = 0 end
		if input.KeyCode == Enum.KeyCode.Q then CONTROL.Q = 0 end
	end)

	RunService.RenderStepped:Connect(function()
		if not _G.IY_FLYING then return end

		humanoid.PlatformStand = true
		camera = workspace.CurrentCamera

		if CONTROL.F + CONTROL.B ~= 0 or CONTROL.L + CONTROL.R ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
			SPEED = 50
		else
			SPEED = 0
		end

		if SPEED > 0 then
			BV.Velocity = (
				(camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
				((camera.CFrame * CFrame.new(
					CONTROL.L + CONTROL.R,
					CONTROL.E + CONTROL.Q,
					0
				)).Position - camera.CFrame.Position)
			) * SPEED

			lCONTROL = CONTROL
		else
			BV.Velocity = Vector3.zero
		end

		BG.CFrame = camera.CFrame
	end)
end

-- ===================== DISABLE =====================
function _G.DisableFly()
	_G.IY_FLYING = false

	if flyKeyDown then flyKeyDown:Disconnect() end
	if flyKeyUp then flyKeyUp:Disconnect() end

	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.PlatformStand = false
	end

	pcall(function()
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
	end)
end