local ConfigCore = _G.BluuConfigCore
if not ConfigCore then
    warn("[BluuHub] Config not found")
    return
end
local Window = (getgenv and getgenv().BluuHubWindow) or _G.BluuHubWindow
local SettingsTab = (getgenv and getgenv().BluuHubSettingsTab) or _G.BluuHubSettingsTab
local WindUI = (getgenv and getgenv().BluuHubWindUI) or _G.BluuHubWindUI
if not (Window and SettingsTab) then
    warn("[BluuHub] Window or SettingsTab not set")
    return
end
local function notify(title, msg, dur)
    if WindUI and WindUI.Notify then
        WindUI:Notify({
            Title = title or "Config",
            Content = msg or "",
            Duration = dur or 1
        })
    else
        print("[Config]", title or "", msg or "")
    end
end
local ConfigSection = SettingsTab:Section({
    Title  = "Configuration",
    Opened = true,
})
local currentName = ""
local selectedName = ""
local configDropdown
local autoInfoParagraph
local function refreshConfigs()
    if not configDropdown or not configDropdown.Refresh then return end
    local list = {}
    local ok, result = pcall(function()
        return ConfigCore.GetAllConfigs()
    end)
    if ok and type(result) == "table" and #result > 0 then
        list = result
    else
        list = {"<no configs>"}
    end
    configDropdown:Refresh(list)
    if #list > 0 and list[1] ~= "<no configs>" then
        selectedName = list[1]
    else
        selectedName = ""
    end
end
local function refreshAutoInfo()
    if not autoInfoParagraph then return end
    local name = ""
    local ok, result = pcall(function()
        return ConfigCore.GetAutoLoad()
    end)
    if ok and type(result) == "string" then
        name = result
    end
    if name ~= "" then
        autoInfoParagraph:SetDesc("Auto Load: " .. name .. "")
    else
        autoInfoParagraph:SetDesc("Auto Load: (none)")
    end
end
ConfigSection:Input({
    Title       = "Config Name",
    Placeholder = "Your Config Name",
    Callback    = function(text)
        currentName = tostring(text or "")
    end
})
configDropdown = ConfigSection:Dropdown({
    Title   = "Config List",
    Values  = {"<no configs>"},
    Multi   = false,
    Callback = function(value)
        if value == "<no configs>" then
            selectedName = ""
        else
            selectedName = tostring(value or "")
        end
    end
})
ConfigSection:Button({
    Title    = "Save",
    Justify  = "Left",
    Icon     = "lucide:save",
    IconAlign = "Right",
    Callback = function()
        local name = currentName
        if name == "" then
            name = selectedName
        end
        name = ConfigCore.NormalizeName(name)
        if not name or name == "" then
            notify("Config", "Fill config name first.", 1.5)
            return
        end
        local ok, err = ConfigCore.Save(name)
        if ok then
            notify("Config", "Saved: " .. name, 1.5)
            refreshConfigs()
        else
            notify("Config", "Saved failed: " .. tostring(err), 2)
        end
    end
})

ConfigSection:Button({
    Title    = "Delete",
    Justify  = "Left",
    Icon     = "lucide:trash-2",
    IconAlign = "Right",
    Callback = function()
        local name = selectedName
        name = ConfigCore.NormalizeName(name)
        if not name or name == "" then
            notify("Config", "Choose config first.", 1.5)
            return
        end
        local ok, err = ConfigCore.Delete(name)
        if ok then
            notify("Config", "Deleted: " .. name, 1.5)
            local autoNow = ConfigCore.GetAutoLoad()
            if autoNow == name then
                ConfigCore.ResetAutoLoad()
            end
            refreshConfigs()
            refreshAutoInfo()
        else
            notify("Config", "Delete failed: " .. tostring(err), 2)
        end
    end
})

ConfigSection:Button({
    Title    = "Set Auto Load",
    Justify  = "Left",
    Icon     = "lucide:zap",
    IconAlign = "Right",
    Callback = function()
        local name = selectedName
        name = ConfigCore.NormalizeName(name)
        if not name or name == "" then
            notify("Config", "Choose config first.", 1.5)
            return
        end
        local ok, err = ConfigCore.SetAutoLoad(name)
        if ok then
            notify("Config", "Auto Load set: " .. name, 1.5)
            refreshAutoInfo()
        else
            notify("Config", "Failed Set Auto Load: " .. tostring(err), 2)
        end
    end
})

ConfigSection:Button({
    Title    = "Reset Auto Load",
    Justify  = "Left",
    Icon     = "lucide:rotate-ccw",
    IconAlign = "Right",
    Callback = function()
        ConfigCore.ResetAutoLoad()
        notify("Config", "Auto Load reset.", 1.5)
        refreshAutoInfo()
    end
})

autoInfoParagraph = ConfigSection:Paragraph({
    Title = "Auto Load Info",
    Desc  = "Auto Load: (none)",
})
refreshConfigs()
refreshAutoInfo()
local ok, err = pcall(function()
    ConfigCore.AutoLoadOnStart()
end)
if not ok then
    warn("[BluuHub] AutoLoadOnStart error:", err)
end
