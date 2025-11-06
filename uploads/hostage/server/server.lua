local ESX = nil

-- Initialize ESX
CreateThread(function()
    ESX = exports['es_extended']:getSharedObject()
end)

-- Handle police alerts
RegisterServerEvent('SendAlert:police')
AddEventHandler('SendAlert:police', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local coords = data.coords
    local title = data.title or "Alerta Policial"
    local description = data.description or "Se ha reportado una situación sospechosa"
    local job = data.job or "police"
    
    -- Get all players with police job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    
    for _, xPolice in pairs(xPlayers) do
        TriggerClientEvent('hostage:policeAlert', xPolice.source, {
            coords = coords,
            title = title,
            description = description
        })
    end
    
    print(('[HOSTAGE] Alert sent to %s officers - %s'):format(#xPlayers, title))
end)

-- Optional: Log hostage events
RegisterServerEvent('hostage:logEvent')
AddEventHandler('hostage:logEvent', function(eventType, targetPed)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local playerName = xPlayer.getName()
    local identifier = xPlayer.identifier
    
    print(('[HOSTAGE] Player: %s (%s) - Event: %s'):format(playerName, identifier, eventType))
    
    -- You can add webhook logging here if needed
    -- Example: Send to Discord webhook
end)

-- Check if player has required job (optional security check)
ESX.RegisterServerCallback('hostage:canTakeHostage', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then 
        cb(false)
        return
    end
    
    -- Add your own logic here
    -- For example, only allow certain jobs to take hostages
    -- Or check if player has a specific item
    
    cb(true)
end)

print('^2[HOSTAGE]^7 Server script loaded successfully for ESX')
