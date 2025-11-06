local ESX = nil
local activeBlips = {}

-- Initialize ESX
CreateThread(function()
    ESX = exports['es_extended']:getSharedObject()
end)

-- Receive police alert
RegisterNetEvent('hostage:policeAlert')
AddEventHandler('hostage:policeAlert', function(data)
    local coords = data.coords
    local title = data.title
    local description = data.description
    
    -- Show notification
    if Cfg.Framework == "esx" then
        ESX.ShowNotification(title .. ': ' .. description)
    end
    
    -- Play sound
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    
    -- Create blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161) -- Hostage icon
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1) -- Red
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(title)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip
    table.insert(activeBlips, blip)
    
    -- Remove blip after 5 minutes
    CreateThread(function()
        Wait(300000) -- 5 minutes
        RemoveBlip(blip)
        
        -- Remove from active blips table
        for i, b in pairs(activeBlips) do
            if b == blip then
                table.remove(activeBlips, i)
                break
            end
        end
    end)
end)

-- Cleanup blips on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in pairs(activeBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        activeBlips = {}
    end
end)
