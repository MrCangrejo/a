local QBCore = nil
local ESX = nil
local hostages = {}
local currentHostageCount = 0
local notifyId = nil

-- Initialize Framework
CreateThread(function()
    if Cfg.Framework == "qbcore" then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Cfg.Framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
    elseif Cfg.Framework == "custom" then
        -- Add your custom framework initialization here
        local customCore = GetCoreObject()
        if customCore then
            QBCore = customCore
        end
    end
end)

-- Helper function to check if player has weapon
local function HasWeapon()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    return weapon ~= `WEAPON_UNARMED`
end

-- Helper function to get closest ped
local function GetClosestPed(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed = nil
    local closestDistance = radius or 3.0
    
    local peds = GetGamePool('CPed')
    for _, ped in pairs(peds) do
        if ped ~= playerPed and not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped, false) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestPed = ped
            end
        end
    end
    
    return closestPed, closestDistance
end

-- Check if ped is already a hostage
local function IsHostage(ped)
    for _, hostage in pairs(hostages) do
        if hostage.ped == ped then
            return true
        end
    end
    return false
end

-- Release hostage function
function release(entity)
    if not DoesEntityExist(entity) then return end
    
    for i, hostage in pairs(hostages) do
        if hostage.ped == entity then
            ClearPedTasksImmediately(entity)
            SetBlockingOfNonTemporaryEvents(entity, false)
            SetPedAsNoLongerNeeded(entity)
            TaskWanderStandard(entity, 10.0, 10)
            
            table.remove(hostages, i)
            currentHostageCount = currentHostageCount - 1
            ShowNotification(Cfg.Translations['release_hostage'])
            break
        end
    end
end

-- Follow function
function follow(entity)
    if not DoesEntityExist(entity) then return end
    
    for _, hostage in pairs(hostages) do
        if hostage.ped == entity then
            hostage.state = "following"
            ClearPedTasksImmediately(entity)
            TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.0, -1.5, 0.0, 1.5, -1, 2.0, true)
            ShowNotification(Cfg.Translations['follow_hostage'])
            break
        end
    end
end

-- Kneel function
function kneel(entity)
    if not DoesEntityExist(entity) then return end
    
    for _, hostage in pairs(hostages) do
        if hostage.ped == entity then
            hostage.state = "kneeling"
            ClearPedTasksImmediately(entity)
            
            local coords = GetEntityCoords(entity)
            TaskGoToCoordAnyMeans(entity, coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 0xbf800000)
            
            Wait(500)
            RequestAnimDict("random@arrests")
            while not HasAnimDictLoaded("random@arrests") do
                Wait(10)
            end
            
            TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, -8.0, -1, 49, 0, false, false, false)
            ShowNotification(Cfg.Translations['kneel_hostage'])
            break
        end
    end
end

-- Threaten function
function threaten(entity)
    if not DoesEntityExist(entity) then return end
    
    if not HasWeapon() then
        ShowNotification("Necesitas un arma para amenazar")
        return
    end
    
    for _, hostage in pairs(hostages) do
        if hostage.ped == entity then
            hostage.state = "threatened"
            
            local playerPed = PlayerPedId()
            ClearPedTasksImmediately(entity)
            ClearPedTasksImmediately(playerPed)
            
            -- Load animations
            RequestAnimDict("anim@gangops@hostage@")
            while not HasAnimDictLoaded("anim@gangops@hostage@") do
                Wait(10)
            end
            
            -- Attach hostage to player
            AttachEntityToEntity(entity, playerPed, 11816, -0.1, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            TaskPlayAnim(entity, "anim@gangops@hostage@", "victim_idle", 8.0, -8.0, -1, 49, 0, false, false, false)
            TaskPlayAnim(playerPed, "anim@gangops@hostage@", "perp_idle", 8.0, -8.0, -1, 49, 0, false, false, false)
            
            SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_PISTOL"), true)
            
            ShowNotification(Cfg.Translations['threat_hostage'])
            
            -- Handle release
            CreateThread(function()
                while hostage.state == "threatened" and DoesEntityExist(entity) do
                    Wait(0)
                    
                    -- Disable certain controls while threatening
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 25, true) -- Aim
                    DisableControlAction(0, 44, true) -- Cover
                    DisableControlAction(0, 37, true) -- Select Weapon
                    
                    if IsControlJustPressed(0, 47) then -- G key to release
                        DetachEntity(entity, true, false)
                        ClearPedTasksImmediately(entity)
                        ClearPedTasksImmediately(playerPed)
                        hostage.state = "following"
                        ShowNotification("Rehén liberado de la amenaza")
                        break
                    end
                    
                    -- If player dies or gets in vehicle, release hostage
                    if IsPedDeadOrDying(playerPed, true) or IsPedInAnyVehicle(playerPed, false) then
                        DetachEntity(entity, true, false)
                        ClearPedTasksImmediately(entity)
                        hostage.state = "following"
                        break
                    end
                end
            end)
            break
        end
    end
end

