if _G.ShopUiControllerLoaded then return end
_G.ShopUiControllerLoaded = true

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local SHOP_UI_NAMES = {
    RodShop  = "RodShop",
    AuraShop = "AuraShop",
    Index    = "Index",
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

local function isGuiVisible(guiName)
    local data = State[guiName]
    local inst = data and data.instance or PlayerGui:FindFirstChild(guiName)
    if not inst then return false end
    if not (inst:IsA("ScreenGui") or inst:IsA("BillboardGui")) then return false end
    return inst.Enabled == true
end

_G.EnableRodShop = function()
    showGui(SHOP_UI_NAMES.RodShop)
end
_G.DisableRodShop = function()
    hideGui(SHOP_UI_NAMES.RodShop)
end
_G.ToggleRodShopUI = function()
    if isGuiVisible(SHOP_UI_NAMES.RodShop) then
        hideGui(SHOP_UI_NAMES.RodShop)
    else
        showGui(SHOP_UI_NAMES.RodShop)
    end
end
_G.EnableAuraShop = function()
    showGui(SHOP_UI_NAMES.AuraShop)
end
_G.DisableAuraShop = function()
    hideGui(SHOP_UI_NAMES.AuraShop)
end
_G.ToggleAuraShopUI = function()
    if isGuiVisible(SHOP_UI_NAMES.AuraShop) then
        hideGui(SHOP_UI_NAMES.AuraShop)
    else
        showGui(SHOP_UI_NAMES.AuraShop)
    end
end
_G.EnableIndex = function()
    showGui(SHOP_UI_NAMES.Index)
end
_G.DisableIndex = function()
    hideGui(SHOP_UI_NAMES.Index)
end
_G.ShowIndexUI = function()
    showGui(SHOP_UI_NAMES.Index)
end

local rfFolder = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteFunction")
local RF_RodShop = rfFolder:WaitForChild("RodShop")
local RF_AuraShop = rfFolder:WaitForChild("AuraShop")

local rods = {
    {Name = "Party Rod",   Price = 250000},
    {Name = "Shark Rod",   Price = 400000},
    {Name = "Piranha Rod", Price = 700000},
    {Name = "Thermo Rod",  Price = 1400000},
    {Name = "Flowers Rod", Price = 2500000},
    {Name = "Trisula Rod", Price = 4000000},
    {Name = "Feather Rod", Price = 6000000},
    {Name = "Wave Rod",    Price = 9000000},
    {Name = "Duck Rod",    Price = 12000000},
    {Name = "Planet Rod",  Price = 15000000},
    {Name = "Earth Rod",   Price = 25000000},
}

_G.ShopRodList = {}
for _, r in ipairs(rods) do
    table.insert(_G.ShopRodList, r.Name)
end

_G.ShopAuraList = {
    "Blackred Love",
    "Green Glitch",
    "Pink Love",
    "Autumn",
    "Sakura",
    "Starlight",
    "Blueada",
    "Purple Wings",
}

_G.SelectedRodToBuy = _G.SelectedRodToBuy or nil
_G.SelectedAuraToBuy = _G.SelectedAuraToBuy or nil
_G.SetRodToBuy = function(name)
    _G.SelectedRodToBuy = name
end
_G.SetAuraToBuy = function(name)
    _G.SelectedAuraToBuy = name
end

_G.BuyRod = function()
    local name = _G.SelectedRodToBuy
    if not name or name == "" then
        return false, "Select a rod first"
    end

    local ok, res = pcall(function()
        return RF_RodShop:InvokeServer("Buy", name)
    end)

    if not ok then
        return false, "Unknown error"
    end

    if res == false then
        return false, "Purchase failed"
    end

    return true, "Purchase success"
end

_G.BuyAura = function()
    local name = _G.SelectedAuraToBuy
    if not name or name == "" then
        return false, "Select an aura first"
    end

    local ok, res = pcall(function()
        return RF_AuraShop:InvokeServer("Buy", name)
    end)

    if not ok then
        return false, "Unknown error"
    end

    if res == false then
        return false, "Purchase failed"
    end

    return true, "Purchase success"
end
