local Workspace = game:GetService("Workspace")

_G.xrayEnabled = false
local XRAY_CONNECTION

local function applyXray()
	for _, v in pairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart")
			and not v.Parent:FindFirstChildWhichIsA("Humanoid")
			and not (v.Parent.Parent and v.Parent.Parent:FindFirstChildWhichIsA("Humanoid"))
		then
			v.LocalTransparencyModifier = _G.xrayEnabled and 0.5 or 0
		end
	end
end

function _G.EnableXray()
	if _G.xrayEnabled then return end
	_G.xrayEnabled = true
	applyXray()

	XRAY_CONNECTION = Workspace.DescendantAdded:Connect(function(v)
		if not _G.xrayEnabled then return end
		if v:IsA("BasePart")
			and not v.Parent:FindFirstChildWhichIsA("Humanoid")
			and not (v.Parent.Parent and v.Parent.Parent:FindFirstChildWhichIsA("Humanoid"))
		then
			v.LocalTransparencyModifier = 0.5
		end
	end)
end

function _G.DisableXray()
	_G.xrayEnabled = false
	if XRAY_CONNECTION then
		XRAY_CONNECTION:Disconnect()
		XRAY_CONNECTION = nil
	end
	applyXray()
end