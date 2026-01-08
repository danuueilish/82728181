if _G.SkipLoadingLoaded then return end
_G.SkipLoadingLoaded = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local GameRemotes = ReplicatedStorage:WaitForChild("Remotes")
local GameLoadedRemote = GameRemotes:WaitForChild("Game"):WaitForChild("Loaded")

_G.SKIP_LOADING = _G.SKIP_LOADING or false

local function forceAnimReady()
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetAttribute("AnimCacheReady", true)
    end
end

local function isLoadingGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end

    local frame = gui:FindFirstChild("Frame")
    if not frame or not frame:IsA("Frame") then return false end

    local skipButton = frame:FindFirstChild("Skip")
    local textLabel  = frame:FindFirstChild("TextLabel")
    local viewport   = frame:FindFirstChild("ViewportFrame")

    if skipButton and textLabel and viewport then
        return true
    end

    return false
end

local function skipOneLoadingGui(gui)
    if not gui then return end

    pcall(function()
        GameLoadedRemote:FireServer()
    end)

    gui:Destroy()
end

local function scanAndSkipAll()
    if not _G.SKIP_LOADING then return end
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if isLoadingGui(gui) then
            skipOneLoadingGui(gui)
        end
    end
end

if not _G.SkipLoading_CharConn then
    _G.SkipLoading_CharConn = LP.CharacterAdded:Connect(function()
        if _G.SKIP_LOADING then
            task.delay(0.1, forceAnimReady)
        end
    end)
end

if not _G.SkipLoading_GuiConn then
    _G.SkipLoading_GuiConn = PlayerGui.ChildAdded:Connect(function(child)
        if not _G.SKIP_LOADING then return end
        task.defer(function()
            if isLoadingGui(child) then
                skipOneLoadingGui(child)
            end
        end)
    end)
end

_G.EnableSkipLoading = function()
    _G.SKIP_LOADING = true
    task.spawn(function()
        forceAnimReady()
        scanAndSkipAll()
    end)
end

_G.DisableSkipLoading = function()
    _G.SKIP_LOADING = false
end
