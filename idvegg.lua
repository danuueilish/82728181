if getgenv().BluuEasterEggESP then
    getgenv().BluuEasterEggESP:Destroy()
    getgenv().BluuEasterEggESP = nil
    task.wait(0.1)
end

local cloneref = getgenv().cloneref or function(inst) return inst end
local Players     = cloneref(game:GetService("Players"))
local RunService  = cloneref(game:GetService("RunService"))
local CoreGui     = cloneref(game:GetService("CoreGui"))

local LP = Players.LocalPlayer

local tablefreeze = function(t)
    local proxy, data = {}, table.clone(t)
    return setmetatable(proxy, {
        __index    = function(_, k) return data[k] end,
        __newindex = function() end,
    })
end

local function GetPivot(inst)
    if inst.ClassName == "Bone"       then return inst.TransformedWorldCFrame
    elseif inst.ClassName == "Attachment" then return inst.WorldCFrame
    elseif inst.ClassName == "Camera" then return inst.CFrame
    else return inst:GetPivot() end
end

local function RandomString(len)
    len = tonumber(len) or math.random(10, 20)
    local arr = {}
    for i = 1, len do arr[i] = string.char(math.random(32, 126)) end
    return table.concat(arr)
end

local function SafeCallback(fn, ...)
    if not (fn and typeof(fn) == "function") then return end
    local r = table.pack(xpcall(fn, function(e) return e end, ...))
    if not r[1] then return nil end
    return table.unpack(r, 2, r.n)
end

local IL = {
    Create = function(t, p)
        local i = Instance.new(t)
        for k, v in pairs(p) do if k ~= "Parent" then i[k] = v end end
        if p.Parent then i.Parent = p.Parent end
        return i
    end,
    FindPrimaryPart = function(inst)
        if typeof(inst) ~= "Instance" then return nil end
        return (inst:IsA("Model") and inst.PrimaryPart or nil)
            or inst:FindFirstChildWhichIsA("BasePart")
            or inst:FindFirstChildWhichIsA("UnionOperation")
            or inst
    end,
    DistanceFrom = function(inst, from)
        if not (inst and from) then return 9e9 end
        local pos  = typeof(inst) == "Instance" and GetPivot(inst).Position  or inst
        local fpos = typeof(from) == "Instance" and GetPivot(from).Position or from
        return (fpos - pos).Magnitude
    end,
}

local getui
do
    local tg = Instance.new("ScreenGui")
    local ok = pcall(function() tg.Parent = CoreGui end)
    getui = ok and function() return CoreGui end
               or  function() return LP.PlayerGui end
    tg:Destroy()
end

local AF = IL.Create("Folder",    { Parent = getui(), Name = RandomString() })
local SF = IL.Create("Folder",    { Parent = game,    Name = RandomString() })
local MG = IL.Create("ScreenGui", { Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999 })
local BG = IL.Create("ScreenGui", { Parent = getui(), Name = RandomString(), IgnoreGuiInset = true, ResetOnSpawn = false, ClipToDeviceSafeArea = false, DisplayOrder = 999999 })

local camera = workspace.CurrentCamera

local Library = {
    Destroyed = false,
    ActiveFolder  = AF, StorageFolder = SF,
    MainGUI = MG,       BillboardGUI  = BG,
    Connections = {},   ESP = {},
    GlobalConfig = {
        IgnoreCharacter = true,
        Rainbow         = false,
        Billboards      = true,
        Highlighters    = true,
        Distance        = true,
        Font            = Enum.Font.GothamBold,
    },
    RainbowHueSetup = 0, RainbowHue = 0,
    RainbowStep = 0,     RainbowColor = Color3.new(),
}

local function wtvp(...)
    camera = camera or workspace.CurrentCamera
    if not camera then return Vector2.new(), false end
    return camera:WorldToViewportPoint(...)
end

function Library:Clear()
    if self.Destroyed then return end
    for _, e in pairs(self.ESP) do if e then e:Destroy() end end
end

