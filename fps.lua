if not _G.__BLUU_PINGFPS_TAG_LOADED then
    _G.__BLUU_PINGFPS_TAG_LOADED = true
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local conn
    local statusTag
    local lastStatus
    local frameCount
    local timeAcc
    local lastUpdate
    local function destroyTag()
        if statusTag and statusTag.Destroy then
            pcall(function()
                statusTag:Destroy()
            end)
        end
        statusTag = nil
    end
    function _G.EnablePingFpsTag(window, options)
        if not window then
            return
        end
        if conn then
            conn:Disconnect()
            conn = nil
        end
        destroyTag()
        frameCount = 0
        timeAcc = 0
        lastUpdate = time()
        lastStatus = ""
        options = options or {}
        local icon = options.Icon or "activity"
        local color = options.Color or Color3.fromHex("#30ff6a")
        local radius = options.Radius or 13
        local interval = options.Interval or 1
        conn = RunService.RenderStepped:Connect(function(dt)
            frameCount += 1
            timeAcc += dt
            local now = time()
            if now - lastUpdate >= interval then
                local fps = 0
                if timeAcc > 0 then
                    fps = math.floor((frameCount / timeAcc) + 0.5)
                end
                local pingVal = 0
                local pingItem = Stats
                    and Stats.Network
                    and Stats.Network.ServerStatsItem
                    and Stats.Network.ServerStatsItem["Data Ping"]
                if pingItem then
                    local s = pingItem:GetValueString() or ""
                    local num = s:match("(%d+)")
                    pingVal = tonumber(num) or 0
                end
                local status = ("PING: %dms | FPS: %d"):format(pingVal, fps)
                if status ~= lastStatus then
                    destroyTag()
                    statusTag = window:Tag({
                        Title = status,
                        Icon = icon,
                        Color = color,
                        Radius = radius,
                    })
                    lastStatus = status
                end
                frameCount = 0
                timeAcc = 0
                lastUpdate = now
            end
        end)
    end
    function _G.DisablePingFpsTag()
        if conn then
            conn:Disconnect()
            conn = nil
        end
        destroyTag()
    end
end