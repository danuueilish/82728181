if _G.ShopUiControllerLoaded then return end
_G.ShopUiControllerLoaded = true
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local SHOP_UI_NAMES = {
    RodShop = "RodShop",
    RodShopWINTER = "RodShopWINTER",
    AuraShop = "AuraShop",
    Index = "Index"
}
local State = {}
local function findTemplate(guiName)
    local template = StarterGui:FindFirstChild(guiName)
    if template then return template end
    local existing = PlayerGui:FindFirstChild(guiName)
    return existing
end
local function showGui(guiName)
    State[guiName] = State[guiName] or {}
    local data = State[guiName]
    local inst = data.instance
    if not inst or inst.Parent ~= PlayerGui then
        inst = PlayerGui:FindFirstChild(guiName)
    end
    if inst then
        if inst:IsA("ScreenGui") or inst:IsA("BillboardGui") then
            inst.Enabled = true
        end
        data.instance = inst
        return inst
    end
    local template = data.template or findTemplate(guiName)
    data.template = template
    if not template then return nil end
    local clone = template:Clone()
    clone.ResetOnSpawn = false
    clone.Parent = PlayerGui
    if clone:IsA("ScreenGui") or clone:IsA("BillboardGui") then
        clone.Enabled = true
    end
    data.instance = clone
    return clone
end
local function hideGui(guiName)
    local data = State[guiName]
    local inst = data and data.instance or PlayerGui:FindFirstChild(guiName)
    if inst and (inst:IsA("ScreenGui") or inst:IsA("BillboardGui")) then
        inst.Enabled = false
    end
end
_G.EnableRodShop = function()
    showGui(SHOP_UI_NAMES.RodShop)
end
_G.DisableRodShop = function()
    hideGui(SHOP_UI_NAMES.RodShop)
end
_G.EnableRodShopWINTER = function()
    showGui(SHOP_UI_NAMES.RodShopWINTER)
end
_G.DisableRodShopWINTER = function()
    hideGui(SHOP_UI_NAMES.RodShopWINTER)
end
_G.EnableAuraShop = function()
    showGui(SHOP_UI_NAMES.AuraShop)
end
_G.DisableAuraShop = function()
    hideGui(SHOP_UI_NAMES.AuraShop)
end
_G.EnableIndex = function()
    showGui(SHOP_UI_NAMES.Index)
end
_G.DisableIndex = function()
    hideGui(SHOP_UI_NAMES.Index)
end
