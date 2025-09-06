local QBCore = exports['qb-core']:GetCoreObject()
local Market = {
    location = nil,
    stock = {},
    isOpen = false
}
local blip = nil

-- request market info on player load
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('qb-blackmarket:server:getMarket', function(data)
        Market = data
    end)
end)

-- update from server
RegisterNetEvent('qb-blackmarket:client:updateMarket', function(data)
    Market = data
    QBCore.Functions.Notify("Black Market moved", "info")
end)

RegisterNetEvent('qb-blackmarket:client:updateStock', function(stock)
    Market.stock = stock
end)

RegisterNetEvent('qb-blackmarket:client:notifyAll', function(msg)
    QBCore.Functions.Notify(msg, 'primary')
end)

-- show alert to cops
RegisterNetEvent('qb-blackmarket:client:showAlert', function(message, zone)
    -- simple notification + create blip at location for a short period
    QBCore.Functions.Notify(message, 'alert')
    if zone then
        local blip = AddBlipForCoord(zone.x, zone.y, zone.z)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Suspicious Activity")
        EndTextCommandSetBlipName(blip)
        Citizen.SetTimeout(120000, function() RemoveBlip(blip) end) -- 2 minutes
    end
end)

-- draw marker and interaction
CreateThread(function()
    while true do
        Wait(1000)
        if Market and Market.location and Market.isOpen then
            local playerPed = PlayerPedId()
            local pos = GetEntityCoords(playerPed)
            local dist = #(pos - vector3(Market.location.x, Market.location.y, Market.location.z))
            if dist < 100.0 then
                DrawMarker(2, Market.location.x, Market.location.y, Market.location.z + 0.2, 0.0,0.0,0.0,0.0,0.0,0.0, 1.0,1.0,0.4, 255,0,0, 100, false, true, 2, nil, nil, false)
            end
            if dist < 2.0 then
                QBCore.Functions.DrawText3D(Market.location.x, Market.location.y, Market.location.z + 0.5, "[E] Access Black Market")
                if IsControlJustReleased(0, 38) then -- E
                    -- check access requirement
                    local pass = Config.AccessItem
                    local hasPass = true
                    if pass then
                        local Player = QBCore.Functions.GetPlayerData()
                        hasPass = false
                        local item = QBCore.Functions.GetPlayerData().items
                        for _,v in pairs(QBCore.Functions.GetPlayerData().items) do
                            if v.name == pass and v.amount > 0 then hasPass = true break end
                        end
                    end

                    if not hasPass then
                        QBCore.Functions.Notify("You need a pass to access", "error")
                    else
                        -- open menu
                        openMarketMenu()
                    end
                end
            end
        end
    end
end)

function openMarketMenu()
    local elements = {}
    for i,v in ipairs(Market.stock) do
        table.insert(elements, {
            label = v.label .. " - $" .. tostring(v.price) .. " (" .. tostring(v.amount) .. ")",
            value = i
        })
    end

    QBCore.UI.Menu.Open('default', GetCurrentResourceName(), 'blackmarket_menu', {
        title = 'Black Market',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local selected = Market.stock[data.current.value]
        if selected then
            -- confirm?
            QBCore.UI.Menu.Open('default', GetCurrentResourceName(), 'blackmarket_confirm', {
                title = 'Buy ' .. selected.label .. ' for $' .. selected.price .. '?',
                align = 'top-left',
                elements = {
                    {label = 'Confirm', value = 'yes'},
                    {label = 'Cancel', value = 'no'}
                }
            }, function(d2, m2)
                if d2.current.value == 'yes' then
                    TriggerServerEvent('qb-blackmarket:server:buyItem', data.current.value)
                    m2.close()
                    menu.close()
                else
                    m2.close()
                end
            end, function(_,_) end)
        end
    end, function(_,_) end)
end
