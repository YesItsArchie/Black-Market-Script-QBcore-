local QBCore = exports['qb-core']:GetCoreObject()

local Market = {
    location = nil, -- vector4
    stock = {},
    sellsSinceLastAlert = 0,
    isOpen = false
}

-- utility
local function pickRandomLocation()
    return Config.PossibleLocations[math.random(1, #Config.PossibleLocations)]
end

local function deepCopy(tbl)
    local t = {}
    for k,v in pairs(tbl) do
        if type(v) == 'table' then t[k] = deepCopy(v) else t[k] = v end
    end
    return t
end

-- Initialize
local function initMarket()
    Market.location = pickRandomLocation()
    Market.stock = deepCopy(Config.InitialStock)
    Market.sellsSinceLastAlert = 0
    Market.isOpen = true
    print("^5[qb-blackmarket]^7 Market opened at: " .. tostring(Market.location))
end

initMarket()

-- rotate endpoint (used by stock_rotation.lua)
RegisterNetEvent('qb-blackmarket:server:rotateMarket', function()
    Market.location = pickRandomLocation()
    Market.stock = deepCopy(Config.InitialStock)
    Market.sellsSinceLastAlert = 0
    Market.isOpen = true
    TriggerClientEvent('qb-blackmarket:client:updateMarket', -1, Market)
    print("^5[qb-blackmarket]^7 Market rotated to new location.")
end)

-- get market info
QBCore.Functions.CreateCallback('qb-blackmarket:server:getMarket', function(source, cb)
    cb({
        location = Market.location,
        stock = Market.stock,
        isOpen = Market.isOpen
    })
end)

-- attempt purchase
RegisterNetEvent('qb-blackmarket:server:buyItem', function(itemIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local entry = Market.stock[itemIndex]
    if not entry or entry.amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Item not available', 'error')
        return
    end

    local price = entry.price
    if Player.Functions.GetMoney('cash') >= price then
        Player.Functions.RemoveMoney('cash', price, 'blackmarket-buy')
        -- add item or give weapon
        if entry.type == 'weapon' then
            Player.Functions.AddItem('weaponlicense', 0) -- no-op (optional license logic)
            Player.Functions.AddItem(entry.name, 1) -- many servers put weapons as items
            -- If you use GiveWeapon, you can add that logic here with client event
        else
            Player.Functions.AddItem(entry.name, 1)
        end

        entry.amount = entry.amount - 1
        TriggerClientEvent('QBCore:Notify', src, 'Purchase successful', 'success')
        TriggerClientEvent('qb-blackmarket:client:updateStock', -1, Market.stock)

        Market.sellsSinceLastAlert = Market.sellsSinceLastAlert + 1
        if Config.AlertCops and Market.sellsSinceLastAlert >= Config.SellThresholdBeforeAlert then
            -- send alert to cops
            Market.sellsSinceLastAlert = 0
            local zone = Market.location
            local msg = string.format(Config.AlertMessage, 'unknown')
            TriggerEvent('qb-blackmarket:server:alertCops', zone, msg)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Not enough cash', 'error')
    end
end)

-- sell dirty items to market
RegisterNetEvent('qb-blackmarket:server:sellItem', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    amount = amount or 1

    if Player.Functions.GetItemByName(itemName) then
        local sellPrice = 0
        -- simple price mapping (you can expand)
        for _,v in pairs(Market.stock) do
            if v.name == itemName then
                sellPrice = math.floor(v.price * 0.5) -- buyback 50%
            end
        end
        if sellPrice <= 0 then
            TriggerClientEvent('QBCore:Notify', src, 'This market does not buy that item', 'error')
            return
        end

        if Player.Functions.RemoveItem(itemName, amount) then
            Player.Functions.AddMoney('cash', sellPrice * amount, 'blackmarket-sell')
            TriggerClientEvent('QBCore:Notify', src, 'Sold items for $' .. tostring(sellPrice * amount), 'success')
            Market.sellsSinceLastAlert = Market.sellsSinceLastAlert + amount
            if Config.AlertCops and Market.sellsSinceLastAlert >= Config.SellThresholdBeforeAlert then
                Market.sellsSinceLastAlert = 0
                TriggerEvent('qb-blackmarket:server:alertCops', Market.location, Config.AlertMessage)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You do not have those items', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have that item', 'error')
    end
end)

-- alert cops
RegisterNetEvent('qb-blackmarket:server:alertCops', function(zone, message)
    local alert = message or Config.AlertMessage
    -- Send to everyone with police job
    for _, player in pairs(QBCore.Functions.GetPlayers()) do
        local src = player
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData.job.name == 'police' then
            TriggerClientEvent('qb-blackmarket:client:showAlert', src, alert, zone)
            TriggerClientEvent('QBCore:Notify', src, "Intel: possible illegal market activity nearby", 'inform')
        end
    end
end)

-- admin command to open/close
QBCore.Commands.Add("blackmarket", "Open/Close Market (dev)", {{name="open", help="open/close"}}, false, function(source, args)
    local action = args[1]
    if action == "open" then
        Market.isOpen = true
        TriggerClientEvent('qb-blackmarket:client:notifyAll', -1, "Black Market is now OPEN")
    elseif action == "close" then
        Market.isOpen = false
        TriggerClientEvent('qb-blackmarket:client:notifyAll', -1, "Black Market is now CLOSED")
    elseif action == "rotate" then
        Market.location = pickRandomLocation()
        Market.stock = deepCopy(Config.InitialStock)
        TriggerClientEvent('qb-blackmarket:client:updateStock', -1, Market.stock)
        TriggerClientEvent('qb-blackmarket:client:updateMarket', -1, Market)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Usage: /blackmarket open|close|rotate', 'error')
    end
end, 'admin')
