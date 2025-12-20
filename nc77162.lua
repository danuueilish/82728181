local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

_G.IY_NOCLIP_RUNNING = false
_G.IY_NOCLIP_CONN = nil

Clip = true
floatName = floatName or "Float"

function _G.EnableNoclip()
	if _G.IY_NOCLIP_RUNNING then return end
	_G.IY_NOCLIP_RUNNING = true

	local speaker = LocalPlayer
	Clip = false

	local function NoclipLoop()
		if Clip == false and speaker.Character ~= nil then
			for _, child in pairs(speaker.Character:GetDescendants()) do
				if child:IsA("BasePart")
					and child.CanCollide == true
					and child.Name ~= floatName
				then
					child.CanCollide = false
				end
			end
		end
	end

	_G.IY_NOCLIP_CONN = RunService.Stepped:Connect(NoclipLoop)
end

function _G.DisableNoclip()
	_G.IY_NOCLIP_RUNNING = false
	Clip = true

	if _G.IY_NOCLIP_CONN then
		_G.IY_NOCLIP_CONN:Disconnect()
		_G.IY_NOCLIP_CONN = nil
	end
end