local core = {}
local function getWindow()
    if getgenv and getgenv().BluuHubWindow then
        return getgenv().BluuHubWindow
    end
    if _G.BluuHubWindow then
        return _G.BluuHubWindow
    end
    return nil
end
local function getConfigManager()
    local window = getWindow()
    if not window then return nil end
    local ok, manager = pcall(function()
        return window.ConfigManager
    end)
    if not ok then return nil end
    return manager
end
function core.NormalizeName(name)
    name = tostring(name or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%.json$", "")
    return name
end
local function getAutoPath()
    local folderName = "BluuHub"
    local w = getWindow()
    if w and w.Folder then
        folderName = tostring(w.Folder)
    end
    return ("WindUI/%s/autoload.txt"):format(folderName)
end
local function fsAvailable()
    return (isfile and readfile and writefile and (makefolder or isfolder))
end
local function ensureFolder()
    if not fsAvailable() then return end
    local ok = pcall(function()
        if makefolder and (not isfolder or not isfolder("WindUI")) then
            makefolder("WindUI")
        end
        local path = getAutoPath()
        local dir = path:match("^(.*)/[^/]+$") or "WindUI"
        if makefolder and (not isfolder or not isfolder(dir)) then
            makefolder(dir)
        end
    end)
end
local function writeAutoName(name)
    if not fsAvailable() then return end
    ensureFolder()
    local path = getAutoPath()
    pcall(function()
        writefile(path, tostring(name or ""))
    end)
end
local function readAutoName()
    if not fsAvailable() then return "" end
    local path = getAutoPath()
    local ok, data = pcall(function()
        if isfile(path) then
            return readfile(path) or ""
        end
        return ""
    end)
    if not ok or not data then return "" end
    return core.NormalizeName(data)
end
function core.GetAllConfigs()
    local manager = getConfigManager()
    if not manager then return {} end
    local ok, list = pcall(function()
        return manager:AllConfigs()
    end)
    if not ok or not list then
        return {}
    end
    local names = {}
    if #list > 0 then
        for _, v in ipairs(list) do
            if type(v) == "string" then
                table.insert(names, core.NormalizeName(v))
            elseif type(v) == "table" then
                local n = v.Name or v.name or v.Title or v.title or v.File or v.file
                if n then
                    table.insert(names, core.NormalizeName(n))
                end
            end
        end
    else
        for k, v in pairs(list) do
            if type(v) == "string" then
                table.insert(names, core.NormalizeName(v))
            elseif type(v) == "table" then
                local n = v.Name or v.name or v.Title or v.title or v.File or v.file or k
                if n then
                    table.insert(names, core.NormalizeName(n))
                end
            elseif type(k) == "string" then
                table.insert(names, core.NormalizeName(k))
            end
        end
    end
    table.sort(names, function(a, b)
        return a:lower() < b:lower()
    end)
    return names
end
function core.Save(name)
    name = core.NormalizeName(name)
    if name == "" then
        return false, "EMPTY_NAME"
    end
    local manager = getConfigManager()
    if not manager then
        return false, "NO_CONFIG_MANAGER"
    end
    local config = manager:CreateConfig(name)
    local ok, err = pcall(function()
        config:Save()
    end)
    if not ok then
        return false, err
    end
    return true
end
function core.Load(name)
    name = core.NormalizeName(name)
    if name == "" then
        return false, "EMPTY_NAME"
    end
    local manager = getConfigManager()
    if not manager then
        return false, "NO_CONFIG_MANAGER"
    end
    local config = manager:CreateConfig(name)
    local ok, err = pcall(function()
        config:Load()
    end)
    if not ok then
        return false, err
    end
    return true
end
function core.Delete(name)
    name = core.NormalizeName(name)
    if name == "" then
        return false, "EMPTY_NAME"
    end
    local manager = getConfigManager()
    if not manager then
        return false, "NO_CONFIG_MANAGER"
    end
    local config = manager:CreateConfig(name)
    local ok, err = pcall(function()
        config:Delete()
    end)
    if not ok then
        return false, err
    end
    return true
end
function core.SetAutoLoad(name)
    name = core.NormalizeName(name)
    if name == "" then
        writeAutoName("")
        return false, "EMPTY_NAME"
    end
    writeAutoName(name)
    return true
end
function core.ResetAutoLoad()
    writeAutoName("")
    return true
end
function core.GetAutoLoad()
    return readAutoName()
end
function core.AutoLoadOnStart()
    local name = core.GetAutoLoad()
    if name == "" then return false end
    local ok, err = core.Load(name)
    return ok, err
end
_G.BluuConfigCore = core
return core
