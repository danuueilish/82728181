if not _G.__IY_FREEZE_SELF_LOADED then
    _G.__IY_FREEZE_SELF_LOADED = true
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    function _G.EnableFreezeSelf()
        local players = {LP.Name}
        if players ~= nil then
            for i, v in pairs(players) do
                task.spawn(function()
                    for i, x in next, Players[v].Character:GetDescendants() do
                        if x:IsA("BasePart") and not x.Anchored then
                            x.Anchored = true
                        end
                    end
                end)
            end
        end
    end
    function _G.DisableFreezeSelf()
        local players = {LP.Name}
        if players ~= nil then
            for i, v in pairs(players) do
                task.spawn(function()
                    for i, x in next, Players[v].Character:GetDescendants() do
                        if x.Name ~= floatName and x:IsA("BasePart") and x.Anchored then
                            x.Anchored = false
                        end
                    end
                end)
            end
        end
    end
end
