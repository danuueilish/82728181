if _G.AutoSellFishLoaded then return end
_G.AutoSellFishLoaded = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer

local SellRemote = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("SellFish")

local running = false
local busy = false
local targetFish = nil
local sellLeft = 0

local function isFavoriteTool(tool)
    if not tool or not tool.Name then return false end
    return tool.Name:find("%(Favorite%)") ~= nil
end

local function equipFish()
    local char = LP.Character
    if not char then return nil end

    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool")
            and tool.Name:lower():find(targetFish)
            and not isFavoriteTool(tool) then

            tool.Parent = char
            return tool
        end
    end
end

local function sellLoop()
    task.spawn(function()
        while running and sellLeft > 0 do
            if busy then task.wait() continue end
            busy = true

            local tool = equipFish()
            if not tool then
                busy = false
                break
            end

            task.wait(0.5)

            SellRemote:InvokeServer("SellFish", "Sell this fish")

            sellLeft -= 1
            busy = false
            task.wait(0.2)
        end

        running = false
    end)
end

_G.EnableAutoSell = function(fishName, amount)
    if running then return end
    targetFish = tostring(fishName):lower()
    sellLeft = tonumber(amount) or 1
    running = true
    sellLoop()
end

_G.DisableAutoSell = function()
    running = false
    busy = false
end