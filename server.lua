local jailedPlayers = {}  -- In-memory cache for online players' jail data

-- Load jailed data from DB on resource start
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local results = MySQL.query.await('SELECT * FROM admin_jail')
    for _, v in ipairs(results) do
        jailedPlayers[v.citizenid] = {time = v.time, reason = v.reason}
    end
end)

-- Function to check if source has permission (using ACE)
local function hasPermission(source)
    for _, group in ipairs(Config.AllowedGroups) do
        if IsPlayerAceAllowed(source, 'group.' .. group) then return true end
    end
    return false
end

-- Webhook function
local function sendWebhook(message)
    if Config.Webhook == '' then return end
    local embed = {
        {
            color = 16711680,
            title = 'Admin Jail Log',
            description = message,
            footer = {text = os.date('%Y-%m-%d %H:%M:%S')}
        }
    }
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({embeds = embed}), {['Content-Type'] = 'application/json'})
end

-- Jail function
local function jailPlayer(targetId, time, reason, adminSource)
    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then return end
    local citizenid = targetPlayer.PlayerData.citizenid
    jailedPlayers[citizenid] = {time = time, reason = reason}
    MySQL.upsert('INSERT INTO admin_jail (citizenid, time, reason) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE time = ?, reason = ?', {citizenid, time, reason, time, reason})
    TriggerClientEvent('adminjail:jail', targetPlayer.Source, Config.JailLocation, time, reason)
    local adminName = GetPlayerName(adminSource)
    local targetName = GetPlayerName(targetId)
    sendWebhook(adminName .. ' jailed ' .. targetName .. ' (CitizenID: ' .. citizenid .. ') for ' .. time .. ' minutes. Reason: ' .. reason)
end

-- Release function (supports offline via citizenid)
local function releasePlayer(targetId, citizenid, adminSource)
    citizenid = citizenid or (exports.qbx_core:GetPlayer(targetId) and exports.qbx_core:GetPlayer(targetId).PlayerData.citizenid)
    if not citizenid then return end
    jailedPlayers[citizenid] = nil
    MySQL.query('DELETE FROM admin_jail WHERE citizenid = ?', {citizenid})
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    local targetName = targetPlayer and GetPlayerName(targetPlayer.Source) or 'Offline Player (CitizenID: ' .. citizenid .. ')'
    if targetPlayer then
        TriggerClientEvent('adminjail:release', targetPlayer.Source, Config.ReleaseLocation)
    end
    local adminName = GetPlayerName(adminSource)
    sendWebhook(adminName .. ' released ' .. targetName)
end

-- Update time function (supports offline)
local function updateTime(targetId, citizenid, newTime, adminSource)
    citizenid = citizenid or (exports.qbx_core:GetPlayer(targetId) and exports.qbx_core:GetPlayer(targetId).PlayerData.citizenid)
    if not citizenid then return end
    if jailedPlayers[citizenid] then jailedPlayers[citizenid].time = newTime end
    MySQL.update('UPDATE admin_jail SET time = ? WHERE citizenid = ?', {newTime, citizenid})
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    local targetName = targetPlayer and GetPlayerName(targetPlayer.Source) or 'Offline Player (CitizenID: ' .. citizenid .. ')'
    if targetPlayer then
        TriggerClientEvent('adminjail:updateTime', targetPlayer.Source, newTime)
    end
    local adminName = GetPlayerName(adminSource)
    sendWebhook(adminName .. ' updated ' .. targetName .. ' jail time to ' .. newTime .. ' minutes')
end

-- Get full jailed list (including offline)
local function getJailedList()
    local results = MySQL.query.await('SELECT a.*, p.charinfo FROM admin_jail a LEFT JOIN players p ON a.citizenid = p.citizenid')
    local list = {}
    for _, v in ipairs(results) do
        local charinfo = json.decode(v.charinfo or '{}')
        local name = (charinfo.firstname and charinfo.firstname .. ' ' .. charinfo.lastname) or 'Unknown'
        local player = exports.qbx_core:GetPlayerByCitizenId(v.citizenid)
        local id = player and player.Source or 'Offline'
        table.insert(list, {id = id, citizenid = v.citizenid, name = name, time = v.time, reason = v.reason})
    end
    return list
