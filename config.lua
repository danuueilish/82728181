if _G.AlohomoraConfigModuleLoaded then return end
_G.AlohomoraConfigModuleLoaded = true

local WindUI = _G.WindUI
local Window = _G.MainWindow
if not (WindUI and Window) then
    warn("[Config] _G.WindUI atau _G.MainWindow belum di-set")
    return
end

local ConfigManager = Window.ConfigManager
if not ConfigManager then
    warn("[Config] Config Manager not found")
    return
end

local HttpService = game:GetService("HttpService")

local currentConfigName
local selectedConfigName
local configNameInput = ""

local autoLoadConfigFile = "BluuHub.txt"

local savedConfigsDropdown

local function safeRead(path)
    if isfile and isfile(path) then
        local ok, content = pcall(readfile, path)
        if ok then
            return content
        end
    end
    return nil
end

local function safeWrite(path, content)
    if writefile then
        pcall(function()
            writefile(path, content or "")
        end)
    end
end

local function getAllConfigs()
    local list = {}
    local ok, data = pcall(function()
        return ConfigManager:AllConfigs()
    end)

    if ok and type(data) == "table" then
        for _, v in ipairs(data) do
            if type(v) == "string" then
                table.insert(list, v)
            elseif type(v) == "table" and v.Name then
                table.insert(list, v.Name)
            end
        end
    end

    table.sort(list)
    return list
end

local function setCurrentConfig(name)
    if not name or name == "" then
        currentConfigName = nil
        return nil
    end
    currentConfigName = name
    return ConfigManager:CreateConfig(name)
end

local function getAutoLoadName()
    local data = safeRead(autoLoadConfigFile)
    if data and data ~= "" then
        return data
    end
    return nil
end

local function setAutoLoadName(name)
    safeWrite(autoLoadConfigFile, name or "")
end

local function autoLoadConfig(dropdown)
    local name = getAutoLoadName()
    if not name or name == "" then
        return
    end

    local cfg = setCurrentConfig(name)
    if not cfg then
        return
    end

    local ok, err = pcall(function()
        cfg:Load()
    end)

    if not ok then
        warn("[Config] failed auto load:", err)
        return
    end

    if dropdown and dropdown.Refresh then
        local list = getAllConfigs()
        dropdown:Refresh(list)
        if dropdown.Select and table.find(list, name) then
            dropdown:Select(name)
        end
    end

    WindUI:Notify({
        Title = "Config",
        Content = "Auto loaded config: " .. name,
        Duration = 3
    })
end

local SettingsTab = _G.SettingsTab or Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

local ConfigSection = SettingsTab:Section({
    Title = "Configuration",
    Opened = true,
    Box = true
})

ConfigSection:Input({
    Title = "Config Name",
    Placeholder = "Enter Config Name",
    Type = "Input",
    Callback = function(text)
        configNameInput = text
    end
})

ConfigSection:Button({
    Title = "Save Config",
    Callback = function()
        local name = (configNameInput or ""):gsub("^%s+",""):gsub("%s+$","")
        if name == "" then
            WindUI:Notify({
                Title = "Config",
                Content = "Enter config name first.",
                Duration = 2
            })
            return
        end

        local cfg = setCurrentConfig(name)
        if not cfg then
            WindUI:Notify({
                Title = "Config",
                Content = "Failed create new config.",
                Duration = 2
            })
            return
        end

        local ok, err = pcall(function()
            cfg:Save()
        end)

        if ok then
            WindUI:Notify({
                Title = "Config",
                Content = "Saved: " .. name,
                Duration = 2
            })

            selectedConfigName = name

            if savedConfigsDropdown and savedConfigsDropdown.Refresh then
                local list = getAllConfigs()
                savedConfigsDropdown:Refresh(list)
                if savedConfigsDropdown.Select and table.find(list, name) then
                    savedConfigsDropdown:Select(name)
                end
            end
        else
            WindUI:Notify({
                Title = "Config",
                Content = "Error save: " .. tostring(err),
                Duration = 3
            })
        end
    end
})

savedConfigsDropdown = ConfigSection:Dropdown({
    Title = "Saved Config",
    Values = getAllConfigs(),
    Multi = false,
    AllowNone = true,
    Callback = function(option)
        if type(option) == "table" and option.Title then
            selectedConfigName = option.Title
        else
            selectedConfigName = option
        end
    end
})

ConfigSection:Button({
    Title = "Load Config",
    Callback = function()
        local name = selectedConfigName
            or ((configNameInput or ""):gsub("^%s+",""):gsub("%s+$",""))

        if not name or name == "" then
            WindUI:Notify({
                Title = "Config",
                Content = "Choose or fill your config name first.",
                Duration = 2
            })
            return
        end

        local cfg = setCurrentConfig(name)
        if not cfg then
            WindUI:Notify({
                Title = "Config",
                Content = "Failed Load config.",
                Duration = 2
            })
            return
        end

        local ok, err = pcall(function()
            cfg:Load()
        end)

        if ok then
            WindUI:Notify({
                Title = "Config",
                Content = "Loaded: " .. name,
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Config",
                Content = "Error load: " .. tostring(err),
                Duration = 3
            })
        end
    end
})

ConfigSection:Button({
    Title = "Refresh Config List",
    Callback = function()
        if savedConfigsDropdown and savedConfigsDropdown.Refresh then
            savedConfigsDropdown:Refresh(getAllConfigs())
        end
        WindUI:Notify({
            Title = "Config",
            Content = "Refreshing List.",
            Duration = 2
        })
    end
})

ConfigSection:Button({
    Title = "Set as Auto Load",
    Callback = function()
        local name = selectedConfigName
            or ((configNameInput or ""):gsub("^%s+",""):gsub("%s+$",""))

        if not name or name == "" then
            WindUI:Notify({
                Title = "Config",
                Content = "Choose config first.",
                Duration = 1
            })
            return
        end

        setAutoLoadName(name)

        WindUI:Notify({
            Title = "Config",
            Content = "Auto Load set to: " .. name,
            Duration = 1
        })
    end
})

ConfigSection:Button({
    Title = "Reset Auto Load",
    Callback = function()
        setAutoLoadName("")
        WindUI:Notify({
            Title = "Config",
            Content = "Auto Load have been reset.",
            Duration = 1
        })
    end
})

task.spawn(function()
    autoLoadConfig(savedConfigsDropdown)
end)

WindUI:Notify({
    Title = "Config",
    Content = "Config Loaded!",
    Icon = "check",
    Duration = 1
})
