local Workspace = game:GetService("Workspace")

local Map = Workspace:FindFirstChild("Map") or Workspace

local GeneratorESPObjects = {}
local PalletESPObjects    = {}
local WindowESPObjects    = {}
local HookESPObjects      = {}

local function isGenerator(obj)
    return obj:IsA("Model") and obj.Name:lower() == "generator"
end

local function isPallet(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local n = obj.Name:lower()
    return n == "wrong pallet" or n == "palletwrong" or n == "palletalien"
end

local function isWindow(obj)
    return (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower() == "window"
end

local function isHook(obj)
    return (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower() == "hook"
end

local function createHighlight(target, color)
    if not target then return end

    local hl = Instance.new("Highlight")
    hl.Name = "VD_MapESP"
    hl.Adornee = target
    hl.FillColor = color or Color3.new(1, 1, 1)
    hl.OutlineColor = hl.FillColor
    hl.FillTransparency = 0.35
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target

    return hl
end

local function clearTable(tbl)
    for inst, hl in pairs(tbl) do
        if hl then
            hl:Destroy()
        end
        tbl[inst] = nil
    end
end

local function cleanDead(tbl)
    for inst, hl in pairs(tbl) do
        if not inst or not inst.Parent or not hl or not hl.Parent then
            if hl then
                hl:Destroy()
            end
            tbl[inst] = nil
        end
    end
end

local function ensureHighlight(inst, tbl, color)
    local hl = tbl[inst]
    if not hl then
        hl = createHighlight(inst, color)
        if hl then
            tbl[inst] = hl
        end
    else
        hl.FillColor    = color
        hl.OutlineColor = color
    end
end

task.spawn(function()
    while task.wait(0.5) do
        local genEnabled    = _G.ESP_GENERATOR or false
        local palletEnabled = _G.ESP_PALLET    or false
        local windowEnabled = _G.ESP_WINDOW    or false
        local hookEnabled   = _G.ESP_HOOK      or false

        local genColor    = _G.ESP_GENERATOR_COLOR or Color3.new(1, 0, 0)
        local palletColor = _G.ESP_PALLET_COLOR    or Color3.new(0.745098, 0.494118, 0.137255)
        local windowColor = _G.ESP_WINDOW_COLOR    or Color3.new(0.25, 0.615, 0.914)
        local hookColor   = _G.ESP_HOOK_COLOR      or Color3.new(0.854902, 0.298039, 0.298039)

        if not genEnabled then
            clearTable(GeneratorESPObjects)
        else
            cleanDead(GeneratorESPObjects)
        end

        if not palletEnabled then
            clearTable(PalletESPObjects)
        else
            cleanDead(PalletESPObjects)
        end

        if not windowEnabled then
            clearTable(WindowESPObjects)
        else
            cleanDead(WindowESPObjects)
        end

        if not hookEnabled then
            clearTable(HookESPObjects)
        else
            cleanDead(HookESPObjects)
        end

        for _, obj in ipairs(Map:GetDescendants()) do
            if genEnabled and isGenerator(obj) then
                ensureHighlight(obj, GeneratorESPObjects, genColor)
            end

            if palletEnabled and isPallet(obj) then
                ensureHighlight(obj, PalletESPObjects, palletColor)
            end

            if windowEnabled and isWindow(obj) then
                ensureHighlight(obj, WindowESPObjects, windowColor)
            end

            if hookEnabled and isHook(obj) then
                ensureHighlight(obj, HookESPObjects, hookColor)
            end
        end
    end
end)
