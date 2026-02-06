if _G.__BLUU_AURA_CORE_LOADED then
    return
end
_G.__BLUU_AURA_CORE_LOADED = true
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local EquipToolsRF = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("EquipTools")
_G.AuraList = {
    "Blackred Love",
    "Green Glitch",
    "Pink Love",
    "Autumn",
    "Sakura",
    "Starlight",
    "Blueada",
    "Purple Wings",
}
_G.AuraMethodList = {
    "Single Aura",
    "Rotation Aura",
}
_G.AuraSelected = {}
_G.AuraMethod = "Single Aura"
_G.AuraDelay = 3
_G.AuraRunning = false

local function equipAura(name)
    local ok, res = pcall(function()
        return EquipToolsRF:InvokeServer("EquipAura", name or "")
    end)
    if not ok or res == false then
        return false
    end
    return true
end

local function clearAura()
    equipAura("")
end

function _G.SetAuraSelection(selection)
    local list = {}
    if type(selection) == "table" then
        for _, v in ipairs(selection) do
            if v and v ~= "" then
                table.insert(list, v)
            end
        end
    elseif type(selection) == "string" then
        if selection ~= "" then
            table.insert(list, selection)
        end
    end
    _G.AuraSelected = list
end

function _G.SetAuraMethod(method)
    if method == "Single Aura" or method == "Rotation Aura" then
        _G.AuraMethod = method
    end
end

function _G.SetAuraDelay(value)
    local n = tonumber(value)
    if not n then
        return
    end
    if n < 0.1 then
        n = 0.1
    end
    _G.AuraDelay = n
end
function _G.DisableAura()
    _G.AuraRunning = false
    clearAura()
end
function _G.EnableAura()
    if _G.AuraRunning then
        return true
    end
    local list = _G.AuraSelected or {}
    local count = #list
    local method = _G.AuraMethod or "Single Aura"
    local delay = _G.AuraDelay or 3
    if method == "Single Aura" then
        if count ~= 1 then
            return false, "Single Aura allowed 1 aura"
        end
        local auraName = list[1]
        local ok = equipAura(auraName)
        if not ok then
            return false, "Failed equip aura: " .. tostring(auraName)
        end
        _G.AuraRunning = true
        return true
    else
        if count < 2 then
            return false, "Rotation need minimal choose 2 aura"
        end
        _G.AuraRunning = true
        task.spawn(function()
            while _G.AuraRunning do
                local currentList = _G.AuraSelected or {}
                if #currentList < 2 then
                    break
                end
                for i = 1, #currentList do
                    if not _G.AuraRunning then
                        break
                    end
                    local auraName = currentList[i]
                    if auraName and auraName ~= "" then
                        equipAura(auraName)
                    end
                    local startTime = os.clock()
                    local d = _G.AuraDelay or delay
                    if d < 0.1 then
                        d = 0.1
                    end
                    while _G.AuraRunning and (os.clock() - startTime) < d do
                        task.wait(0.1)
                    end
                end
            end
            clearAura()
            _G.AuraRunning = false
        end)
        return true
    end
end