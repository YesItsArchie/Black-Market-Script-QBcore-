-- rotates market every Config.RotateInterval seconds
local function rotationLoop()
    while true do
        Wait(Config.RotateInterval * 1000)
        TriggerEvent('qb-blackmarket:server:rotateMarket')
    end
end

CreateThread(function()
    rotationLoop()
end)
