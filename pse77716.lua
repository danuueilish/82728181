-- creds: msstudio

local VERSION = "2.0.4"

if getgenv().mstudio45_ESP then
	getgenv().mstudio45_ESP:Destroy() 
	getgenv().mstudio45_ESP = nil
	task.wait(0.1)
end

local cloneref = getgenv().cloneref or function(inst) return inst; end
local getui;

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local tablefreeze = function(provided_table)
	local proxy = {}
	local data = table.clone(provided_table)
	local mt = {
		__index = function(table, key) return data[key] end,
		__newindex = function(table, key, value) end
	}
	return setmetatable(proxy, mt)
end

local function GetPivot(Instance)
	if Instance.ClassName == "Bone" then
		return Instance.TransformedWorldCFrame
	elseif Instance.ClassName == "Attachment" then
		return Instance.WorldCFrame
	elseif Instance.ClassName == "Camera" then
		return Instance.CFrame
	else
		return Instance:GetPivot()
	end
end

local function RandomString(length)
	length = tonumber(length) or math.random(10, 20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

function SafeCallback(Func, ...)
    if not (Func and typeof(Func) == "function") then return end
    local Result = table.pack(xpcall(Func, function(Error)
        return Error
    end, ...))
    if not Result[1] then return nil end
    return table.unpack(Result, 2, Result.n)
end

local InstancesLib = {
	Create = function(instanceType, properties)
		local instance = Instance.new(instanceType)
		for name, val in pairs(properties) do
			if name == "Parent" then continue end
			instance[name] = val
		end
		if properties["Parent"] ~= nil then
			instance["Parent"] = properties["Parent"]
		end
		return instance
	end,

	TryGetProperty = function(instance, propertyName)
		local success, property = pcall(function() return instance[propertyName] end)
		return if success then property else nil;
	end,

	FindPrimaryPart = function(instance)
		if typeof(instance) ~= "Instance" then return nil end
		return (instance:IsA("Model") and instance.PrimaryPart or nil)
			or instance:FindFirstChildWhichIsA("BasePart")
			or instance:FindFirstChildWhichIsA("UnionOperation")
			or instance;
	end,

	DistanceFrom = function(inst, from)
		if not (inst and from) then return 9e9; end
		local position = if typeof(inst) == "Instance" then GetPivot(inst).Position else inst;
		local fromPosition = if typeof(from) == "Instance" then GetPivot(from).Position else from;
		return (fromPosition - position).Magnitude;
	end
}

do
	local testGui = Instance.new("ScreenGui")
	local successful = pcall(function() testGui.Parent = CoreGui; end)
	if not successful then
		getui = function() return Players.LocalPlayer.PlayerGui; end;
	else
		getui = function() return CoreGui end;
	end
	testGui:Destroy()
end

local ActiveFolder = InstancesLib.Create("Folder", {Parent = getui(), Name = RandomString()})
local StorageFolder = InstancesLib.Create("Folder", {Parent = if typeof(game) == "userdata" then Players.Parent else game, Name = RandomString()})
local MainGUI = InstancesLib.Create("ScreenGui", {Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999})
local BillboardGUI = InstancesLib.Create("ScreenGui", {Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999})

local Library = {
	Destroyed = false,
	ActiveFolder = ActiveFolder,
	StorageFolder = StorageFolder,
	MainGUI = MainGUI,
	BillboardGUI = BillboardGUI,
	Connections = {},
	ESP = {},
	GlobalConfig = {
		IgnoreCharacter = false,
		Rainbow = false,
		Billboards = true,
		Highlighters = true,
		Distance = true,
		Arrows = false,
		Font = Enum.Font.RobotoCondensed
	},
	RainbowHueSetup = 0,
	RainbowHue = 0,
	RainbowStep = 0,
	RainbowColor = Color3.new()
}

local character;
local rootPart;
local camera = workspace.CurrentCamera;

local function worldToViewport(...)
	camera = (camera or workspace.CurrentCamera);
	if camera == nil then return Vector2.new(0, 0), false; end
	return camera:WorldToViewportPoint(...);
end

local function UpdatePlayerVariables(newCharacter, force)
	if force ~= true and Library.GlobalConfig.IgnoreCharacter == true then return; end;
	character = newCharacter or Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait();
	rootPart = character:WaitForChild("HumanoidRootPart", 2.5) or character:WaitForChild("UpperTorso", 2.5) or character:WaitForChild("Torso", 2.5) or character.PrimaryPart or character:WaitForChild("Head", 2.5);
end
task.spawn(UpdatePlayerVariables, nil, true);

function Library:Clear()
	if Library.Destroyed == true then return end
	for _, ESP in pairs(Library.ESP) do
		if not ESP then continue end
		ESP:Destroy()
	end
end

function Library:Destroy()
	if Library.Destroyed == true then return end
	Library:Clear();
	Library.Destroyed = true;
	ActiveFolder:Destroy();
	StorageFolder:Destroy();
	MainGUI:Destroy();
	BillboardGUI:Destroy();
	for _, connection in Library.Connections do
		if connection and connection.Connected then connection:Disconnect() end
	end
	table.clear(Library.Connections)
	getgenv().mstudio45_ESP = nil;
end

local AllowedESPType = {text = true, sphereadornment = true, cylinderadornment = true, adornment = true, selectionbox = true, highlight = true}

function Library:Add(espSettings)
	if Library.Destroyed == true then return end
	if not espSettings.ESPType then espSettings.ESPType = "Highlight" end
	espSettings.ESPType = string.lower(espSettings.ESPType)
	espSettings.Name = if typeof(espSettings.Name) == "string" then espSettings.Name else espSettings.Model.Name;
	espSettings.TextModel = if typeof(espSettings.TextModel) == "Instance" then espSettings.TextModel else espSettings.Model;
	espSettings.Visible = if typeof(espSettings.Visible) == "boolean" then espSettings.Visible else true;
	espSettings.Color = if typeof(espSettings.Color) == "Color3" then espSettings.Color else Color3.new();
	espSettings.MaxDistance = if typeof(espSettings.MaxDistance) == "number" then espSettings.MaxDistance else 5000;
	espSettings.StudsOffset = if typeof(espSettings.StudsOffset) == "Vector3" then espSettings.StudsOffset else Vector3.new();
	espSettings.TextSize = if typeof(espSettings.TextSize) == "number" then espSettings.TextSize else 16;
	espSettings.Thickness = if typeof(espSettings.Thickness) == "number" then espSettings.Thickness else 0.1;
	espSettings.Transparency = if typeof(espSettings.Transparency) == "number" then espSettings.Transparency else 0.65;
	espSettings.SurfaceColor = if typeof(espSettings.SurfaceColor) == "Color3" then espSettings.SurfaceColor else Color3.new();
	espSettings.FillColor = if typeof(espSettings.FillColor) == "Color3" then espSettings.FillColor else Color3.new();
	espSettings.OutlineColor = if typeof(espSettings.OutlineColor) == "Color3" then espSettings.OutlineColor else Color3.new(1, 1, 1);
	espSettings.FillTransparency = if typeof(espSettings.FillTransparency) == "number" then espSettings.FillTransparency else 0.65;
	espSettings.OutlineTransparency = if typeof(espSettings.OutlineTransparency) == "number" then espSettings.OutlineTransparency else 0;
	espSettings.Arrow = if typeof(espSettings.Arrow) == "table" then espSettings.Arrow else { Enabled = false };

	local ESP = {
		Index = RandomString(),
		OriginalSettings = tablefreeze(espSettings),
		CurrentSettings = espSettings,
		Hidden = false,
		Deleted = false,
		Connections = {}
	}

	local Billboard = InstancesLib.Create("BillboardGui", {
		Parent = BillboardGUI,
		Name = ESP.Index,
		Enabled = true,
		ResetOnSpawn = false,
		AlwaysOnTop = true,
		Size = UDim2.new(0, 200, 0, 50),
		Adornee = ESP.CurrentSettings.TextModel or ESP.CurrentSettings.Model,
		StudsOffset = ESP.CurrentSettings.StudsOffset or Vector3.new(),
	})

	local BillboardText = InstancesLib.Create("TextLabel", {
		Parent = Billboard,
		Size = UDim2.new(0, 200, 0, 50),
		Font = Library.GlobalConfig.Font,
		TextWrap = true,
		TextWrapped = true,
		RichText = true,
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Text = ESP.CurrentSettings.Name,
		TextColor3 = ESP.CurrentSettings.Color or Color3.new(),
		TextSize = ESP.CurrentSettings.TextSize or 16,
	})
	InstancesLib.Create("UIStroke", {Parent = BillboardText})

	local Highlighter, IsAdornment = nil, not not string.match(string.lower(ESP.OriginalSettings.ESPType), "adornment")
	
	if IsAdornment then
		local _, ModelSize = nil, nil
		if ESP.CurrentSettings.Model:IsA("Model") then
			_, ModelSize = ESP.CurrentSettings.Model:GetBoundingBox()
		else
			if not InstancesLib.TryGetProperty(ESP.CurrentSettings.Model, "Size") then
				local prim = InstancesLib.FindPrimaryPart(ESP.CurrentSettings.Model)
				if not InstancesLib.TryGetProperty(prim, "Size") then
					espSettings.ESPType = "Highlight"
					return Library:Add(espSettings)
				end
				ModelSize = prim.Size
			else
				ModelSize = ESP.CurrentSettings.Model.Size
			end
		end

		if ESP.OriginalSettings.ESPType == "sphereadornment" then
			Highlighter = InstancesLib.Create("SphereHandleAdornment", {Parent = ActiveFolder, Name = ESP.Index, Adornee = ESP.CurrentSettings.Model, AlwaysOnTop = true, ZIndex = 10, Radius = ModelSize.X * 1.085, CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0), Color3 = ESP.CurrentSettings.Color or Color3.new(), Transparency = ESP.CurrentSettings.Transparency or 0.65})
		elseif ESP.OriginalSettings.ESPType == "cylinderadornment" then
			Highlighter = InstancesLib.Create("CylinderHandleAdornment", {Parent = ActiveFolder, Name = ESP.Index, Adornee = ESP.CurrentSettings.Model, AlwaysOnTop = true, ZIndex = 10, Height = ModelSize.Y * 2, Radius = ModelSize.X * 1.085, CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0), Color3 = ESP.CurrentSettings.Color or Color3.new(), Transparency = ESP.CurrentSettings.Transparency or 0.65})
		else
			Highlighter = InstancesLib.Create("BoxHandleAdornment", {Parent = ActiveFolder, Name = ESP.Index, Adornee = ESP.CurrentSettings.Model, AlwaysOnTop = true, ZIndex = 10, Size = ModelSize, Color3 = ESP.CurrentSettings.Color or Color3.new(), Transparency = ESP.CurrentSettings.Transparency or 0.65})
		end
	elseif ESP.OriginalSettings.ESPType == "selectionbox" then
		Highlighter = InstancesLib.Create("SelectionBox", {Parent = ActiveFolder, Name = ESP.Index, Adornee = ESP.CurrentSettings.Model, Color3 = ESP.CurrentSettings.BorderColor or Color3.new(), LineThickness = ESP.CurrentSettings.Thickness or 0.1, SurfaceColor3 = ESP.CurrentSettings.SurfaceColor or Color3.new(), SurfaceTransparency = ESP.CurrentSettings.Transparency or 0.65})
	elseif ESP.OriginalSettings.ESPType == "highlight" then
		Highlighter = InstancesLib.Create("Highlight", {Parent = ActiveFolder, Name = ESP.Index, Adornee = ESP.CurrentSettings.Model, FillColor = ESP.CurrentSettings.FillColor or Color3.new(), OutlineColor = ESP.CurrentSettings.OutlineColor or Color3.new(1, 1, 1), FillTransparency = ESP.CurrentSettings.FillTransparency or 0.65, OutlineTransparency = ESP.CurrentSettings.OutlineTransparency or 0})
	end

	local Arrow = nil;
	if typeof(ESP.OriginalSettings.Arrow) == "table" then
		Arrow = InstancesLib.Create("ImageLabel", {Parent = MainGUI, Name = ESP.Index, Size = UDim2.new(0, 48, 0, 48), SizeConstraint = Enum.SizeConstraint.RelativeYY, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Image = "http://www.roblox.com/asset/?id=16368985219", ImageColor3 = ESP.CurrentSettings.Color or Color3.new()});
		ESP.CurrentSettings.Arrow.CenterOffset = if typeof(ESP.CurrentSettings.Arrow.CenterOffset) == "number" then ESP.CurrentSettings.Arrow.CenterOffset else 300;
	end

	function ESP:Destroy()
		if ESP.Deleted == true then return; end
		ESP.Deleted = true
		if table.find(Library.ESP, ESP.Index) then table.remove(Library.ESP, table.find(Library.ESP, ESP.Index)) end
		Library.ESP[ESP.Index] = nil
		if Billboard then Billboard:Destroy() end
		if Highlighter then Highlighter:Destroy() end
		if Arrow then Arrow:Destroy() end
		for _, connection in ESP.Connections do if connection and connection.Connected then connection:Disconnect() end end
		table.clear(ESP.Connections)
		if ESP.OriginalSettings.OnDestroy then SafeCallback(ESP.OriginalSettings.OnDestroy.Fire, ESP.OriginalSettings.OnDestroy) end
		if ESP.OriginalSettings.OnDestroyFunc then SafeCallback(ESP.OriginalSettings.OnDestroyFunc) end
		ESP.Render = function(...) end
	end

	local function Show(forceShow)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceShow ~= true and not ESP.Hidden then return end
		ESP.Hidden = false;
		Billboard.Enabled = true;
		if Highlighter then Highlighter.Adornee = ESP.CurrentSettings.Model; Highlighter.Parent = ActiveFolder; end
		if Arrow then Arrow.Visible = true; end
	end

	local function Hide(forceHide)
		if not (ESP and ESP.Deleted ~= true) then return end
		if forceHide ~= true and ESP.Hidden then return end
		ESP.Hidden = true
		Billboard.Enabled = false;
		if Highlighter then Highlighter.Adornee = nil; Highlighter.Parent = StorageFolder; end
		if Arrow then Arrow.Visible = false; end
	end

	function ESP:Show(force) ESP.CurrentSettings.Visible = true; Show(force); end
	function ESP:Hide(force) if not (ESP and ESP.CurrentSettings and ESP.Deleted ~= true) then return end ESP.CurrentSettings.Visible = false; Hide(force); end
	function ESP:ToggleVisibility(force) ESP.CurrentSettings.Visible = not ESP.CurrentSettings.Visible; if ESP.CurrentSettings.Visible then Show(force); else Hide(force); end end

	function ESP:Render()
		if not ESP then return end
		local ESPSettings = ESP.CurrentSettings
		if ESP.Deleted == true or not ESPSettings then return end
		if not (ESPSettings.Visible and camera and (if Library.GlobalConfig.IgnoreCharacter == true then true else rootPart)) then Hide() return end
		if not ESPSettings.ModelRoot then ESPSettings.ModelRoot = InstancesLib.FindPrimaryPart(ESPSettings.Model) end

		local modelRoot = ESPSettings.ModelRoot or ESPSettings.Model
		local distanceFromPlayer = InstancesLib.DistanceFrom(modelRoot, rootPart or camera)
		if distanceFromPlayer > ESPSettings.MaxDistance then Hide() return end
		local screenPos, isOnScreen = worldToViewport(GetPivot(modelRoot).Position)

		if ESPSettings.BeforeUpdate then SafeCallback(ESPSettings.BeforeUpdate, ESP) end

		if Arrow then
			Arrow.Visible = Library.GlobalConfig.Arrows == true and ESPSettings.Arrow.Enabled == true and (isOnScreen ~= true);
			if Arrow.Visible then
				local screenSize = camera.ViewportSize
				local centerPos = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
				local partPos = Vector2.new(screenPos.X, screenPos.Y);
				local IsInverted = screenPos.Z <= 0;
				local invert = (IsInverted and -1 or 1);
				local direction = (partPos - centerPos);
				local arctan = math.atan2(direction.Y, direction.X);
				local angle = math.deg(arctan) + 90;
				local distance = (ESPSettings.Arrow.CenterOffset * 0.001) * screenSize.Y;
				Arrow.Rotation = angle + 180 * (IsInverted and 0 or 1);
				Arrow.Position = UDim2.new(0, centerPos.X + (distance * math.cos(arctan) * invert), 0, centerPos.Y + (distance * math.sin(arctan) * invert));
				Arrow.ImageColor3 = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.Arrow.Color;
			end
		end

		if isOnScreen == false then Hide() return else Show() end

		if Billboard then
			Billboard.Enabled = Library.GlobalConfig.Billboards == true;
			if Billboard.Enabled then
				if Library.GlobalConfig.Distance then
					BillboardText.Text = string.format('%s\n<font size="%d">[%s]</font>', ESPSettings.Name, ESPSettings.TextSize - 3, math.floor(distanceFromPlayer));
				else BillboardText.Text = ESPSettings.Name; end
				BillboardText.Font = Library.GlobalConfig.Font;
				BillboardText.TextColor3 = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.Color;
				BillboardText.TextSize = ESPSettings.TextSize;
			end
		end

		if Highlighter then
			Highlighter.Parent = if Library.GlobalConfig.Highlighters == true then ActiveFolder else StorageFolder;
			Highlighter.Adornee = if Library.GlobalConfig.Highlighters == true then ESPSettings.Model else nil;
			if Highlighter.Adornee then
				if IsAdornment then
					Highlighter.Color3 = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.Color;
					Highlighter.Transparency = ESPSettings.Transparency
				elseif ESP.OriginalSettings.ESPType == "selectionbox" then
					Highlighter.Color3 = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.Color;
					Highlighter.LineThickness = ESPSettings.Thickness;
					Highlighter.SurfaceColor3 = ESPSettings.SurfaceColor;
					Highlighter.SurfaceTransparency = ESPSettings.Transparency;
				else
					Highlighter.FillColor = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.FillColor;
					Highlighter.OutlineColor = if Library.GlobalConfig.Rainbow then Library.RainbowColor else ESPSettings.OutlineColor;
					Highlighter.FillTransparency = ESPSettings.FillTransparency;
					Highlighter.OutlineTransparency = ESPSettings.OutlineTransparency;
				end
			end
		end
		if ESPSettings.AfterUpdate then SafeCallback(ESPSettings.AfterUpdate, ESP) end
	end
	if not ESP.OriginalSettings.Visible then Hide() end
	Library.ESP[ESP.Index] = ESP
	return ESP
