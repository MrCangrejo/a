local ESX
local hasOxLib = GetResourceState('ox_lib') == 'started'
local hasTarget = GetResourceState('ox_target') == 'started'

local ScenesState = {}
local ActiveScene
local ChairEntities = {}
local ChairTargets = {}
local CurrentToolProp
local ControlThreadActive = false
local PendingConsent

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

    CreateThread(function()
        while not ESX do
            TriggerEvent('esx:getSharedObject', function(obj)
                ESX = obj
            end)
            Wait(50)
        end
    end)

    while not ESX do
        Wait(50)
    end

    return ESX
end

local function translate(key, ...)
    local text = Config.Texts[key] or key
    if select('#', ...) > 0 then
        return string.format(text, ...)
    end
    return text
end

local function notify(message, nType)
    if hasOxLib then
        exports.ox_lib:notify({
            description = message,
            type = nType or 'inform'
        })
    else
        ensureESX()
        ESX.ShowNotification(message)
    end
end

local function requestModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelValid(model) then
        return false
    end

    if not HasModelLoaded(model) then
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) do
            Wait(10)
            timeout = timeout + 10
            if timeout >= 5000 then
                break
            end
        end
    end

    return HasModelLoaded(model)
end

local function loadAnimDict(dict)
    if type(dict) == 'table' then
        for _, entry in ipairs(dict) do
            local loaded = loadAnimDict(entry)
            if loaded then
                return loaded
            end
        end
        return nil
    end

    if HasAnimDictLoaded(dict) then
        return dict
    end

    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout >= 5000 then
            break
        end
    end

    if HasAnimDictLoaded(dict) then
        return dict
    end

    return nil
end

local function resolveAnimation(animData)
    if not animData then return end

    if animData.variants then
        for _, variant in ipairs(animData.variants) do
            local dict = loadAnimDict(variant.dict)
            if dict then
                return dict, variant.clip, variant.flag, variant.duration
            end
        end
    else
        local dict = loadAnimDict(animData.dict)
        if dict then
            return dict, animData.clip, animData.flag, animData.duration
        end
    end

    return nil
end

local function clearToolProp()
    if CurrentToolProp and DoesEntityExist(CurrentToolProp) then
        DeleteObject(CurrentToolProp)
    end
    CurrentToolProp = nil
end

local function detachVictim()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    DetachEntity(ped, true, true)
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    SetEntityCollision(ped, true, true)
    SetPedCanRagdoll(ped, true)
end

