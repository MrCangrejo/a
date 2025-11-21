-- ============================================
-- CLASE FINES - SISTEMA DE MULTAS MEJORADO
-- Maneja la lógica de multas para MRC MDT
-- ============================================

Fines = {}

-- Constructor de la clase Fines
function Fines:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

-- ============================================
-- FUNCIONES PARA OBTENER PLANTILLAS DE MULTAS
-- ============================================

-- Obtener todas las plantillas de multas disponibles
function Fines:GetFineTemplates()
    local templates = MySQL.query.await('SELECT * FROM wsb_mdt_fine_templates ORDER BY category, title')
    return templates or {}
end

-- Obtener plantillas por categoría
function Fines:GetFineTemplatesByCategory(category)
    local templates = MySQL.query.await('SELECT * FROM wsb_mdt_fine_templates WHERE category = ? ORDER BY title', {category})
    return templates or {}
end

-- ============================================
-- FUNCIONES PARA APLICAR MULTAS
-- ============================================

-- Aplicar multa a un ciudadano
function Fines:ApplyFine(citizenId, officerId, officerName, chargeData)
    -- Validar parámetros
    if not citizenId or not officerId or not chargeData then
        return false, "Parámetros inválidos"
    end

    -- Obtener información del oficial
    local officer = MRC.GetPlayerById(officerId)
    if not officer then
        return false, "Oficial no encontrado"
    end

    -- Preparar datos de la multa
    local fineData = {
        citizen_id = citizenId,
        officer_id = officerId,
        officer_name = officerName,
        charge_title = chargeData.title or "Multa personalizada",
        charge_description = chargeData.description or "",
        fine_amount = chargeData.amount or 0,
        jail_time = chargeData.jail_time or 0,
        charge_id = chargeData.id or nil,
        applied_date = os.date('%Y-%m-%d %H:%M:%S')
    }

    -- Insertar multa en la base de datos
    local result = MySQL.insert.await('INSERT INTO wsb_mdt_fines SET ?', fineData)

    if result then
        -- Notificar al jugador multado
        self:NotifyPlayer(citizenId, fineData)

        -- Integrar con sistema de facturación (ESX/QBCore)
        self:BillPlayer(citizenId, fineData)

        return true, "Multa aplicada correctamente", result
    else
        return false, "Error al registrar la multa en la base de datos"
    end
end

-- ============================================
-- FUNCIONES PARA OBTENER HISTORIAL DE MULTAS
-- ============================================

-- Obtener historial completo de multas de un ciudadano
function Fines:GetCitizenFineHistory(citizenId)
    if not citizenId then return {} end

    local history = MySQL.query.await([[
        SELECT
            f.*,
            DATE_FORMAT(f.applied_date, '%d/%m/%Y %H:%i') as formatted_date
        FROM wsb_mdt_fines f
        WHERE f.citizen_id = ?
        ORDER BY f.applied_date DESC
    ]], {citizenId})

    return history or {}
end

-- Obtener multas activas (no pagadas) de un ciudadano
function Fines:GetActiveFines(citizenId)
    if not citizenId then return {} end

    local activeFines = MySQL.query.await([[
        SELECT
            f.*,
            DATE_FORMAT(f.applied_date, '%d/%m/%Y %H:%i') as formatted_date
        FROM wsb_mdt_fines f
        WHERE f.citizen_id = ? AND f.paid = 0
        ORDER BY f.applied_date DESC
    ]], {citizenId})

    return activeFines or {}
end

-- Obtener multas pagadas de un ciudadano
function Fines:GetPaidFines(citizenId)
    if not citizenId then return {} end

    local paidFines = MySQL.query.await([[
        SELECT
            f.*,
            DATE_FORMAT(f.applied_date, '%d/%m/%Y %H:%i') as formatted_date
        FROM wsb_mdt_fines f
        WHERE f.citizen_id = ? AND f.paid = 1
        ORDER BY f.applied_date DESC
    ]], {citizenId})

    return paidFines or {}
end

-- ============================================
-- FUNCIONES PARA GESTIÓN DE MULTAS
-- ============================================

