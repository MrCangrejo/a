-- ============================================
-- SISTEMA DE BÚSQUEDA DE JUGADORES - MRC MDT
-- Funcionalidad de búsqueda en tiempo real
-- ============================================

-- Variables locales
local isSearching = false
local searchResults = {}
local currentSearchQuery = ""

-- Función para abrir la interfaz de búsqueda
function OpenPlayerSearch()
    if not hasPermission() then return end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openSearch",
        data = {
            results = searchResults,
            query = currentSearchQuery
        }
    })
end

-- Función para realizar búsqueda
function PerformPlayerSearch(query)
    if isSearching then return end
    if not query or query == "" then
        searchResults = {}
        SendNUIMessage({
            action = "updateSearchResults",
            data = searchResults
        })
        return
    end

    isSearching = true
    currentSearchQuery = query

    -- Mostrar loading
    SendNUIMessage({
        action = "searchLoading",
        data = true
    })

    -- Enviar búsqueda al servidor
    TriggerServerEvent('mrc_mdt:searchPlayers', query)
end

-- Evento para recibir resultados de búsqueda
RegisterNetEvent('mrc_mdt:searchResults')
AddEventHandler('mrc_mdt:searchResults', function(results)
    isSearching = false
    searchResults = results or {}

    -- Ocultar loading y mostrar resultados
    SendNUIMessage({
        action = "searchLoading",
        data = false
    })

    SendNUIMessage({
        action = "updateSearchResults",
        data = searchResults
    })
end)

-- Función para seleccionar un jugador de los resultados
function SelectPlayerFromSearch(citizenId)
    if not citizenId then return end

    -- Abrir ficha completa del jugador
    OpenPlayerProfile(citizenId)
end

-- Función para limpiar búsqueda
function ClearPlayerSearch()
    searchResults = {}
    currentSearchQuery = ""
    SendNUIMessage({
        action = "clearSearch"
    })
end

-- Eventos NUI para búsqueda
RegisterNUICallback('searchPlayers', function(data, cb)
    PerformPlayerSearch(data.query)
    cb('ok')
end)

RegisterNUICallback('selectPlayer', function(data, cb)
    SelectPlayerFromSearch(data.citizenId)
    cb('ok')
end)

RegisterNUICallback('clearSearch', function(data, cb)
    ClearPlayerSearch()
    cb('ok')
end)

RegisterNUICallback('closeSearch', function(data, cb)
    SetNuiFocus(false, false)
    ClearPlayerSearch()
    cb('ok')
end)

-- Exportar funciones para uso en otros archivos
exports('OpenPlayerSearch', OpenPlayerSearch)
exports('PerformPlayerSearch', PerformPlayerSearch)
exports('ClearPlayerSearch', ClearPlayerSearch)