local function playBaseVictimAnim(spotId)
    local ped = PlayerPedId()
    local data = Config.TortureSpots[spotId]
    local base = Config.BaseVictimAnim

    if not data or not base then return end

    local chair = ChairEntities[spotId]
    if not chair or not DoesEntityExist(chair) then return end

    local dict, clip, flag, animDuration = resolveAnimation(base)
    if not dict then
        local references = {}
        if base.variants then
            for _, variant in ipairs(base.variants) do
                references[#references+1] = tostring(variant.dict)
            end
        else
            local baseDict = base.dict
            if type(baseDict) == 'table' then
                for _, entry in ipairs(baseDict) do
                    references[#references+1] = tostring(entry)
                end
            else
                references[#references+1] = tostring(base.dict)
            end
        end
        print(('[mrc_torture] No se pudo cargar ninguna animación base (%s)'):format(table.concat(references, ', ')))
        return
    end

    if not clip then
        print('[mrc_torture] La animación base no tiene clip válido configurado.')
        return
    end

    local offset = data.victimOffset or vec3(0.0, 0.0, 0.0)
    local rotation = data.victimRotation or vec3(0.0, 0.0, 0.0)
    local worldPos = GetOffsetFromEntityInWorldCoords(chair, offset)
    local heading = (data.heading or GetEntityHeading(chair)) + (rotation.z or 0.0)

    DetachEntity(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityCoordsNoOffset(ped, worldPos.x, worldPos.y, worldPos.z, false, false, false)
    SetEntityHeading(ped, heading)

    TaskPlayAnimAdvanced(
        ped,
        dict,
        clip,
        worldPos.x,
        worldPos.y,
        worldPos.z,
        rotation.x or 0.0,
        rotation.y or 0.0,
        heading,
        base.blendIn or 8.0,
        base.blendOut or -8.0,
        animDuration or base.duration or -1,
        flag or base.flag or 33,
        0.0,
        false,
        false,
        false
    )

    AttachEntityToEntity(ped, chair, data.victimBone or 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, false, 2, true)
    SetPedCanRagdoll(ped, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
end

local function disableControlsThread()
    if ControlThreadActive then return end
    ControlThreadActive = true
    CreateThread(function()
        while ActiveScene do
            if Config.DisableVictimControls and ActiveScene.role == 'victim' then
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 264, true)
            end

            if Config.KeepTorturerStill and ActiveScene.role == 'torturer' then
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 32, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
            end

            Wait(0)
        end
        ControlThreadActive = false
    end)
end

local function setupChairTarget(spotId, entity)
    if not hasTarget then
        print('[mrc_torture] ox_target no está disponible, no se podrán usar las interacciones.')
        return
    end

    local options = {
        {
            name = ('mrc_torture:start:%s'):format(spotId),
            label = translate('start_title'),
            icon = 'fa-solid fa-user-lock',
            distance = 1.8,
            onSelect = function()
                TriggerEvent('mrc_torture:clientStart', spotId)
            end,
            canInteract = function(_, distance)
                local scene = ScenesState[spotId]
                if ActiveScene and ActiveScene.role == 'victim' then
                    return false
                end
                if scene and scene.active then
                    return false
                end
                return distance <= 2.0
            end
        },
        {
            name = ('mrc_torture:tool:%s'):format(spotId),
            label = translate('tool_menu'),
            icon = 'fa-solid fa-khanda',
            distance = 1.8,
            onSelect = function()
                TriggerEvent('mrc_torture:openToolMenu', spotId)
            end,
            canInteract = function(_, distance)
                local scene = ScenesState[spotId]
                if not scene or not scene.active then
                    return false
                end
                local myId = GetPlayerServerId(PlayerId())
                return scene.torturer == myId and distance <= 2.0
            end
        },
        {
            name = ('mrc_torture:release:%s'):format(spotId),
            label = translate('scene_finished'),
            icon = 'fa-solid fa-unlock-keyhole',
            distance = 1.8,
            onSelect = function()
                TriggerServerEvent('mrc_torture:requestEnd', spotId, 'manual')
            end,
            canInteract = function(_, distance)
                local scene = ScenesState[spotId]
                if not scene or not scene.active then
                    return false
                end
                local myId = GetPlayerServerId(PlayerId())
                if scene.torturer == myId or scene.victim == myId then
                    return distance <= 2.0
                end
                return false
            end
        }
    }

    local targetId = exports.ox_target:addLocalEntity(entity, options)
    ChairTargets[spotId] = targetId
end

local function createChair(spotId, data)
    if ChairEntities[spotId] and DoesEntityExist(ChairEntities[spotId]) then
        return ChairEntities[spotId]
    end

    if not requestModel(data.chairProp) then
        print(('[mrc_torture] No se pudo cargar el modelo de la silla %s'):format(data.chairProp))
        return nil
    end

    local modelHash = joaat(data.chairProp)
    local obj = CreateObjectNoOffset(modelHash, data.coords.x, data.coords.y, data.coords.z, false, false, false)
    if not DoesEntityExist(obj) then
        return nil
    end

    SetEntityHeading(obj, data.heading or 0.0)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    ChairEntities[spotId] = obj
    SetModelAsNoLongerNeeded(modelHash)

    setupChairTarget(spotId, obj)
    return obj
end

local function createBlip(spotId, data)
    local blipConfig = data.blip ~= nil and data.blip or Config.DefaultBlip
    if not blipConfig or not blipConfig.enabled then
        return
    end

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, blipConfig.sprite or 52)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipConfig.scale or 0.8)
    SetBlipColour(blip, blipConfig.colour or 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipConfig.name or 'Interrogatorio')
    EndTextCommandSetBlipName(blip)
end

local function buildSpots()
    ensureESX()
    for index, data in ipairs(Config.TortureSpots) do
        createChair(index, data)
        createBlip(index, data)
    end
end

local function getNearbyPlayers(distance)
    local players = {}
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                if #(coords - targetCoords) <= distance then
                    local id = GetPlayerServerId(player)
                    table.insert(players, {
                        id = id,
                        name = GetPlayerName(player) or ('ID %s'):format(id)
                    })
                end
            end
        end
    end

    return players
end

local function openPlayerMenu(spotId)
    local players = getNearbyPlayers(Config.InteractionDistance)
    if #players == 0 then
        notify(translate('no_players'), 'error')
        return
    end

    if hasOxLib then
        local options = {}
        for _, player in ipairs(players) do
            options[#options+1] = {
                title = player.name,
                description = ('ID: %s'):format(player.id),
                icon = 'fa-solid fa-user',
                onSelect = function()
                    TriggerServerEvent('mrc_torture:requestStart', spotId, player.id)
                end
            }
        end
        exports.ox_lib:registerContext({
            id = 'mrc_torture_players_' .. spotId,
            title = translate('start_title'),
            description = translate('start_description'),
            options = options
        })
        exports.ox_lib:showContext('mrc_torture_players_' .. spotId)
    else
        ensureESX()
        local elements = {}
        for _, player in ipairs(players) do
            elements[#elements+1] = {
                label = ('%s (ID: %s)'):format(player.name, player.id),
                value = player.id
            }
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mrc_torture_players', {
            title = translate('start_title'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            TriggerServerEvent('mrc_torture:requestStart', spotId, data.current.value)
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    end
end

local function openToolMenu(spotId)
    if not ActiveScene or ActiveScene.spotId ~= spotId or ActiveScene.role ~= 'torturer' then
        return
    end

    local options = {}
    for toolName, tool in pairs(Config.Tools) do
        options[#options+1] = {
            title = tool.label,
            description = ('Duración: %.1f s'):format((tool.duration or 1000) / 1000),
            icon = tool.icon or 'fa-solid fa-hands',
            onSelect = function()
                TriggerServerEvent('mrc_torture:useTool', spotId, toolName)
            end
        }
    end

    if hasOxLib then
        exports.ox_lib:registerContext({
            id = 'mrc_torture_tools_' .. spotId,
            title = translate('tool_menu'),
            options = options
        })
        exports.ox_lib:showContext('mrc_torture_tools_' .. spotId)
    else
        ensureESX()
        local elements = {}
        for _, option in ipairs(options) do
            elements[#elements+1] = {
                label = option.title,
                value = option
            }
        end
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mrc_torture_tools', {
            title = translate('tool_menu'),
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            local opt = data.current.value
            if opt then
                opt.onSelect()
            end
        end, function(data, menu)
            menu.close()
        end)
    end
end

local function attachVictimToChair(spotId)
    local data = Config.TortureSpots[spotId]
    if not data then return end
    local chair = ChairEntities[spotId]
    if not chair or not DoesEntityExist(chair) then
        chair = createChair(spotId, data)
    end
    if not chair then return end

    local ped = PlayerPedId()
    local offset = data.victimOffset or vec3(0.0, 0.0, 0.0)
    local worldPos = GetOffsetFromEntityInWorldCoords(chair, offset)

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCoordsNoOffset(ped, worldPos.x, worldPos.y, worldPos.z, false, false, false)
    SetEntityHeading(ped, data.heading or GetEntityHeading(chair))
    SetPedCanRagdoll(ped, false)
    SetEntityCollision(ped, false, false)

    playBaseVictimAnim(spotId)

    if Config.BaseVictimAnim and Config.BaseVictimAnim.reapplyDelay then
        CreateThread(function()
            Wait(Config.BaseVictimAnim.reapplyDelay)
            if ActiveScene and ActiveScene.role == 'victim' and ActiveScene.spotId == spotId then
                playBaseVictimAnim(spotId)
            end
        end)
    end
end

local function positionTorturer(spotId)
    local data = Config.TortureSpots[spotId]
    if not data then return end
    local ped = PlayerPedId()
    local offset = data.torturerOffset or vec3(0.0, -1.0, 0.0)

    local position = vector3(data.coords.x + offset.x, data.coords.y + offset.y, data.coords.z + offset.z)
    SetEntityCoords(ped, position.x, position.y, position.z, false, false, false, true)
    SetEntityHeading(ped, (data.heading or 0.0) + (data.torturerHeading or 180.0))
    ClearPedTasksImmediately(ped)
end

local function playVictimReaction(tool)
    if not tool then return end

    if tool.victimAnim then
        local ped = PlayerPedId()
        local anim = tool.victimAnim
        local length = anim.duration or tool.duration or 4000

        local dict, clip, variantFlag, variantDuration = resolveAnimation(anim)
        if dict then
            if not clip then
                print('[mrc_torture] Falta el clip configurado para la animación de la víctima.')
                return
            end
            length = anim.duration or variantDuration or tool.duration or 4000
            TaskPlayAnim(ped, dict, clip, 8.0, -8.0, length, variantFlag or anim.flag or 49, 0.0, false, false, false)
        else
            local references = {}
            if anim.variants then
                for _, variant in ipairs(anim.variants) do
                    references[#references+1] = tostring(variant.dict)
                end
            else
                local animDict = anim.dict
                if type(animDict) == 'table' then
                    for _, entry in ipairs(animDict) do
                        references[#references+1] = tostring(entry)
                    end
                else
                    references[#references+1] = tostring(anim.dict)
                end
            end
            print(('[mrc_torture] No se pudo cargar el diccionario de animación de la víctima (%s)'):format(table.concat(references, ', ')))
        end

        if ActiveScene and ActiveScene.role == 'victim' then
            CreateThread(function()
                Wait(length)
                if ActiveScene and ActiveScene.role == 'victim' then
                    playBaseVictimAnim(ActiveScene.spotId)
                end
            end)
        end
    elseif ActiveScene and ActiveScene.role == 'victim' then
        playBaseVictimAnim(ActiveScene.spotId)
    end
end

local function playTorturerAnim(tool)
    if not tool or not tool.anim then return end
    local ped = PlayerPedId()
    local anim = tool.anim

    local dict, clip, variantFlag, variantDuration = resolveAnimation(anim)
    if dict then
        if not clip then
            print('[mrc_torture] Falta el clip configurado para la animación del torturador.')
            return
        end
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, tool.duration or variantDuration or -1, variantFlag or anim.flag or 49, 0.0, false, false, false)
    else
        local references = {}
        if anim.variants then
            for _, variant in ipairs(anim.variants) do
                references[#references+1] = tostring(variant.dict)
            end
        else
            local animDict = anim.dict
            if type(animDict) == 'table' then
                for _, entry in ipairs(animDict) do
                    references[#references+1] = tostring(entry)
                end
            else
                references[#references+1] = tostring(anim.dict)
            end
        end
        print(('[mrc_torture] No se pudo cargar el diccionario de animación del torturador (%s)'):format(table.concat(references, ', ')))
    end
end

local function handleToolProp(tool)
    clearToolProp()
    if not tool or not tool.prop then return end

    if not requestModel(tool.prop.model) then
        return
    end

    local ped = PlayerPedId()
    local modelHash = joaat(tool.prop.model)
    local prop = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
    if not DoesEntityExist(prop) then
        return
    end

    local boneIndex = GetPedBoneIndex(ped, tool.prop.bone or 57005)
    AttachEntityToEntity(prop, ped, boneIndex, tool.prop.pos.x, tool.prop.pos.y, tool.prop.pos.z, tool.prop.rot.x, tool.prop.rot.y, tool.prop.rot.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(modelHash)
    CurrentToolProp = prop
end

local function playToolSound(tool)
    if not tool or not tool.sound then return end
    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, tool.sound.name or 'CLICK', tool.sound.reference or 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    ReleaseSoundId(soundId)
end

local function applyScreenEffects(tool)
    if not tool or not tool.effects then return end
    local effects = tool.effects

    if effects.screen and effects.screen.effect then
        local effectName = effects.screen.effect
        local duration = effects.screen.duration or 3000
        AnimpostfxPlay(effectName, duration, false)
        if duration > 0 then
            CreateThread(function()
                Wait(duration)
                AnimpostfxStop(effectName)
            end)
        end
    end

    if effects.shake and effects.shake.amplitude then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', effects.shake.amplitude)
        if effects.shake.duration then
            CreateThread(function()
                Wait(effects.shake.duration)
                StopGameplayCamShaking(true)
            end)
        end
    end
end

RegisterNetEvent('mrc_torture:notify', function(nType, message)
    notify(message, nType)
end)

RegisterNetEvent('mrc_torture:updateSceneState', function(spotId, state)
    ScenesState[spotId] = state
end)

RegisterNetEvent('mrc_torture:startScene', function(spotId, role)
    ActiveScene = {
        spotId = spotId,
        role = role
    }
    disableControlsThread()

    if role == 'victim' then
        attachVictimToChair(spotId)
        notify(translate('scene_victim'), 'inform')
    elseif role == 'torturer' then
        positionTorturer(spotId)
        notify(translate('scene_started'), 'success')
    end
end)

RegisterNetEvent('mrc_torture:stopScene', function(spotId, reason)
    if ActiveScene and ActiveScene.spotId == spotId then
        if ActiveScene.role == 'victim' then
            detachVictim()
            StopGameplayCamShaking(true)
            AnimpostfxStopAll()
            if Config.ScreenFadeDuration > 0 then
                DoScreenFadeOut(250)
                Wait(Config.ScreenFadeDuration)
                DoScreenFadeIn(250)
            end
            if reason and Config.Texts[reason] then
                notify(translate(reason), 'inform')
            else
                notify(translate('victim_released'), 'inform')
            end
        elseif ActiveScene.role == 'torturer' then
            clearToolProp()
            ClearPedTasks(PlayerPedId())
            if reason and Config.Texts[reason] then
                notify(translate(reason), 'inform')
            else
                notify(translate('scene_cancelled'), 'inform')
            end
        end
        ActiveScene = nil
    end
end)

RegisterNetEvent('mrc_torture:performTool', function(spotId, toolName)
    if not ActiveScene or ActiveScene.spotId ~= spotId or ActiveScene.role ~= 'torturer' then
        return
    end

    local tool = Config.Tools[toolName]
    if not tool then return end

    handleToolProp(tool)
    playTorturerAnim(tool)
    playToolSound(tool)
    notify(translate('tool_used', tool.label), 'inform')

    Wait(tool.duration or 4000)
    clearToolProp()
end)

RegisterNetEvent('mrc_torture:receiveTool', function(spotId, toolName)
    if not ActiveScene or ActiveScene.spotId ~= spotId or ActiveScene.role ~= 'victim' then
        return
    end

    local tool = Config.Tools[toolName]
    if not tool then return end

    playVictimReaction(tool)
    playToolSound(tool)
    applyScreenEffects(tool)
    notify(translate('tool_received', tool.label), 'error')
end)

RegisterNetEvent('mrc_torture:applyDamage', function(amount, canKill)
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local health = GetEntityHealth(ped)
    local newHealth = health - (amount or 0)
    if not canKill and newHealth <= 101 then
        newHealth = 101
    end
    SetEntityHealth(ped, math.max(newHealth, 101))
end)

RegisterNetEvent('mrc_torture:askConsent', function(requestId, torturerId, spotId)
    if PendingConsent then
        TriggerServerEvent('mrc_torture:consentResult', requestId, false)
        return
    end

    PendingConsent = requestId

    local torturerName = GetPlayerName(GetPlayerFromServerId(torturerId)) or ('ID %s'):format(torturerId)
    local message = translate('consent_question', torturerName)

    if hasOxLib then
        exports.ox_lib:registerContext({
            id = 'mrc_torture_consent',
            title = message,
            options = {
                {
                    title = translate('consent_accept'),
                    icon = 'fa-solid fa-thumbs-up',
                    onSelect = function()
                        TriggerServerEvent('mrc_torture:consentResult', requestId, true)
                        PendingConsent = nil
                    end
                },
                {
                    title = translate('consent_decline'),
                    icon = 'fa-solid fa-thumbs-down',
                    onSelect = function()
                        TriggerServerEvent('mrc_torture:consentResult', requestId, false)
                        PendingConsent = nil
                    end
                }
            }
        })
        exports.ox_lib:showContext('mrc_torture_consent')
    else
        ensureESX()
        local elements = {
            { label = translate('consent_accept'), value = true },
            { label = translate('consent_decline'), value = false }
        }

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mrc_torture_consent', {
            title = message,
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            TriggerServerEvent('mrc_torture:consentResult', requestId, data.current.value)
            PendingConsent = nil
            menu.close()
        end, function(data, menu)
            TriggerServerEvent('mrc_torture:consentResult', requestId, false)
            PendingConsent = nil
            menu.close()
        end)
    end

    CreateThread(function()
        Wait(Config.ConsentTimeout)
        if PendingConsent == requestId then
            TriggerServerEvent('mrc_torture:consentResult', requestId, false)
            notify(translate('consent_timeout'), 'error')
            PendingConsent = nil
        end
    end)
end)

RegisterNetEvent('mrc_torture:clearConsent', function()
    PendingConsent = nil
end)

RegisterNetEvent('mrc_torture:clientStart', function(spotId)
    local scene = ScenesState[spotId]
    if scene and scene.active then
        notify(translate('already_active'), 'error')
        return
    end

    if ActiveScene and ActiveScene.role == 'victim' then
        notify(translate('you_are_victim'), 'error')
        return
    end

    openPlayerMenu(spotId)
end)

RegisterNetEvent('mrc_torture:openToolMenu', function(spotId)
    openToolMenu(spotId)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for _, entity in pairs(ChairEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    clearToolProp()
    if ActiveScene and ActiveScene.role == 'victim' then
        detachVictim()
    end
end)

CreateThread(function()
    ensureESX()
    if not hasTarget then
        print('[mrc_torture] Este recurso requiere ox_target para funcionar correctamente.')
    end
    buildSpots()
    TriggerServerEvent('mrc_torture:syncState')
end)

CreateThread(function()
    while true do
        if ActiveScene and ActiveScene.role == 'victim' then
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                TriggerServerEvent('mrc_torture:notifyDeath', ActiveScene.spotId)
                Wait(5000)
            end
        end
        Wait(500)
    end
end)

AddEventHandler('esx:onPlayerDeath', function()
    if ActiveScene and ActiveScene.role == 'victim' then
        TriggerServerEvent('mrc_torture:notifyDeath', ActiveScene.spotId)
    end
end)

RegisterCommand('mrc_torture_tools', function()
    if ActiveScene and ActiveScene.role == 'torturer' then
        openToolMenu(ActiveScene.spotId)
    end
end, false)

RegisterKeyMapping('mrc_torture_tools', 'Abrir menú de tortura', 'keyboard', 'K')
