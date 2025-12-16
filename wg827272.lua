if _G.AutoGiveWinterLoaded then return end
_G.AutoGiveWinterLoaded = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local WinterEvent = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("WinterEvent")

local Prompt = workspace.WinterDeco
    .ChrismastEventBooth
    .Rig
    .Torso
    :WaitForChild("ProximityPrompt")

local running = false
local busy = false
local selectedFish = nil
local giveLeft = 0

local function equipFish()
    local char = LP.Character
    if not char then return nil end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(selectedFish) then
            tool.Parent = char
            return tool
        end
    end
end

local function giveLoop()
    task.spawn(function()
        while running and giveLeft > 0 do
            if busy then task.wait() continue end
            busy = true

            -- FIRE NPC (sekali, tunggu)
            fireproximityprompt(Prompt)
            task.wait(2)

            -- QUEST (logic asli server)
            WinterEvent:InvokeServer("CheckQuest")
            WinterEvent:InvokeServer("GetQuestInfo")
            task.wait(2)

            -- EQUIP FISH (JANGAN DILEPAS)
            local tool = equipFish()
            if not tool then
                busy = false
                break
            end

            task.wait(2)

            -- GIVE
            WinterEvent:InvokeServer("EndQuest")
            task.wait(2)

            giveLeft -= 1
            busy = false
        end
    end)
end

_G.EnableAutoGive = function(fishName, amount)
    if running then return end
    selectedFish = tostring(fishName):lower()
    giveLeft = tonumber(amount) or 1
    running = true
    giveLoop()
end

_G.DisableAutoGive = function()
    running = false
    busy = false
end