end

-- Countdown thread (only decrements for online players)
CreateThread(function()
    while true do
        Wait(60000)  -- 1 minute
        for citizenid, data in pairs(jailedPlayers) do
            local player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
            if player and data.time > 0 then
                data.time = data.time - 1
                if data.time <= 0 then
                    releasePlayer(player.Source, nil, 0)  -- Auto-release, no admin
                else
                    MySQL.update('UPDATE admin_jail SET time = ? WHERE citizenid = ?', {data.time, citizenid})
                end
            end
        end
    end
end)

-- Player load: Check if jailed
RegisterNetEvent('qbx_core:playerLoaded')
AddEventHandler('qbx_core:playerLoaded', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    local citizenid = player.PlayerData.citizenid
    local data = jailedPlayers[citizenid]
    if data then
        TriggerClientEvent('adminjail:jail', source, Config.JailLocation, data.time, data.reason)
    end
end)

-- Player disconnect: Save remaining time
AddEventHandler('playerDropped', function()
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local citizenid = player.PlayerData.citizenid
    local data = jailedPlayers[citizenid]
    if data then
        MySQL.update('UPDATE admin_jail SET time = ? WHERE citizenid = ?', {data.time, citizenid})
    end
end)

-- Commands (using ox_lib)
lib.addCommand(Config.Commands.jail, {
    help = 'Jail a player',
    params = {
        {name = 'id', help = 'Player ID'},
        {name = 'time', help = 'Time (minutes)'},
        {name = 'reason', help = 'Reason'}
    }
}, function(source, args)
    if not hasPermission(source) then return end
    local id = tonumber(args.id)
    local time = tonumber(args.time)
    local reason = args.reason
    if not id or not time or time <= 0 or not reason then return end
    jailPlayer(id, time, reason, source)
end)

lib.addCommand(Config.Commands.release, {
    help = 'Release a player',
    params = {
        {name = 'id', help = 'Player ID'}
    }
}, function(source, args)
    if not hasPermission(source) then return end
    local id = tonumber(args.id)
    if not id then return end
    releasePlayer(id, nil, source)
end)

lib.addCommand(Config.Commands.time, {
    help = 'Check your jail time'
}, function(source)
    local player = exports.qbx_core:GetPlayer(source)
    local data = jailedPlayers[player.PlayerData.citizenid]
    if not data then
        exports.qbx_core:Notify(source, Config.Language.notjailed, 'error')
        return
    end
    exports.qbx_core:Notify(source, string.format(Config.Language.timeleft, data.time), 'primary')
end)

lib.addCommand(Config.Commands.list, {
    help = 'List all jailed players'
}, function(source)
    if not hasPermission(source) then return end
    local list = getJailedList()
    if #list == 0 then
        exports.qbx_core:Notify(source, Config.Language.noonejailed, 'error')
        return
    end
    exports.qbx_core:Notify(source, Config.Language.listheader, 'primary')
    for _, v in ipairs(list) do
        local msg = string.format(Config.Language.listitem, v.name, v.id, v.citizenid, v.time, v.reason)
        exports.qbx_core:Notify(source, msg, 'success')
    end
end)

lib.addCommand(Config.Commands.menu, {
    help = 'Open admin jail menu'
}, function(source)
    if not hasPermission(source) then return end
    TriggerClientEvent('adminjail:openMenu', source)
end)

-- Callbacks and events
lib.callback.register('adminjail:getJailed', function(source)
    if not hasPermission(source) then return end
    return getJailedList()
end)

RegisterServerEvent('adminjail:release')
AddEventHandler('adminjail:release', function(targetId, citizenid)
    local source = source
    if not hasPermission(source) then return end
    releasePlayer(targetId, citizenid, source)
end)

RegisterServerEvent('adminjail:updateTime')
AddEventHandler('adminjail:updateTime', function(targetId, citizenid, newTime)
    local source = source
    if not hasPermission(source) then return end
    if newTime <= 0 then return end
    updateTime(targetId, citizenid, newTime, source)
end)