function Library:Destroy()
    if self.Destroyed then return end
    self:Clear()
    self.Destroyed = true
    AF:Destroy(); SF:Destroy(); MG:Destroy(); BG:Destroy()
    for _, c in self.Connections do
        if c and c.Connected then c:Disconnect() end
    end
    table.clear(self.Connections)
    getgenv().BluuEasterEggESP = nil
end

function Library:Add(s)
    if self.Destroyed then return end
    s.ESPType             = string.lower(s.ESPType or "highlight")
    s.Name                = typeof(s.Name)  == "string"  and s.Name  or s.Model.Name
    s.TextModel           = typeof(s.TextModel) == "Instance" and s.TextModel or s.Model
    s.Visible             = typeof(s.Visible) == "boolean" and s.Visible or true
    s.Color               = typeof(s.Color) == "Color3"  and s.Color  or Color3.new()
    s.MaxDistance         = typeof(s.MaxDistance) == "number" and s.MaxDistance or 9e9
    s.StudsOffset         = typeof(s.StudsOffset) == "Vector3" and s.StudsOffset or Vector3.new(0, 3.5, 0)
    s.TextSize            = typeof(s.TextSize) == "number" and s.TextSize or 22
    s.FillColor           = typeof(s.FillColor) == "Color3" and s.FillColor or Color3.new()
    s.OutlineColor        = typeof(s.OutlineColor) == "Color3" and s.OutlineColor or Color3.new(1,1,1)
    s.FillTransparency    = typeof(s.FillTransparency) == "number" and s.FillTransparency or 0.45
    s.OutlineTransparency = typeof(s.OutlineTransparency) == "number" and s.OutlineTransparency or 0

    local ESP = {
        Index = RandomString(), OriginalSettings = tablefreeze(s),
        CurrentSettings = s,   Hidden = false, Deleted = false, Connections = {},
    }

    local Billboard = IL.Create("BillboardGui", {
        Parent = BG, Name = ESP.Index, Enabled = true, ResetOnSpawn = false,
        AlwaysOnTop = true, Size = UDim2.new(0, 220, 0, 60),
        Adornee = s.TextModel, StudsOffset = s.StudsOffset,
    })
    local BillboardText = IL.Create("TextLabel", {
        Parent = Billboard, Size = UDim2.new(0, 220, 0, 60),
        Font = Library.GlobalConfig.Font, TextWrapped = true, RichText = true,
        TextStrokeTransparency = 0, BackgroundTransparency = 1,
        Text = s.Name, TextColor3 = s.Color, TextSize = s.TextSize,
    })
    IL.Create("UIStroke", { Parent = BillboardText, Thickness = 1.5 })

    local Highlighter = IL.Create("Highlight", {
        Parent = AF, Name = ESP.Index, Adornee = s.Model,
        FillColor = s.FillColor, OutlineColor = s.OutlineColor,
        FillTransparency = s.FillTransparency, OutlineTransparency = s.OutlineTransparency,
    })

    function ESP:Destroy()
        if self.Deleted then return end
        self.Deleted = true
        Library.ESP[self.Index] = nil
        if Billboard    then Billboard:Destroy() end
        if Highlighter  then Highlighter:Destroy() end
        for _, c in self.Connections do if c and c.Connected then c:Disconnect() end end
        table.clear(self.Connections)
        self.Render = function() end
    end

    local function Show()
        if not ESP or ESP.Deleted then return end
        ESP.Hidden = false
        Billboard.Enabled = true
        Highlighter.Adornee = s.Model; Highlighter.Parent = AF
    end

    local function Hide()
        if not ESP or ESP.Deleted then return end
        ESP.Hidden = true
        Billboard.Enabled = false
        Highlighter.Adornee = nil; Highlighter.Parent = SF
    end

    function ESP:Render()
        if self.Deleted or not s then return end
        if not s.Visible then Hide() return end

        if not s.ModelRoot then s.ModelRoot = IL.FindPrimaryPart(s.Model) end
        local root = s.ModelRoot or s.Model

        local dist = IL.DistanceFrom(root, camera)
        if dist > s.MaxDistance then Hide() return end

        local _, onScreen = wtvp(GetPivot(root).Position)
        if not onScreen then Hide() return else Show() end

        if Library.GlobalConfig.Billboards then
            Billboard.Enabled = true
            BillboardText.Text = Library.GlobalConfig.Distance
                and string.format("<b>Easter Egg</b>\n<font size=\"%d\">[%d studs]</font>", s.TextSize - 2, math.floor(dist))
                or  "<b>Easter Egg</b>"
            BillboardText.TextColor3 = Library.GlobalConfig.Rainbow and Library.RainbowColor or s.Color
            BillboardText.TextSize   = s.TextSize
        else
            Billboard.Enabled = false
        end
        if Library.GlobalConfig.Highlighters then
            Highlighter.Parent  = AF
            Highlighter.Adornee = s.Model
            Highlighter.FillColor           = Library.GlobalConfig.Rainbow and Library.RainbowColor or s.FillColor
            Highlighter.OutlineColor        = Library.GlobalConfig.Rainbow and Library.RainbowColor or s.OutlineColor
            Highlighter.FillTransparency    = s.FillTransparency
            Highlighter.OutlineTransparency = s.OutlineTransparency
        else
            Highlighter.Parent  = SF
            Highlighter.Adornee = nil
        end
    end

    if not s.Visible then Hide() end
    Library.ESP[ESP.Index] = ESP
    return ESP
