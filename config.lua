Config = {}

Config.Locale = 'en'

-- Black market spawn locations (vector4 x,y,z,heading) - add or change to your map
Config.PossibleLocations = {
    vector4(-1268.7, -3015.4, -48.5, 220.0), -- example: docks/warehouse
    vector4(295.1, -2049.3, 20.0, 180.0),
    vector4(164.0, -1006.0, 29.3, 90.0),
    vector4(-303.4, 6200.1, 31.5, 45.0)
}

-- How often (in seconds) the market will rotate location/stock. Default 2 hours = 7200s
Config.RotateInterval = 7200

-- Item required to access market (can be nil for no item requirement)
Config.AccessItem = 'blackmarket_pass'

-- Max items allowed sold/bought before police intel alert triggers
Config.SellThresholdBeforeAlert = 10

-- Police alert settings
Config.AlertCops = true
Config.AlertMessage = "Suspicious Black Market activity reported near %s."

-- Black market stock: list of item definitions
-- server stock entries: {name = 'weapon_pistol', label = 'Pistol', price = 12000, type='weapon'|'item', amount=5}
Config.InitialStock = {
    {name = 'weapon_pistol', label = 'Pistol (Suppressed)', price = 15000, type = 'weapon', amount = 2},
    {name = 'weapon_smg', label = 'Compact SMG', price = 45000, type = 'weapon', amount = 1},
    {name = 'cocaine_brick', label = 'Cocaine Brick', price = 8000, type = 'item', amount = 5},
    {name = 'meth_brick', label = 'Meth Brick', price = 7000, type = 'item', amount = 5},
    {name = 'armor_vest', label = 'Kevlar Vest', price = 12000, type = 'item', amount = 3},
    {name = 'encrypted_usb', label = 'Encrypted USB', price = 5000, type = 'item', amount = 3}
}
