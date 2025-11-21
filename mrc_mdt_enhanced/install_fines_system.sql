-- ============================================
-- SISTEMA DE MULTAS MEJORADO PARA MRC_MDT
-- Instalación de nuevas tablas
-- ============================================

-- Tabla para almacenar el historial de multas aplicadas
CREATE TABLE IF NOT EXISTS `wsb_mdt_fines` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'Identificador del ciudadano multado',
    `officer_id` VARCHAR(50) NOT NULL COMMENT 'Identificador del oficial que aplicó la multa',
    `officer_name` VARCHAR(100) NOT NULL COMMENT 'Nombre del oficial',
    `charge_id` INT(11) DEFAULT NULL COMMENT 'ID del cargo si es predefinido',
    `charge_title` VARCHAR(255) NOT NULL COMMENT 'Título del cargo/multa',
    `charge_description` TEXT COMMENT 'Descripción del cargo',
    `fine_amount` INT(11) NOT NULL DEFAULT 0 COMMENT 'Cantidad de la multa',
    `jail_time` INT(11) NOT NULL DEFAULT 0 COMMENT 'Tiempo de cárcel en minutos',
    `status` VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT 'Estado: pending, paid, cancelled',
    `incident_id` INT(11) DEFAULT NULL COMMENT 'ID del incidente relacionado',
    `location` VARCHAR(255) DEFAULT NULL COMMENT 'Ubicación donde se aplicó la multa',
    `notes` TEXT COMMENT 'Notas adicionales',
    `metadata` LONGTEXT COMMENT 'Metadata adicional en JSON',
    `created_at` INT(11) NOT NULL COMMENT 'Timestamp de creación',
    `updated_at` INT(11) NOT NULL COMMENT 'Timestamp de última actualización',
    `paid_at` INT(11) DEFAULT NULL COMMENT 'Timestamp de pago',
    PRIMARY KEY (`id`),
    INDEX `idx_citizen_id` (`citizen_id`),
    INDEX `idx_officer_id` (`officer_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_charge_id` (`charge_id`),
    INDEX `idx_incident_id` (`incident_id`),
    INDEX `idx_created_at` (`created_at`),
    FOREIGN KEY (`incident_id`) REFERENCES `wsb_mdt_incidents`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de multas aplicadas';

-- Tabla para almacenar licencias de ciudadanos
CREATE TABLE IF NOT EXISTS `wsb_mdt_licenses` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'Identificador del ciudadano',
    `license_type` VARCHAR(50) NOT NULL COMMENT 'Tipo de licencia: drive, weapon, motorcycle, truck, etc.',
    `license_label` VARCHAR(100) NOT NULL COMMENT 'Etiqueta de la licencia',
    `status` VARCHAR(20) NOT NULL DEFAULT 'active' COMMENT 'Estado: active, suspended, revoked, expired',
    `issued_by` VARCHAR(50) DEFAULT NULL COMMENT 'Oficial que emitió la licencia',
    `issued_by_name` VARCHAR(100) DEFAULT NULL COMMENT 'Nombre del oficial',
    `issued_at` INT(11) NOT NULL COMMENT 'Fecha de emisión',
    `expires_at` INT(11) DEFAULT NULL COMMENT 'Fecha de expiración (NULL = sin expiración)',
    `suspended_until` INT(11) DEFAULT NULL COMMENT 'Suspendida hasta (timestamp)',
    `notes` TEXT COMMENT 'Notas sobre la licencia',
    `metadata` LONGTEXT COMMENT 'Metadata adicional en JSON',
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_citizen_license` (`citizen_id`, `license_type`),
    INDEX `idx_citizen_id` (`citizen_id`),
    INDEX `idx_license_type` (`license_type`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Licencias de ciudadanos';

-- Tabla para almacenar vehículos vinculados a ciudadanos del MDT
-- (Complementa la tabla wsb_mdt_vehicles existente)
CREATE TABLE IF NOT EXISTS `wsb_mdt_citizen_vehicles` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'Identificador del ciudadano propietario',
    `vehicle_id` INT(11) NOT NULL COMMENT 'ID del vehículo en wsb_mdt_vehicles',
    `ownership_type` VARCHAR(50) DEFAULT 'owner' COMMENT 'Tipo: owner, co-owner, registered',
    `registered_at` INT(11) NOT NULL COMMENT 'Fecha de registro',
    `notes` TEXT COMMENT 'Notas sobre la propiedad',
    `metadata` LONGTEXT COMMENT 'Metadata adicional',
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_citizen_vehicle` (`citizen_id`, `vehicle_id`),
    INDEX `idx_citizen_id` (`citizen_id`),
    INDEX `idx_vehicle_id` (`vehicle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Relación ciudadanos-vehículos';

-- Tabla para configuración de tipos de multas predefinidas
CREATE TABLE IF NOT EXISTS `wsb_mdt_fine_templates` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(50) NOT NULL COMMENT 'Categoría: traffic, criminal, administrative',
    `title` VARCHAR(255) NOT NULL COMMENT 'Título de la multa',
    `description` TEXT COMMENT 'Descripción',
    `default_fine` INT(11) NOT NULL DEFAULT 0 COMMENT 'Multa por defecto',
    `default_jail` INT(11) NOT NULL DEFAULT 0 COMMENT 'Tiempo de cárcel por defecto',
    `min_fine` INT(11) DEFAULT 0 COMMENT 'Multa mínima',
    `max_fine` INT(11) DEFAULT NULL COMMENT 'Multa máxima',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Si está activa',
    `created_by` VARCHAR(50) DEFAULT NULL,
    `created_by_name` VARCHAR(100) DEFAULT NULL,
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_category` (`category`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Plantillas de multas predefinidas';

-- Insertar algunas plantillas de multas de ejemplo
INSERT INTO `wsb_mdt_fine_templates` (`category`, `title`, `description`, `default_fine`, `default_jail`, `min_fine`, `max_fine`, `is_active`, `created_at`, `updated_at`) VALUES
('traffic', 'Exceso de Velocidad', 'Conducir por encima del límite de velocidad permitido', 500, 0, 200, 2000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('traffic', 'Conducción Temeraria', 'Conducir de manera peligrosa poniendo en riesgo a otros', 1500, 10, 1000, 5000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('traffic', 'Conducir sin Licencia', 'Operar un vehículo sin licencia válida', 2000, 15, 1500, 3000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('traffic', 'Estacionamiento Ilegal', 'Estacionar en zona prohibida', 300, 0, 100, 500, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('traffic', 'Semáforo en Rojo', 'No detenerse en semáforo en rojo', 750, 0, 500, 1500, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('criminal', 'Posesión de Drogas', 'Posesión de sustancias ilegales', 5000, 30, 3000, 10000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('criminal', 'Robo Menor', 'Robo de propiedad de bajo valor', 2500, 20, 1000, 5000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('criminal', 'Agresión', 'Agresión física a otra persona', 3000, 25, 2000, 7000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('criminal', 'Vandalismo', 'Daño intencional a propiedad pública o privada', 1500, 15, 1000, 4000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('administrative', 'Alteración del Orden Público', 'Comportamiento disruptivo en público', 1000, 5, 500, 2000, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
('administrative', 'Falta de Respeto a la Autoridad', 'Falta de cooperación con oficiales', 800, 10, 500, 1500, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Tabla para notificaciones de multas (opcional, para sistema de notificaciones)
CREATE TABLE IF NOT EXISTS `wsb_mdt_fine_notifications` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `fine_id` INT(11) NOT NULL COMMENT 'ID de la multa',
    `citizen_id` VARCHAR(50) NOT NULL COMMENT 'ID del ciudadano',
    `notification_type` VARCHAR(50) NOT NULL COMMENT 'Tipo: issued, reminder, paid, cancelled',
    `message` TEXT NOT NULL COMMENT 'Mensaje de la notificación',
    `is_read` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Si fue leída',
    `sent_at` INT(11) NOT NULL COMMENT 'Timestamp de envío',
    `read_at` INT(11) DEFAULT NULL COMMENT 'Timestamp de lectura',
    PRIMARY KEY (`id`),
    INDEX `idx_fine_id` (`fine_id`),
    INDEX `idx_citizen_id` (`citizen_id`),
    INDEX `idx_is_read` (`is_read`),
    FOREIGN KEY (`fine_id`) REFERENCES `wsb_mdt_fines`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones de multas';

-- ============================================
-- VISTAS ÚTILES PARA CONSULTAS RÁPIDAS
-- ============================================

-- Vista para multas activas (pendientes)
CREATE OR REPLACE VIEW `view_active_fines` AS
SELECT 
    f.id,
    f.citizen_id,
    c.firstname,
    c.lastname,
    CONCAT(c.firstname, ' ', c.lastname) as citizen_name,
    f.officer_name,
    f.charge_title,
    f.fine_amount,
    f.jail_time,
    f.status,
    f.location,
    f.created_at,
    DATEDIFF(NOW(), FROM_UNIXTIME(f.created_at)) as days_since_issued
FROM wsb_mdt_fines f
LEFT JOIN wsb_mdt_citizens c ON f.citizen_id = c.identifier
WHERE f.status = 'pending'
ORDER BY f.created_at DESC;

-- Vista para historial completo de multas por ciudadano
CREATE OR REPLACE VIEW `view_citizen_fine_history` AS
SELECT 
    f.id,
    f.citizen_id,
    c.firstname,
    c.lastname,
    CONCAT(c.firstname, ' ', c.lastname) as citizen_name,
    f.officer_name,
    f.charge_title,
    f.charge_description,
    f.fine_amount,
    f.jail_time,
    f.status,
    f.location,
    f.created_at,
    f.paid_at,
    CASE 
        WHEN f.status = 'paid' THEN 'Pagada'
        WHEN f.status = 'pending' THEN 'Pendiente'
        WHEN f.status = 'cancelled' THEN 'Cancelada'
        ELSE f.status
    END as status_label
FROM wsb_mdt_fines f
LEFT JOIN wsb_mdt_citizens c ON f.citizen_id = c.identifier
ORDER BY f.created_at DESC;

-- Vista para licencias activas por ciudadano
CREATE OR REPLACE VIEW `view_citizen_licenses` AS
SELECT 
    l.id,
    l.citizen_id,
    c.firstname,
    c.lastname,
    CONCAT(c.firstname, ' ', c.lastname) as citizen_name,
    l.license_type,
    l.license_label,
    l.status,
    l.issued_by_name,
    l.issued_at,
    l.expires_at,
    l.suspended_until,
    CASE 
        WHEN l.status = 'active' AND (l.expires_at IS NULL OR l.expires_at > UNIX_TIMESTAMP()) THEN 'Válida'
        WHEN l.status = 'active' AND l.expires_at <= UNIX_TIMESTAMP() THEN 'Expirada'
        WHEN l.status = 'suspended' THEN 'Suspendida'
        WHEN l.status = 'revoked' THEN 'Revocada'
        ELSE l.status
    END as status_label
FROM wsb_mdt_licenses l
LEFT JOIN wsb_mdt_citizens c ON l.citizen_id = c.identifier
ORDER BY l.citizen_id, l.license_type;

-- ============================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- ============================================

-- Procedimiento para obtener el total de multas pendientes de un ciudadano
DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS `sp_get_citizen_pending_fines_total`(IN p_citizen_id VARCHAR(50))
BEGIN
    SELECT 
        COUNT(*) as total_fines,
        COALESCE(SUM(fine_amount), 0) as total_amount,
        COALESCE(SUM(jail_time), 0) as total_jail_time
    FROM wsb_mdt_fines
    WHERE citizen_id = p_citizen_id AND status = 'pending';
END$$
DELIMITER ;

-- Procedimiento para marcar una multa como pagada
DELIMITER $$
CREATE PROCEDURE IF NOT EXISTS `sp_mark_fine_as_paid`(IN p_fine_id INT)
BEGIN
    UPDATE wsb_mdt_fines
    SET status = 'paid',
        paid_at = UNIX_TIMESTAMP(),
        updated_at = UNIX_TIMESTAMP()
    WHERE id = p_fine_id;
END$$
DELIMITER ;

-- ============================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ============================================

-- Índice compuesto para búsquedas frecuentes
CREATE INDEX idx_citizen_status_date ON wsb_mdt_fines(citizen_id, status, created_at);

-- Índice para búsquedas por oficial
CREATE INDEX idx_officer_date ON wsb_mdt_fines(officer_id, created_at);

-- ============================================
-- TRIGGERS PARA AUDITORÍA
-- ============================================

-- Trigger para actualizar updated_at automáticamente
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS `trg_fines_before_update`
BEFORE UPDATE ON `wsb_mdt_fines`
FOR EACH ROW
BEGIN
    SET NEW.updated_at = UNIX_TIMESTAMP();
END$$
DELIMITER ;

-- Trigger para crear notificación cuando se aplica una multa
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS `trg_fines_after_insert`
AFTER INSERT ON `wsb_mdt_fines`
FOR EACH ROW
BEGIN
    INSERT INTO wsb_mdt_fine_notifications (fine_id, citizen_id, notification_type, message, sent_at)
    VALUES (
        NEW.id,
        NEW.citizen_id,
        'issued',
        CONCAT('Se te ha aplicado una multa: ', NEW.charge_title, ' - $', NEW.fine_amount),
        UNIX_TIMESTAMP()
    );
END$$
DELIMITER ;

-- ============================================
-- VERIFICACIÓN DE INSTALACIÓN
-- ============================================

SELECT 'Instalación completada exitosamente!' as status;
SELECT 'Tablas creadas:' as info;
SELECT TABLE_NAME, TABLE_ROWS 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME LIKE 'wsb_mdt_%'
ORDER BY TABLE_NAME;