-- Subdue NPC
local function SubdueNPC(ped)
    if currentHostageCount >= Cfg.MaxHostages then
        ShowNotification(Cfg.Translations['max_hostages'])
        return
    end
    
    if IsHostage(ped) then
        return
    end
    
    -- Random chance to alert police
    if math.random(100) <= Cfg.Percentage then
        sendPoliceAlert(GetEntityCoords(PlayerPedId()))
    end
    
    -- Random chance to ignore threat
    if math.random(100) > 70 then
        ShowNotification(Cfg.Translations['ignored'])
        TaskSmartFleePed(ped, PlayerPedId(), 100.0, -1, false, false)
        return
    end
    
    -- Subdue the NPC
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    
    RequestAnimDict("random@arrests")
    while not HasAnimDictLoaded("random@arrests") do
        Wait(10)
    end
    
    TaskPlayAnim(ped, "random@arrests", "idle_2_hands_up", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Add to hostages table
    table.insert(hostages, {
        ped = ped,
        state = "subdued"
    })
    currentHostageCount = currentHostageCount + 1
    
    ShowNotification("Rehén capturado")
end

-- Kill hostage
local function KillHostage(ped)
    if not CanKillNPC() then
        return
    end
    
    for i, hostage in pairs(hostages) do
        if hostage.ped == ped then
            SetEntityHealth(ped, 0)
            table.remove(hostages, i)
            currentHostageCount = currentHostageCount - 1
            break
        end
    end
end

-- Main thread for hostage interaction
CreateThread(function()
    while true do
        local sleep = 500
        
        local playerPed = PlayerPedId()
        local closestPed, distance = GetClosestPed(3.0)
        
        if closestPed and HasWeapon() then
            sleep = 0
            if not IsHostage(closestPed) then
                -- Show subdue prompt
                ShowHelpNotification(Cfg.KillKey, Cfg.Translations['someter'], closestPed)
                
                if IsControlJustPressed(0, Cfg.KillKey) then
                    SubdueNPC(closestPed)
                    HideHelpNotification()
                end
            else
                -- Show hostage options
                if IsControlJustPressed(0, Cfg.KillKey) then
                    HideHelpNotification()
                    if Cfg.CustomMenu then
                        openMenu(closestPed)
                    else
                        -- Default menu using native GTA menu or ox_lib
                        if GetResourceState('ox_lib') == 'started' then
                            openMenu(closestPed)
                        else
                            -- Simple ESX menu
                            OpenHostageMenu(closestPed)
                        end
                    end
                end
            end
        else
            if notifyId then
                HideHelpNotification()
            end
        end
        
        Wait(sleep)
    end
end)

-- Thread for handling kneeling hostages
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        
        -- Handle kneeling hostages
        for i, hostage in pairs(hostages) do
            if DoesEntityExist(hostage.ped) then
                local hostageCoords = GetEntityCoords(hostage.ped)
                local playerCoords = GetEntityCoords(playerPed)
                local dist = #(hostageCoords - playerCoords)
                
                if hostage.state == "kneeling" then
                    if dist < 2.0 then
                        sleep = 0
                        ShowHelpNotification(Cfg.KillKey, Cfg.Translations['Matar']['fullText'], hostage.ped)
                        
                        -- Kill hostage
                        if IsControlJustPressed(0, Cfg.KillKey) then
                            KillHostage(hostage.ped)
                            HideHelpNotification()
                        end
                        
                        -- Return to kneeling
                        if IsControlJustPressed(0, Cfg.KneelKey) then
                            kneel(hostage.ped)
                        end
                    end
                end
                
                -- Check if hostage is too far and should escape
                if dist > Cfg.DistanceToEscape and hostage.state ~= "threatened" then
                    release(hostage.ped)
                    ShowNotification("El rehén ha escapado")
                end
            else
                -- Remove dead or deleted hostages
                table.remove(hostages, i)
                currentHostageCount = currentHostageCount - 1
            end
        end
        
        Wait(sleep)
    end
end)

-- ESX Menu for hostage options (fallback if ox_lib not available)
function OpenHostageMenu(entity)
    if not DoesEntityExist(entity) then return end
    
    ESX.UI.Menu.CloseAll()
    
    local elements = {
        {label = Cfg.Translations['release_hostage'], value = 'release'},
        {label = Cfg.Translations['follow_hostage'], value = 'follow'},
        {label = Cfg.Translations['kneel_hostage'], value = 'kneel'},
        {label = Cfg.Translations['threat_hostage'], value = 'threaten'},
    }
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'hostage_menu', {
        title    = Cfg.Translations['hostage_options'],
        align    = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value
        
        if action == 'release' then
            release(entity)
        elseif action == 'follow' then
            follow(entity)
        elseif action == 'kneel' then
            kneel(entity)
        elseif action == 'threaten' then
            threaten(entity)
        end
        
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, hostage in pairs(hostages) do
            if DoesEntityExist(hostage.ped) then
                release(hostage.ped)
            end
        end
        HideHelpNotification()
    end
end)

-- Cleanup on player death
AddEventHandler('esx:onPlayerDeath', function()
    for _, hostage in pairs(hostages) do
        if DoesEntityExist(hostage.ped) then
            release(hostage.ped)
        end
    end
    hostages = {}
    currentHostageCount = 0
end)