-- Marcar multa como pagada
function Fines:MarkFineAsPaid(fineId, officerId)
    if not fineId then return false end

    local result = MySQL.update.await('UPDATE wsb_mdt_fines SET paid = 1, paid_date = NOW(), paid_by = ? WHERE id = ?',
        {officerId, fineId})

    return result > 0
end

-- Eliminar multa (solo administradores)
function Fines:DeleteFine(fineId)
    if not fineId then return false end

    local result = MySQL.query.await('DELETE FROM wsb_mdt_fines WHERE id = ?', {fineId})
    return result > 0
end

-- ============================================
-- FUNCIONES DE INTEGRACIÓN CON FRAMEWORKS
-- ============================================

-- Notificar al jugador sobre la multa
function Fines:NotifyPlayer(citizenId, fineData)
    local player = MRC.GetPlayerByCitizenId(citizenId)
    if not player then return end

    local notification = {
        title = "🏛️ POLICÍA - Multa Recibida",
        description = string.format("Has recibido una multa de $%d por: %s", fineData.fine_amount, fineData.charge_title),
        type = "error",
        duration = 10000
    }

    -- Enviar notificación según el framework
    if MRC.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', player.source, notification.description)
    elseif MRC.Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', player.source, notification.description, 'error', 10000)
    end

    -- Mostrar multa en pantalla
    TriggerClientEvent('mrc_mdt:client:ShowFineNotification', player.source, fineData)
end

-- Facturar al jugador usando el sistema del framework
function Fines:BillPlayer(citizenId, fineData)
    local player = MRC.GetPlayerByCitizenId(citizenId)
    if not player then return end

    if MRC.Framework == 'esx' then
        -- Usar ESX billing system
        local xPlayer = ESX.GetPlayerFromId(player.source)
        if xPlayer then
            xPlayer.removeAccountMoney('bank', fineData.fine_amount)
            -- Registrar en sociedad policial si existe
        end
    elseif MRC.Framework == 'qbcore' then
        -- Usar QBCore billing system
        local Player = QBCore.Functions.GetPlayer(player.source)
        if Player then
            Player.Functions.RemoveMoney('bank', fineData.fine_amount, "Police Fine: " .. fineData.charge_title)
        end
    end
end

-- ============================================
-- FUNCIONES ESTADÍSTICAS
-- ============================================

-- Obtener estadísticas de multas por oficial
function Fines:GetOfficerStats(officerId, days)
    days = days or 30

    local stats = MySQL.query.await([[
        SELECT
            COUNT(*) as total_fines,
            SUM(fine_amount) as total_amount,
            AVG(fine_amount) as avg_amount
        FROM wsb_mdt_fines
        WHERE officer_id = ? AND applied_date >= DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {officerId, days})

    return stats and stats[1] or {total_fines = 0, total_amount = 0, avg_amount = 0}
end

-- Obtener estadísticas generales
function Fines:GetGeneralStats(days)
    days = days or 30

    local stats = MySQL.query.await([[
        SELECT
            COUNT(*) as total_fines,
            SUM(fine_amount) as total_revenue,
            COUNT(DISTINCT citizen_id) as citizens_fined,
            COUNT(DISTINCT officer_id) as active_officers
        FROM wsb_mdt_fines
        WHERE applied_date >= DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})

    return stats and stats[1] or {total_fines = 0, total_revenue = 0, citizens_fined = 0, active_officers = 0}
end

-- ============================================
-- FUNCIONES DE VALIDACIÓN
-- ============================================

-- Validar datos de multa antes de aplicar
function Fines:ValidateFineData(fineData)
    if not fineData.citizen_id then
        return false, "ID de ciudadano requerido"
    end

    if not fineData.officer_id then
        return false, "ID de oficial requerido"
    end

    if not fineData.charge_title or fineData.charge_title == "" then
        return false, "Título del cargo requerido"
    end

    if not fineData.fine_amount or fineData.fine_amount < 0 then
        return false, "Monto de multa inválido"
    end

    return true, "Datos válidos"
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Crear instancia global de la clase
MRC.Fines = Fines:new()

print("^2[MRC MDT] ^7Clase Fines cargada correctamente")