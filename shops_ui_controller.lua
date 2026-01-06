if _G.ShopUiControllerLoaded then return end
_G.ShopUiControllerLoaded = true
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local GUI_NAMES = {
    RodShop       = "RodShop",
    RodShopWINTER = "RodShopWINTER",
    AuraShop      = "AuraShop",
    Index         = "Index",
}
local State = {}
local function getTemplate(guiName)
    local data = State[guiName]
    if data and data.template and data.template.Parent then
        return data.template
    end
    local template = StarterGui:FindFirstChild(guiName)
    if not State[guiName] then State[guiName] = {} end
    State[guiName].template = template
    return template
end
local function spawnGui(guiName)
    local inst = PlayerGui:FindFirstChild(guiName)
    if inst then
        if inst:IsA("ScreenGui") or inst:IsA("BillboardGui") then
            inst.Enabled = true
        end
        State[guiName] = State[guiName] or {}
        State[guiName].instance = inst
        return inst
    end
    local template = getTemplate(guiName)
    if not template then
        return nil
    end
    local clone = template:Clone()
    clone.ResetOnSpawn = false
    clone.Parent = PlayerGui
    if clone:IsA("ScreenGui") or clone:IsA("BillboardGui") then
        clone.Enabled = true
    end
    State[guiName] = State[guiName] or {}
    State[guiName].instance = clone
    State[guiName].cloned   = true
    return clone
end
local function destroyGui(guiName)
    local data = State[guiName]
    local inst = data and data.instance or PlayerGui:FindFirstChild(guiName)
    if inst then
        inst:Destroy()
    end
    if data then
        data.instance = nil
        data.cloned   = false
    end
end
_G.EnableRodShop = function()
    spawnGui(GUI_NAMES.RodShop)
end
_G.DisableRodShop = function()
    destroyGui(GUI_NAMES.RodShop)
end
_G.EnableRodShopWINTER = function()
    spawnGui(GUI_NAMES.RodShopWINTER)
end
_G.DisableRodShopWINTER = function()
    destroyGui(GUI_NAMES.RodShopWINTER)
end
_G.EnableAuraShop = function()
    spawnGui(GUI_NAMES.AuraShop)
end
_G.DisableAuraShop = function()
    destroyGui(GUI_NAMES.AuraShop)
end
_G.EnableIndex = function()
    spawnGui(GUI_NAMES.Index)
end
_G.DisableIndex = function()
    destroyGui(GUI_NAMES.Index)
end
