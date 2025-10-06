local isJailed = false

-- Jail event
RegisterNetEvent('adminjail:jail')
AddEventHandler('adminjail:jail', function(location, time, reason)
    local ped = PlayerPedId()
    SetEntityCoords(ped, location.xyz)
    SetEntityHeading(ped, location.w)
    isJailed = true
    exports.qbx_core:Notify(string.format(Config.Language.jailed, time, reason), 'error')
    if Config.UseBuckets then
        SetPlayerRoutingBucket(GetPlayerServerId(PlayerId()), Config.BucketId)
    end
    CreateThread(function()
        while isJailed do
            for _, control in ipairs(Config.DisableControls) do
                DisableControlAction(0, control, true)
            end
            Wait(0)
        end
    end)
end)

-- Release event
RegisterNetEvent('adminjail:release')
AddEventHandler('adminjail:release', function(location)
    local ped = PlayerPedId()
    SetEntityCoords(ped, location.xyz)
    SetEntityHeading(ped, location.w)
    isJailed = false
    exports.qbx_core:Notify(Config.Language.released, 'success')
    if Config.UseBuckets then
        SetPlayerRoutingBucket(GetPlayerServerId(PlayerId()), 0)
    end
end)

-- Update time event
RegisterNetEvent('adminjail:updateTime')
AddEventHandler('adminjail:updateTime', function(newTime)
    -- Can add notify if needed
end)

-- Open menu event
RegisterNetEvent('adminjail:openMenu')
AddEventHandler('adminjail:openMenu', function()
    local jailed = lib.callback.await('adminjail:getJailed')
    if not jailed then return end
    local options = {}
    for _, v in ipairs(jailed) do
        table.insert(options, {
            title = v.name .. ' (ID: ' .. v.id .. ', CitizenID: ' .. v.citizenid .. ')',
            description = 'Time: ' .. v.time .. ' | Reason: ' .. v.reason,
            onSelect = function()
                lib.registerContext({
                    id = 'adminjail_action',
                    title = v.name,
                    options = {
                        {
                            title = 'Release',
                            onSelect = function()
                                TriggerServerEvent('adminjail:release', v.id == 'Offline' and nil or v.id, v.citizenid)
                            end
                        },
                        {
                            title = 'Update Time',
                            onSelect = function()
                                local input = lib.inputDialog('Update Jail Time', {
                                    {type = 'number', label = 'New Time (minutes)', required = true, min = 1}
                                })
                                if input and input[1] then
                                    TriggerServerEvent('adminjail:updateTime', v.id == 'Offline' and nil or v.id, v.citizenid, input[1])
                                end
                            end
                        }
                    }
                })
                lib.showContext('adminjail_action')
            end
        })
    end
    lib.registerContext({
        id = 'adminjail_menu',
        title = 'Admin Jail Menu',
        options = options
    })
    lib.showContext('adminjail_menu')
end)