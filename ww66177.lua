if _G.AutoConvertFishLoaded then return end
_G.AutoConvertFishLoaded = true
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local ConvertRemote = ReplicatedStorage
    :WaitForChild("Events")
    :WaitForChild("RemoteFunction")
    :WaitForChild("Gopay")
local running = false
local busy = false
local maxWeightKg = 50
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
local function updateTokenUI()
    if not _G.BluuHub_SetGopayToken then return end
    local ok, result = pcall(function()
        return ConvertRemote:InvokeServer("CheckToken")
    end)
    if ok and result ~= nil then
        pcall(_G.BluuHub_SetGopayToken, result)
    end
end
local function convertLoop()
    task.spawn(function()
        while running do
            if busy then
                task.wait()
                continue
            end
            busy = true
            local tool = equipFishUnderLimit()
            if not tool then
                busy = false
                break
            end
            task.wait(0.5)
            pcall(function()
                ConvertRemote:InvokeServer("ConvertIkan")
            end)
            updateTokenUI()
            busy = false
            task.wait(0.2)
        end
        running = false
    end)
end
_G.EnableAutoConvert = function(weightLimitKg)
    if running then return end
    maxWeightKg = tonumber(weightLimitKg) or 50
    running = true
    convertLoop()
end
_G.DisableAutoConvert = function()
    running = false
    busy = false
end
