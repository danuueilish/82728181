if _G.__BLUU_AURA_LOADED then return end
_G.__BLUU_AURA_LOADED = true
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local plr = LP
local WindUI = getgenv().BluuHubWindUI
local MainTab = getgenv().BluuHubWindow
if not (WindUI and MainTab) then return end
local EquipToolsRF = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("EquipTools")
local auraList = {
    "Blackred Love",
    "Green Glitch",
    "Pink Love",
    "Autumn",
    "Sakura",
    "Starlight",
    "Blueada",
    "Purple Wings",
}
local methodOptions = {
    "Single Aura",
    "Rotation Aura",
}
local selectedAuras = {}
local selectedMethod = methodOptions[1]
local rotationDelay = 3
local applyToggle = false
local rotationThread = nil
local ApplyAuraToggle
local function notify(title, content, dur)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = dur or 2
        })
    end)
end

local function equipAuraServer(auraName)
    local ok, res = pcall(function()
        return EquipToolsRF:InvokeServer("EquipAura", auraName or "")
    end)
    if not ok or res == false then
        return false
    end
    return true
end

local function clearAura()
    equipAuraServer("")
end

local function forceToggleOff(msg)
    applyToggle = false
    if ApplyAuraToggle and ApplyAuraToggle.Set then
        ApplyAuraToggle:Set(false)
    end
    if msg then
        notify("Aura", msg, 0.5)
    end
end

local function startRotation()
    if rotationThread then return end
    rotationThread = task.spawn(function()
        while applyToggle do
            if #selectedAuras == 0 then
                break
            end
            for i = 1, #selectedAuras do
                if not applyToggle then break end
                local name = selectedAuras[i]
                if name and name ~= "" then
                    equipAuraServer(name)
                end
                local t0 = os.clock()
                while applyToggle and (os.clock() - t0) < rotationDelay do
                    task.wait(0.1)
                end
            end
        end
        clearAura()
        rotationThread = nil
    end)
end

local function handleToggleOn()
    if selectedMethod == "Single Aura" then
        if #selectedAuras ~= 1 then
            forceToggleOff("You need choose only 1 Aura.")
            return
        end
        local auraName = selectedAuras[1]
        local ok = equipAuraServer(auraName)
        if not ok then
            forceToggleOff("Failed equip aura " .. tostring(auraName))
            return
        end
        notify("Aura", "Applied " .. auraName, 0.5)
    else
        if #selectedAuras <= 1 then
            forceToggleOff("Rotation mode need atleast minimal 2 aura")
            return
        end
        notify("Aura", "Rotation started (" .. #selectedAuras .. " auras)", 0.5)
        startRotation()
    end
end

local function handleToggleOff()
    applyToggle = false
    clearAura()
    notify("Aura", "Aura removed", 0.5)
end

local ExtrasTab:Section({
    Title = "Aura",
    Opened = true,
})
ExtrasTab:Space({ Columns = 0.2 })
ExtrasTab:Dropdown({
    Title = "Select Aura",
    Values = auraList,
    Default = auraList[1],
    Multi = true,
    Flag = "Bluu_AuraSelect",
    Callback = function(selection)
        local list = {}
        if type(selection) == "table" then
            for _, name in ipairs(selection) do
                if name and name ~= "" then
                    table.insert(list, name)
                end
            end
        elseif type(selection) == "string" then
            if selection ~= "" then
                table.insert(list, selection)
            end
        end
        selectedAuras = list
    end,
})

ExtrasTab:Dropdown({
    Title = "Method",
    Values = methodOptions,
    Default = methodOptions[1],
    Multi = false,
    Flag = "Bluu_AuraMethod",
    Callback = function(method)
        if method then
            selectedMethod = method
        end
    end,
})

ExtrasTab:Slider({
    Title = "Rotation Delay",
    Step = 0.5,
    Value = {
        Min = 0.5,
        Max = 30,
        Default = rotationDelay,
    },
    Flag = "Bluu_AuraDelay",
    Callback = function(v)
        local num = tonumber(v)
        if not num then return end
        rotationDelay = math.clamp(num, 0.5, 30)
    end,
})

ExtrasTab = AuraSection:Toggle({
    Title = "Apply Aura",
    Default = false,
    Flag = "Bluu_AuraApply",
    Callback = function(state)
        applyToggle = state
        if state then
            handleToggleOn()
        else
            handleToggleOff()
        end
    end,
})