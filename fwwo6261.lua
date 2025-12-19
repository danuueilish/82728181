local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

_G.IY_FLYING = false
_G.iyflyspeed = _G.iyflyspeed or 1
_G.vehicleflyspeed = _G.vehicleflyspeed or 1
_G.QEfly = true

local flyKeyDown, flyKeyUp
local flyConnection

local function getRoot(char)
	return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

function _G.EnableFly(vfly)
	if _G.IY_FLYING then return end
	_G.IY_FLYING = true

	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local root = getRoot(char)
	local camera = workspace.CurrentCamera

	local isMobile = UserInputService.TouchEnabled
	local ControlModule

	if isMobile then
		ControlModule = require(
			LocalPlayer.PlayerScripts
				:WaitForChild("PlayerModule")
				:WaitForChild("ControlModule")
		)
	end

	local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}

	local BG = Instance.new("BodyGyro")
	local BV = Instance.new("BodyVelocity")

	BG.P = 9e4
	BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
	BG.CFrame = root.CFrame
	BG.Parent = root

	BV.MaxForce = Vector3.new(9e9,9e9,9e9)
	BV.Velocity = Vector3.zero
	BV.Parent = root

	if not isMobile then
		flyKeyDown = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 1 end
			if input.KeyCode == Enum.KeyCode.S then CONTROL.B = -1 end
			if input.KeyCode == Enum.KeyCode.A then CONTROL.L = -1 end
			if input.KeyCode == Enum.KeyCode.D then CONTROL.R = 1 end
			if input.KeyCode == Enum.KeyCode.E and _G.QEfly then CONTROL.E = 1 end
			if input.KeyCode == Enum.KeyCode.Q and _G.QEfly then CONTROL.Q = -1 end
		end)

		flyKeyUp = UserInputService.InputEnded:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0 end
			if input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0 end
			if input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0 end
			if input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0 end
			if input.KeyCode == Enum.KeyCode.E then CONTROL.E = 0 end
			if input.KeyCode == Enum.KeyCode.Q then CONTROL.Q = 0 end
		end)
	end

	flyConnection = RunService.RenderStepped:Connect(function()
		if not _G.IY_FLYING then return end

		humanoid.PlatformStand = true
		camera = workspace.CurrentCamera

		local moveVector = Vector3.zero
		local speed = (_G.iyflyspeed or 1) * 50

		if isMobile then
			local dir = ControlModule:GetMoveVector()
			moveVector =
				(camera.CFrame.RightVector * dir.X) +
				(camera.CFrame.LookVector * -dir.Z)
		else
			moveVector =
				(camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
				(camera.CFrame.RightVector * (CONTROL.R + CONTROL.L)) +
				(camera.CFrame.UpVector * (CONTROL.E + CONTROL.Q))
		end

		if moveVector.Magnitude > 0 then
			BV.Velocity = moveVector.Unit * speed
		else
			BV.Velocity = Vector3.zero
		end

		BG.CFrame = camera.CFrame
	end)
end

function _G.DisableFly()
	_G.IY_FLYING = false

	if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown = nil end
	if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp = nil end
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end

	local char = LocalPlayer.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		char:FindFirstChildOfClass("Humanoid").PlatformStand = false
	end

	if char then
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then
				v:Destroy()
			end
		end
	end
end