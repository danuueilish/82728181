local Workspace = game:GetService("Workspace")

local Map = Workspace:FindFirstChild("Map") or Workspace

local GeneratorESPObjects = {}
local PalletESPObjects    = {}
local WindowESPObjects    = {}
local HookESPObjects      = {}
local GateESPObjects      = {}
local GiftESPObjects      = {}
local GeneratorLabels     = {}

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

local function isGate(obj)
    return (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower() == "gate"
end

local function isGift(obj)
    return (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower() == "gift"
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

local function getGeneratorProgress(gen)
    local progress = 0

    if gen:GetAttribute("Progress") ~= nil then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") ~= nil then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in ipairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end

    if progress > 1 then
        progress = progress / 100
    end

    return math.clamp(progress, 0, 1)
end

local function getProgressColor(percent)
    local r = 255 * (1 - percent)
    local g = 255 * percent
    return Color3.fromRGB(r, g, 0)
end

local function generatorFinished(gen)
    return getGeneratorProgress(gen) >= 0.99
        or gen:FindFirstChild("Finished")
        or gen:FindFirstChild("Repaired")
end

local function ensureGeneratorLabel(genModel, text, color)
    if not genModel then return end

    local gui = GeneratorLabels[genModel]
    if not gui or not gui.Parent then
        gui = Instance.new("BillboardGui")
        gui.Name = "VD_GenLabel"
        gui.Size = UDim2.new(0, 80, 0, 18)
        gui.StudsOffset = Vector3.new(0, 4, 0)
        gui.AlwaysOnTop = true
        gui.MaxDistance = 500

        local rootPart = genModel:FindFirstChildWhichIsA("BasePart")
        gui.Parent = rootPart or genModel

        local lbl = Instance.new("TextLabel")
        lbl.Name = "TextLabel"
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextScaled = true
        lbl.TextStrokeTransparency = 0.4
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Text = text or ""
        lbl.Parent = gui

        GeneratorLabels[genModel] = gui
    end

    local lbl = gui:FindFirstChild("TextLabel")
    if lbl then
        lbl.Text = text or lbl.Text
        if color then
            lbl.TextColor3 = color
        end
    end
end

local function clearGeneratorLabel(genModel)
    local gui = GeneratorLabels[genModel]
    if gui then
        gui:Destroy()
        GeneratorLabels[genModel] = nil
    end
end

local function clearAllGeneratorLabels()
    for gen, gui in pairs(GeneratorLabels) do
        if gui then gui:Destroy() end
        GeneratorLabels[gen] = nil
    end
end

local function cleanDeadGeneratorLabels()
    for gen, gui in pairs(GeneratorLabels) do
        if (not gen or not gen.Parent) or (not gui or not gui.Parent) then
            if gui then gui:Destroy() end
            GeneratorLabels[gen] = nil
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        local genEnabled    = _G.ESP_GENERATOR or false
        local palletEnabled = _G.ESP_PALLET    or false
        local windowEnabled = _G.ESP_WINDOW    or false
        local hookEnabled   = _G.ESP_HOOK      or false
        local gateEnabled   = _G.ESP_GATE      or false
        local giftEnabled   = _G.ESP_GIFT      or false

        local genColor    = _G.ESP_GENERATOR_COLOR or Color3.new(1, 0, 0)
        local palletColor = _G.ESP_PALLET_COLOR    or Color3.new(0.745098, 0.494118, 0.137255)
        local windowColor = _G.ESP_WINDOW_COLOR    or Color3.new(0.25, 0.615, 0.914)
        local hookColor   = _G.ESP_HOOK_COLOR      or Color3.new(0.854902, 0.298039, 0.298039)
        local gateColor = _G.ESP_GATE_COLOR or Color3.new(0.854902, 0.298039, 0.298039)
        local giftColor = _G.ESP_GIFT_COLOR or Color3.new(0.854902, 0.298039, 0.298039)

        if not genEnabled then
            clearTable(GeneratorESPObjects)
            clearAllGeneratorLabels()
        else
            cleanDead(GeneratorESPObjects)
            cleanDeadGeneratorLabels()
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

        if not gateEnabled then
            clearTable(GateESPObjects)
        else
            cleanDead(GateESPObjects)
        end

        if not giftEnabled then
            clearTable(GiftESPObjects)
        else
            cleanDead(GiftESPObjects)
        end

        for _, obj in ipairs(Map:GetDescendants()) do
            if genEnabled and isGenerator(obj) then
                ensureHighlight(obj, GeneratorESPObjects, genColor)
                local progress = getGeneratorProgress(obj)
                if not generatorFinished(obj) then
                    local percent = math.floor(progress * 100 + 0.5)
                    if percent == 0 and progress > 0 then
                        percent = 1
                    end
                    local color = getProgressColor(progress)
                    ensureGeneratorLabel(obj, "[" .. tostring(percent) .. "%]", color)
                else
                    clearGeneratorLabel(obj)
                end
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

            if gateEnabled and isGate(obj) then
                ensureHighlight(obj, GateESPObjects, gateColor)
            end

            if giftEnabled and isGift(obj) then
                ensureHighlight(obj, GiftESPObjects, giftColor)
            end
        end
    end
end)
