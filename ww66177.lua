if _G.AutoConvertFishLoaded then return end
_G.AutoConvertFishLoaded = true
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local ConvertRemote = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("Gopay")
local running     = false
local busy        = false
local maxWeightKg = 50
local convertMode = "single"
local function isFavoriteTool(tool)
    if not tool or not tool.Name then return false end
    return tool.Name:find("%(Favorite%)") ~= nil
end
local function getWeightFromName(name)
    if not name then return nil end
    name = name:lower()
    local num = name:match("(%d+)%s*kg")
    if num then
        return tonumber(num)
    end
    return nil
end
local function equipFishUnderLimit()
    local char = LP.Character
    if not char then return nil end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and not isFavoriteTool(tool) then
            local w = getWeightFromName(tool.Name)
            if w and w <= maxWeightKg then
                tool.Parent = char
                return tool
            end
        end
    end
    return nil
end
local function equipAllUnderLimit()
    local char = LP.Character
    if not char then return 0 end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return 0 end
    local count = 0
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and not isFavoriteTool(tool) then
            local w = getWeightFromName(tool.Name)
            if w and w <= maxWeightKg then
                tool.Parent = char
                count += 1
            end
        end
    end
    return count
end
local function convertLoop()
    task.spawn(function()
        while running do
            if busy then
                task.wait()
                continue
            end
            busy = true
            if convertMode == "all" then
                local equippedCount = equipAllUnderLimit()
                if equippedCount == 0 then
                    busy = false
                    break
                end
                task.wait(0.5)
                pcall(function()
                    ConvertRemote:InvokeServer("ConvertIkan")
                end)
            else
                local tool = equipFishUnderLimit()
                if not tool then
                    busy = false
                    break
                end
                task.wait(0.5)
                pcall(function()
                    ConvertRemote:InvokeServer("ConvertIkan")
                end)
            end
            busy = false
            task.wait(0.2)
        end
        running = false
    end)
end
_G.EnableAutoConvert = function(weightLimitKg, modeStr)
    if running then return end
    maxWeightKg = tonumber(weightLimitKg) or 50
    modeStr = tostring(modeStr or ""):lower()
    if modeStr == "all" then
        convertMode = "all"
    else
        convertMode = "single"
    end
    running = true
    convertLoop()
end
_G.DisableAutoConvert = function()
    running = false
    busy    = false
end
