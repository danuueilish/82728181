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

local function fsAvailable()
    return (isfile and readfile and writefile and listfiles and (makefolder or isfolder))
end

local function getFolder()
    local folderName = "BluuHub"
    local w = getWindow()
    if w and w.Folder then
        folderName = tostring(w.Folder)
    end
    return folderName
end

local function getConfigDir()
    return ("WindUI/%s/Configs"):format(getFolder())
end

local function getAutoPath()
    return ("WindUI/%s/autoload.txt"):format(getFolder())
end

local function ensureFolder()
    if not fsAvailable() then return end
    pcall(function()
        if makefolder then
            if not isfolder or not isfolder("WindUI") then
                makefolder("WindUI")
            end
            local mid = ("WindUI/%s"):format(getFolder())
            if not isfolder or not isfolder(mid) then
                makefolder(mid)
            end
            local cfgDir = getConfigDir()
            if not isfolder or not isfolder(cfgDir) then
                makefolder(cfgDir)
            end
        end
    end)
end

function core.NormalizeName(name)
    name = tostring(name or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%.json$", "")
    return name
end

local function writeAutoName(name)
    if not fsAvailable() then return end
    ensureFolder()
    pcall(function()
        writefile(getAutoPath(), tostring(name or ""))
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
    local names = {}
    if fsAvailable() then
        ensureFolder()
        local cfgDir = getConfigDir()
        local ok, files = pcall(listfiles, cfgDir)
        if ok and type(files) == "table" then
            for _, path in ipairs(files) do
                if tostring(path):match("%.json$") then
                    local filename = path:match("([^/\\]+)$") or path
                    local normalized = core.NormalizeName(filename)
                    if normalized ~= "" then
                        table.insert(names, normalized)
                    end
                end
            end
        end
    end
    if #names == 0 then
        local manager = getConfigManager()
        if manager then
            local ok, list = pcall(function()
                return manager:AllConfigs()
            end)
            if ok and type(list) == "table" then
                local function tryAdd(v, k)
                    if type(v) == "string" then
                        table.insert(names, core.NormalizeName(v))
                    elseif type(v) == "table" then
                        local n = v.Name or v.name or v.Title or v.title or v.File or v.file
                        if n then table.insert(names, core.NormalizeName(n)) end
                    elseif type(k) == "string" then
                        table.insert(names, core.NormalizeName(k))
                    end
                end
                if #list > 0 then
                    for _, v in ipairs(list) do tryAdd(v) end
                else
                    for k, v in pairs(list) do tryAdd(v, k) end
                end
            end
        end
    end

    local seen = {}
    local unique = {}
    for _, n in ipairs(names) do
        if not seen[n] then
            seen[n] = true
            table.insert(unique, n)
        end
    end

    table.sort(unique, function(a, b)
        return a:lower() < b:lower()
    end)
    return unique
end

function core.Save(name)
    name = core.NormalizeName(name)
    if name == "" then return false, "EMPTY_NAME" end

    local manager = getConfigManager()
    if not manager then return false, "NO_CONFIG_MANAGER" end

    local config = manager:CreateConfig(name)
    local ok, err = pcall(function() config:Save() end)
    if not ok then return false, err end
    return true
end

function core.Load(name)
    name = core.NormalizeName(name)
    if name == "" then return false, "EMPTY_NAME" end

    local manager = getConfigManager()
    if not manager then return false, "NO_CONFIG_MANAGER" end

    local config = manager:CreateConfig(name)
    local ok, err = pcall(function() config:Load() end)
    if not ok then return false, err end
    return true
end

function core.Delete(name)
    name = core.NormalizeName(name)
    if name == "" then return false, "EMPTY_NAME" end

    local manager = getConfigManager()
    if not manager then return false, "NO_CONFIG_MANAGER" end

    local config = manager:CreateConfig(name)
    local ok, err = pcall(function() config:Delete() end)
    if not ok then return false, err end
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
    return core.Load(name)
end
_G.BluuConfigCore = core
return core