end

table.insert(Library.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = workspace.CurrentCamera; end))
table.insert(Library.Connections, Players.LocalPlayer.CharacterAdded:Connect(UpdatePlayerVariables))
table.insert(Library.Connections, RunService.RenderStepped:Connect(function(Delta)
	if not Library.GlobalConfig.Rainbow then return end
	Library.RainbowStep = Library.RainbowStep + Delta
	if Library.RainbowStep >= (1 / 60) then
		Library.RainbowStep = 0
		Library.RainbowHueSetup = Library.RainbowHueSetup + (1 / 400)
		if Library.RainbowHueSetup > 1 then Library.RainbowHueSetup = 0 end
		Library.RainbowHue = Library.RainbowHueSetup
		Library.RainbowColor = Color3.fromHSV(Library.RainbowHue, 0.8, 1)
	end
end))

table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
	for Index, ESP in Library.ESP do
		if not ESP then Library.ESP[Index] = nil; continue end
		if ESP.Deleted == true or not (ESP.CurrentSettings and (ESP.CurrentSettings.Model and ESP.CurrentSettings.Model.Parent)) then ESP:Destroy() continue end
		pcall(ESP.Render, ESP)
	end
end))

getgenv().mstudio45_ESP = Library

local function InitESP(player)
    if player == Players.LocalPlayer then return end

    local function CharacterSetup(char)
        if not char then return end
        
        local root = char:WaitForChild("HumanoidRootPart", 10) or char:WaitForChild("Torso", 10)
        if not root then return end
        
        Library:Add({
            Model = char,
            Name = player.DisplayName or player.Name,
            Color = Color3.fromHex("FFA0B6"), 
            MaxDistance = 5000,
            ESPType = "Highlight",
            FillColor = Color3.fromHex("FFA0B6"), 
            OutlineColor = Color3.fromHex("FFA0B6"), 
            FillTransparency = 0.6,
            OutlineTransparency = 0
        })
    end

    if player.Character then 
        task.spawn(CharacterSetup, player.Character) 
    end
    player.CharacterAdded:Connect(CharacterSetup)
end

for _, player in ipairs(Players:GetPlayers()) do
    InitESP(player)
end

Players.PlayerAdded:Connect(InitESP)