local ESX
local ActiveScenes = {}
local PlayerScenes = {}
local ConsentRequests = {}
local PlayerCooldowns = {}

local function ensureESX()
    if ESX then return ESX end

    local state = GetResourceState('es_extended')
    if state ~= 'missing' then
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return ESX
        end
    end

    TriggerEvent('esx:getSharedObject', function(obj)
        ESX = obj
    end)

    while not ESX do
        Wait(50)
    end

    return ESX
end

ensureESX()

local allowedJobs = {}
if Config.AllowedJobs then
    for _, job in ipairs(Config.AllowedJobs) do
        allowedJobs[job] = true
    end
end

local function translate(key, ...)
    local text = Config.Texts[key] or key
    if select('#', ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

local function notifyPlayer(source, nType, message)
    TriggerClientEvent('mrc_torture:notify', source, nType, message)
end

local function hasPermission(source)
    if Config.AllowEveryone then
        return true
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then
        return false
    end

    return allowedJobs[xPlayer.job.name] == true
end

local function isPlayerNearSpot(playerId, spot)
    if not spot or not spot.coords then return false end
    local ped = GetPlayerPed(playerId)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    return #(coords - spot.coords) <= (Config.SpotRange or 4.0)
end

local function broadcastSceneState(spotId, state)
    TriggerClientEvent('mrc_torture:updateSceneState', -1, spotId, state)
end

local function clearScene(spotId, reasonKey)
    local scene = ActiveScenes[spotId]
    if not scene then return end

    if scene.torturer then
        TriggerClientEvent('mrc_torture:stopScene', scene.torturer, spotId, reasonKey)
        PlayerScenes[scene.torturer] = nil
    end

    if scene.victim then
        TriggerClientEvent('mrc_torture:stopScene', scene.victim, spotId, reasonKey)
        PlayerScenes[scene.victim] = nil
    end

    ActiveScenes[spotId] = nil
    broadcastSceneState(spotId, { active = false })
end

local function startScene(spotId, torturer, victim)
    local spot = Config.TortureSpots[spotId]
    if not spot then return end

    ActiveScenes[spotId] = {
        active = true,
        torturer = torturer,
        victim = victim,
        startedAt = os.time(),
        toolInUse = false,
        lastTool = 0
    }

    PlayerScenes[torturer] = spotId
    PlayerScenes[victim] = spotId

    broadcastSceneState(spotId, {
        active = true,
        torturer = torturer,
        victim = victim
    })

    TriggerClientEvent('mrc_torture:startScene', torturer, spotId, 'torturer')
    TriggerClientEvent('mrc_torture:startScene', victim, spotId, 'victim')

    PlayerCooldowns[torturer] = os.time() + (Config.SceneCooldown or 0)
end

RegisterNetEvent('mrc_torture:requestStart', function(spotId, targetId)
    local source = source
    local spot = Config.TortureSpots[spotId]

    if not spot then
        return
    end

    if not targetId or GetPlayerPed(targetId) == 0 then
        notifyPlayer(source, 'error', translate('no_players'))
        return
    end

    if not hasPermission(source) then
        notifyPlayer(source, 'error', translate('no_permission'))
        return
    end

    if source == targetId then
        notifyPlayer(source, 'error', translate('same_target'))
        return
    end

    if ActiveScenes[spotId] then
        notifyPlayer(source, 'error', translate('already_active'))
        return
    end

    if PlayerScenes[source] then
        notifyPlayer(source, 'error', translate('already_active'))
        return
    end

    if PlayerScenes[targetId] then
        notifyPlayer(source, 'error', translate('scene_busy'))
        return
    end

    if Config.SceneCooldown and Config.SceneCooldown > 0 then
        local cooldown = PlayerCooldowns[source]
        if cooldown and cooldown > os.time() then
            notifyPlayer(source, 'error', translate('cooldown'))
            return
        end
    end

    if not isPlayerNearSpot(source, spot) or not isPlayerNearSpot(targetId, spot) then
        notifyPlayer(source, 'error', translate('victim_too_far'))
        return
    end

    if Config.RequireVictimConsent then
        local requestId = ('%s:%s:%s:%s'):format(source, targetId, spotId, os.time())
        ConsentRequests[requestId] = {
            torturer = source,
            victim = targetId,
            spotId = spotId,
            expire = GetGameTimer() + (Config.ConsentTimeout or 15000)
        }

        TriggerClientEvent('mrc_torture:askConsent', targetId, requestId, source, spotId)

        SetTimeout(Config.ConsentTimeout or 15000, function()
            local request = ConsentRequests[requestId]
            if request then
                ConsentRequests[requestId] = nil
                notifyPlayer(source, 'error', translate('consent_timeout'))
                TriggerClientEvent('mrc_torture:clearConsent', targetId)
            end
        end)
    else
        startScene(spotId, source, targetId)
    end
end)

RegisterNetEvent('mrc_torture:consentResult', function(requestId, accepted)
    local source = source
    local request = ConsentRequests[requestId]
    if not request then
        return
    end

    if request.victim ~= source then
        return
    end

    ConsentRequests[requestId] = nil

    local torturer = request.torturer
    local victim = request.victim
    local spotId = request.spotId

    TriggerClientEvent('mrc_torture:clearConsent', victim)

    if not accepted then
        notifyPlayer(torturer, 'error', translate('scene_denied'))
        return
    end

    if not hasPermission(torturer) then
        notifyPlayer(torturer, 'error', translate('no_permission'))
        return
    end

    if PlayerScenes[torturer] or PlayerScenes[victim] then
        notifyPlayer(torturer, 'error', translate('scene_busy'))
        return
    end

    local spot = Config.TortureSpots[spotId]
    if not spot then
        return
    end

    if not isPlayerNearSpot(torturer, spot) or not isPlayerNearSpot(victim, spot) then
        notifyPlayer(torturer, 'error', translate('victim_too_far'))
        return
    end

    startScene(spotId, torturer, victim)
end)

RegisterNetEvent('mrc_torture:useTool', function(spotId, toolName)
    local source = source
    local scene = ActiveScenes[spotId]
    if not scene or scene.torturer ~= source then
        return
    end

    local tool = Config.Tools[toolName]
    if not tool then
        return
    end

    if scene.toolInUse then
        notifyPlayer(source, 'error', translate('tool_cooldown'))
        return
    end

    local now = GetGameTimer()
    if Config.ToolCooldown and Config.ToolCooldown > 0 and scene.lastTool and now - scene.lastTool < Config.ToolCooldown then
        notifyPlayer(source, 'error', translate('tool_cooldown'))
        return
    end

    scene.toolInUse = true
    scene.lastTool = now

    TriggerClientEvent('mrc_torture:performTool', scene.torturer, spotId, toolName)
    TriggerClientEvent('mrc_torture:receiveTool', scene.victim, spotId, toolName)

    if tool.effects and tool.effects.health and tool.effects.health.amount then
        TriggerClientEvent('mrc_torture:applyDamage', scene.victim, tool.effects.health.amount, tool.effects.health.canKill or false)
    end

    if tool.effects and tool.effects.stress and tool.effects.stress.amount and Config.StressEvent then
        TriggerEvent(Config.StressEvent, scene.victim, tool.effects.stress.amount)
    end

    SetTimeout(tool.duration or 4000, function()
        if ActiveScenes[spotId] then
            ActiveScenes[spotId].toolInUse = false
        end
    end)
end)

RegisterNetEvent('mrc_torture:requestEnd', function(spotId, reason)
    local source = source
    local scene = ActiveScenes[spotId]
    if not scene then
        return
    end

    if scene.torturer ~= source and scene.victim ~= source then
        if not IsPlayerAceAllowed(source, 'command.mrc_torture') then
            return
        end
    end

    clearScene(spotId, reason == 'manual' and 'scene_finished' or 'scene_cancelled')
end)


RegisterNetEvent('mrc_torture:syncState', function()
    local source = source
    for spotId, scene in pairs(ActiveScenes) do
        TriggerClientEvent('mrc_torture:updateSceneState', source, spotId, {
            active = true,
            torturer = scene.torturer,
            victim = scene.victim
        })
    end
end)

RegisterNetEvent('mrc_torture:notifyDeath', function(spotId)
    local source = source
    local scene = ActiveScenes[spotId]
    if not scene or scene.victim ~= source then
        return
    end

    clearScene(spotId, 'victim_dead')
end)

AddEventHandler('playerDropped', function()
    local source = source
    local spotId = PlayerScenes[source]
    if spotId then
        clearScene(spotId, 'victim_disconnected')
    end

    for requestId, request in pairs(ConsentRequests) do
        if request.torturer == source or request.victim == source then
            ConsentRequests[requestId] = nil
        end
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
    local spotId = PlayerScenes[source]
    if spotId then
        clearScene(spotId, 'scene_cancelled')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for spotId, _ in pairs(ActiveScenes) do
        clearScene(spotId, 'scene_cancelled')
    end
end)