end

table.insert(Library.Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera
end))

table.insert(Library.Connections, RunService.RenderStepped:Connect(function(dt)
    if not Library.GlobalConfig.Rainbow then return end
    Library.RainbowStep += dt
    if Library.RainbowStep >= (1/60) then
        Library.RainbowStep = 0
        Library.RainbowHueSetup = (Library.RainbowHueSetup + 1/400) % 1
        Library.RainbowColor = Color3.fromHSV(Library.RainbowHueSetup, 0.8, 1)
    end
end))

table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
    for idx, e in Library.ESP do
        if not e then Library.ESP[idx] = nil; continue end
        if e.Deleted or not (e.CurrentSettings and e.CurrentSettings.Model and e.CurrentSettings.Model.Parent) then
            e:Destroy(); continue
        end
        pcall(e.Render, e)
    end
end))

getgenv().BluuEasterEggESP = Library
local EGG_COLOR   = Color3.fromHex("FFD700")
local EGG_OUTLINE = Color3.fromHex("FFFFFF")
local function AddEggESP(egg)
    if not egg or not egg.Parent then return end
    local attachment = egg:FindFirstChildOfClass("Attachment")
        or egg:FindFirstChild("Attachment")
    local adornTarget = attachment or egg
    Library:Add({
        Model               = egg,
        TextModel           = adornTarget,
        Name                = "Easter Egg",
        Color               = EGG_COLOR,
        MaxDistance         = 9e9,
        ESPType             = "Highlight",
        FillColor           = EGG_COLOR,
        OutlineColor        = EGG_OUTLINE,
        FillTransparency    = 0.45,
        OutlineTransparency = 0,
        TextSize            = 22,
        StudsOffset         = Vector3.new(0, 4, 0),
    })
end

local function HookFolder(folder)
    for _, egg in ipairs(folder:GetChildren()) do
        task.spawn(AddEggESP, egg)
    end
    folder.ChildAdded:Connect(function(egg)
        task.wait(0.2)
        AddEggESP(egg)
    end)
end

task.spawn(function()
    local temp = workspace:FindFirstChild("Temp") or workspace:WaitForChild("Temp", 15)
    if not temp then return end

    local eggFolder = temp:FindFirstChild("EasterEgg")
    if eggFolder then
        HookFolder(eggFolder)
    else
        temp.ChildAdded:Connect(function(child)
            if child.Name == "EasterEgg" then
                HookFolder(child)
            end
        end)
    end
end)
