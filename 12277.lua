if _G.__WINTER_QUEST_LOADED then return end
_G.__WINTER_QUEST_LOADED = true

_G.AutoWinterQuest = _G.AutoWinterQuest or false
_G.RunningWinterQuest = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local WinterEvent = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("WinterEvent")

local NPC_CFRAME = CFrame.new(6597, -51, 6837)
local FISHING_POS = Vector3.new(6597, -51, 6837)

_G.WinterQuest = _G.WinterQuest or {
    Type = nil,
    Fish = nil,
    Need = 0,
    Count = 0
}

local function tp(cf)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf
    end
end

local function checkQuest()
    local ok, res = pcall(function()
        return WinterEvent:InvokeServer("CheckQuest")
    end)
    return ok and res
end

local function getQuest()
    pcall(function()
        WinterEvent:InvokeServer("GetQuest")
    end)
end

local function getQuestInfo()
    local ok, info = pcall(function()
        return WinterEvent:InvokeServer("GetQuestInfo")
    end)
    if ok and type(info) == "table" then
        _G.WinterQuest.Type = info.Type
        _G.WinterQuest.Fish = info.Fish
        _G.WinterQuest.Need = info.Need or 0
        _G.WinterQuest.Count = info.Progress or 0
        return true
    end
end

local function giveFish()
    local gui = LP.PlayerGui:FindFirstChild("BackpackGui")
    if not gui then return end

    local inv = gui.Backpack.Inventory.ScrollingFrame.UIGridFrame
    if not inv then return end

    local given = 0
    for _, item in ipairs(inv:GetChildren()) do
        if not _G.AutoWinterQuest then break end
        if given >= _G.WinterQuest.Need then break end

        local weight = item:FindFirstChild("Weight")
        if weight then
            local w = tonumber(weight.Text)
            if w and w < 200 then
                firesignal(item.MouseButton1Click)
                task.wait(0.15)
                tp(NPC_CFRAME)
                task.wait(0.4)
                given += 1
            end
        end
    end
end

task.spawn(function()
    while task.wait(1.5) do
        if not _G.AutoWinterQuest then
            _G.RunningWinterQuest = false
            break
        end

        if _G.RunningWinterQuest then continue end
        _G.RunningWinterQuest = true

        
        tp(NPC_CFRAME)
        task.wait(0.7)

        
        if not checkQuest() then
            getQuest()
            task.wait(0.6)
        end

        
        if not getQuestInfo() then
            _G.RunningWinterQuest = false
            continue
        end

        
        tp(CFrame.new(FISHING_POS))
        task.wait(0.5)

        
        _G.AutoFishingV2 = true

        repeat
            task.wait(1)
            getQuestInfo()
        until
            _G.WinterQuest.Count >= _G.WinterQuest.Need
            or not _G.AutoWinterQuest

        _G.AutoFishingV2 = false

        
        if _G.WinterQuest.Type == "GiveFish" then
            tp(NPC_CFRAME)
            task.wait(0.6)
            giveFish()
        end

        
        task.wait(2)
        _G.RunningWinterQuest = false
    end

    _G.__WINTER_QUEST_LOADED = false
end)
