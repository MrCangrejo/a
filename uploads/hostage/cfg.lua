Cfg = {} or Cfg

Cfg.Framework = 'esx' -- qbcore, esx or custom

Cfg.CustomNotify = true

Cfg.Percentage = 20

Cfg.Language = 'es'

Cfg.KillKey = 38 -- E
Cfg.KneelKey = 149 -- S

Cfg.CustomMenu = false

Cfg.MaxHostages = 5 -- Max hostages that a player can have
Cfg.DistanceToEscape = 30.0 -- The distance that the hostage have to be from the player to escape 

function GetCoreObject()
    -- If you use a custom framework, return your core object here
    -- Example: return exports['your_core']:GetCoreObject()
    return nil
end

function openMenu(entity)
    lib.registerContext({
        id = 'hostageped',
        title = '¿En que puedo ayudarte?',
        options = {
            {
                title = 'Liberar',
                icon = 'fa-solid fa-person-running',
                onSelect = function()
                    release(entity)
                end
            },
            {
                title = 'Sigueme',
                icon = 'fa-solid fa-person-walking-arrow-right',
                onSelect = function()
                    follow(entity)
                end
            },
            {
                title = 'Quedate aquí',
                icon = 'fa-solid fa-person-praying',
                onSelect = function()
                    kneel(entity)
                end
            },
            {
                title = 'Cogerlo del cuello',
                icon = 'fa-solid fa-gun',
                onSelect = function()
                    threaten(entity)
                end
            },
        }
    })
    -- Functions to make this work
    -- release(entity)
    -- follow(entity)
    -- kneel(entity)
    -- threaten(entity)
    lib.showContext('hostageped')
end

function ShowHelpNotification(key, msg, entity)
    -- Check if origen_notify exists
    if GetResourceState('origen_notify') == 'started' then
        if notifyId == nil then
            notifyId = exports["origen_notify"]:CreateHelp("E", msg)
        end
    else
        -- Fallback to native help text
        BeginTextCommandDisplayHelp("STRING")
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, true, -1)
    end
end

function HideHelpNotification()
    if GetResourceState('origen_notify') == 'started' then
        if notifyId ~= nil then
            exports["origen_notify"]:RemoveHelp(notifyId)
            notifyId = nil
        end
    else
        -- Clear native help text
        ClearAllHelpMessages()
    end
end

-- @param msg string 
function ShowNotification(msg)
    if not Cfg.CustomNotify then
        if Cfg.Framework == "qbcore" then
            QBCore.Functions.Notify(msg, "primary")
        elseif Cfg.Framework == "esx" then
            ESX.ShowNotification(msg)
        end
    else
        -- Put your code here if you want to use a custom notification
    end
end

function sendPoliceAlert(coords)
    TriggerServerEvent("SendAlert:police", {
        coords = GetEntityCoords(PlayerPedId()), -- Coordinates vector3(x, y, z) in which the alert is triggered
        title = "Intento de secuestro",
        description = "Una persona armada está intentado secuestrar a alguien, ayuda por favor!!",
        job = "police"
    })
end

function CanKillNPC()
    -- Your code to check if the player can kill the npc
    return true
end

Cfg.Translations = {
    ['es'] = {
        ['someter'] = 'Someter',
        ['Matar'] = {
            ['kill'] = 'Matar | S Volver a arrodillar', -- Only if you use origen_notify
            ['kneel'] = 'Volver a arrodillar', -- Only if you use origen_notify
            ['fullText'] = '[E] Matar | [Backspace] Volver a arrodillar',
        },
        ['ignored'] = 'El civil ha ignorado tu amenaza',
        ['hostage_options'] = 'Opciones de rehén',
        ['release_hostage'] = 'Liberar rehén',
        ['release_hostage_desc'] = 'Deja al rehén libre',
        ['follow_hostage'] = 'Sigueme',
        ['follow_hostage_desc'] = 'Ordena al rehén que te siga',
        ['kneel_hostage'] = 'Arrodillate',
        ['kneel_hostage_desc'] = 'Ordena al rehén que se arrodille',
        ['threat_hostage'] = 'Amenzar',
        ['threat_hostage_desc'] = 'Amenaza al rehén con un arma en el cuello',
        ['max_hostages'] = 'No puedes tener más rehenes',
    },
    ['en'] = {
        ['someter'] = '~y~E~w~ Subdue',
        ['Matar'] = {
            ['kill'] = 'Kill',-- Only if you use origen_notify
            ['kneel'] = 'Return to kneeling',-- Only if you use origen_notify
            ['fullText'] = '[E] Kill  | [Backspace] Return to kneeling',
        },
        ['ignored'] = 'The civilian ignored your threat',
        ['hostage_options'] = 'Hostage options',
        ['release_hostage'] = 'Release hostage',
        ['release_hostage_desc'] = 'Set the hostage free',
        ['follow_hostage'] = 'Follow me',
        ['follow_hostage_desc'] = 'Order the hostage to follow you',
        ['kneel_hostage'] = 'Kneel',
        ['kneel_hostage_desc'] = 'Order the hostage to kneel',
        ['threat_hostage'] = 'Threaten',
        ['threat_hostage_desc'] = 'Threaten the hostage with a weapon at the neck',
        ['max_hostages'] = 'You can\'t have more hostages',
    },
    ['it'] = {
        ['someter'] = '~y~E~w~ Sottomettere',
        ['Matar'] = {
            ['kill'] = 'Uccidi', -- Only if you use origen_notify
            ['kneel'] = 'Torna a far inginocchiare', -- Only if you use origen_notify
            ['fullText'] = '[E] Uccidi | [Backspace] Torna a far inginocchiare',
        },
        ['ignored'] = 'Il civile ha ignorato la tua minaccia',
        ['hostage_options'] = 'Opzioni ostaggio',
        ['release_hostage'] = 'Liberare ostaggio',
        ['release_hostage_desc'] = "Lascia libero l'ostaggio",
        ['follow_hostage'] = 'Segui ostaggio',
        ['follow_hostage_desc'] = "Ordina all'ostaggio di seguirti",
        ['kneel_hostage'] = 'Fai inginocchiare ostaggio',
        ['kneel_hostage_desc'] = "Ordina all'ostaggio di inginocchiarsi",
        ['threat_hostage'] = 'Minaccia ostaggio',
        ['threat_hostage_desc'] = "Minaccia l'ostaggio con un'arma al collo",
        ['max_hostages'] = 'Non puoi avere più ostaggi',
    },
    
    
}

Cfg.Translations = Cfg.Translations[Cfg.Language] -- DONT TOUCH THIS