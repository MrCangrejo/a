# 📋 ANÁLISIS COMPLETO - MRC MDT (Police Database System)

## 🔍 RESUMEN EJECUTIVO

**Script Analizado:** mrc_mdt v1.0.5  
**Tipo:** Sistema de Base de Datos Policial para FiveM  
**Framework:** Compatible con ESX y QBCore  
**Base de Datos:** MySQL (oxmysql)  

---

## 📊 ESTRUCTURA ACTUAL DEL SISTEMA

### 1. **ARQUITECTURA GENERAL**

El script está dividido en tres capas principales:

```
mrc_mdt/
├── client/          # Lógica del lado del cliente
├── server/          # Lógica del lado del servidor
│   ├── classes/     # Clases OOP para entidades
│   └── main.lua     # Controlador principal
├── config/          # Configuración
├── web/             # Interfaz UI (React/Vue)
└── locales/         # Traducciones
```

### 2. **SISTEMA DE CLASES (OOP)**

El script utiliza un sistema orientado a objetos con las siguientes entidades:

#### **Entidades Principales:**

| Clase | Tabla SQL | Función Principal |
|-------|-----------|-------------------|
| `MDTCitizen` | `wsb_mdt_citizens` | Gestión de ciudadanos registrados |
| `MDTVehicle` | `wsb_mdt_vehicles` | Registro de vehículos |
| `MDTWeapon` | `wsb_mdt_weapons` | Registro de armas |
| `MDTProperty` | `wsb_mdt_properties` | Registro de propiedades |
| `MDTIncident` | `wsb_mdt_incidents` | Reportes policiales |
| `MDTCharge` | `wsb_mdt_charges` | Cargos/Multas disponibles |
| `MDTWarrant` | `wsb_mdt_warrants` | Órdenes de arresto |
| `MDTBOLO` | `wsb_mdt_bolos` | Alertas BOLO |
| `MDTEvidence` | `wsb_mdt_evidence` | Evidencias |
| `MDTPhoto` | `wsb_mdt_photos` | Fotos/Screenshots |
| `MDTNote` | `wsb_mdt_notes` | Notas |
| `MDTCamera` | `wsb_mdt_cameras` | Cámaras de seguridad |
| `MDTAnnouncement` | `wsb_mdt_announcements` | Anuncios departamentales |
| `MDTDispatch` | En memoria | Sistema de despacho en tiempo real |

---

## 🗄️ ESTRUCTURA DE BASE DE DATOS

### **Tabla: `wsb_mdt_citizens`**
```sql
CREATE TABLE `wsb_mdt_citizens` (
    `identifier` VARCHAR(50) PRIMARY KEY,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `dob` VARCHAR(20) DEFAULT 'Unknown',
    `phone` VARCHAR(20) DEFAULT 'Unknown',
    `gender` VARCHAR(10) DEFAULT 'other',
    `job` VARCHAR(50) DEFAULT NULL,
    `job_grade` INT(11) DEFAULT 0,
    `fingerprint` VARCHAR(50) NOT NULL,
    `metadata` LONGTEXT,
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL,
    INDEX `idx_name` (`firstname`, `lastname`),
    INDEX `idx_fingerprint` (`fingerprint`)
);
```

### **Tabla: `wsb_mdt_incidents`**
```sql
CREATE TABLE `wsb_mdt_incidents` (
    `id` INT(11) AUTO_INCREMENT PRIMARY KEY,
    `incident_number` VARCHAR(20) UNIQUE NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `location` VARCHAR(255),
    `status` VARCHAR(20) DEFAULT 'open',
    `primary_citizen` VARCHAR(50) DEFAULT NULL,
    `created_by` VARCHAR(50) NOT NULL,
    `created_by_name` VARCHAR(100) NOT NULL,
    `closed_by` VARCHAR(50) DEFAULT NULL,
    `closed_by_name` VARCHAR(100) DEFAULT NULL,
    `total_fine` INT(11) DEFAULT 0,
    `total_jail_time` INT(11) DEFAULT 0,
    `fine_reduction` INT(11) DEFAULT 0,
    `jail_reduction` INT(11) DEFAULT 0,
    `manual_fine` TINYINT(1) DEFAULT 0,
    `manual_jail` TINYINT(1) DEFAULT 0,
    `max_fine` INT(11) DEFAULT NULL,
    `max_jail` INT(11) DEFAULT NULL,
    `metadata` LONGTEXT,
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL,
    `closed_at` INT(11) DEFAULT NULL,
    INDEX `idx_incident_number` (`incident_number`),
    INDEX `idx_status` (`status`),
    INDEX `idx_primary_citizen` (`primary_citizen`)
);
```

### **Tabla: `wsb_mdt_charges`**
```sql
CREATE TABLE `wsb_mdt_charges` (
    `id` INT(11) AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT,
    `jail_time` INT(11) DEFAULT 0,
    `fine` INT(11) DEFAULT 0,
    `category` VARCHAR(50) DEFAULT 'misdemeanor',
    `created_by` VARCHAR(50),
    `created_by_name` VARCHAR(100),
    `created_at` INT(11) NOT NULL,
    `updated_at` INT(11) NOT NULL
);
```

### **Tabla: `wsb_mdt_entity_links`**
```sql
CREATE TABLE `wsb_mdt_entity_links` (
    `id` INT(11) AUTO_INCREMENT PRIMARY KEY,
    `from_type` VARCHAR(50) NOT NULL,
    `from_id` VARCHAR(50) NOT NULL,
    `to_type` VARCHAR(50) NOT NULL,
    `to_id` VARCHAR(50) NOT NULL,
    `linked_by` VARCHAR(50),
    `metadata` LONGTEXT,
    `created_at` INT(11) NOT NULL,
    INDEX `idx_from` (`from_type`, `from_id`),
    INDEX `idx_to` (`to_type`, `to_id`)
);
```

---

## ⚙️ FUNCIONALIDADES ACTUALES

### **1. Sistema de Ciudadanos**
- ✅ Registro de ciudadanos en el MDT
- ✅ Búsqueda por nombre, identificador, teléfono, huella
- ✅ Vinculación con vehículos, armas, propiedades
- ✅ Fotos/Avatar
- ✅ Notas
- ✅ Historial de incidentes

### **2. Sistema de Incidentes**
- ✅ Creación de reportes policiales
- ✅ Vinculación de cargos (charges)
- ✅ Cálculo automático de multas y tiempo de cárcel
- ✅ Vinculación de ciudadanos, vehículos, evidencias
- ✅ Notas en incidentes
- ✅ Estados: abierto/cerrado

### **3. Sistema de Cargos (Charges)**
- ✅ Base de datos de cargos predefinidos
- ✅ Categorías: misdemeanor, felony, infraction
- ✅ Multa y tiempo de cárcel por cargo
- ✅ Búsqueda de cargos
- ✅ Creación/edición/eliminación (con permisos)

### **4. Sistema de Órdenes (Warrants)**
- ✅ Creación de órdenes de arresto
- ✅ Vinculación con ciudadanos
- ✅ Estados: activo/servido/cancelado
- ✅ Vinculación de cargos a órdenes

### **5. Sistema de Vehículos**
- ✅ Registro de vehículos en MDT
- ✅ Búsqueda por matrícula
- ✅ Vinculación con propietarios
- ✅ Marcado de vehículos (flagged)
- ✅ Fotos de vehículos

### **6. Sistema de Armas**
- ✅ Registro de armas
- ✅ Número de serie
- ✅ Vinculación con propietarios
- ✅ Marcado de armas

### **7. Sistema de Evidencias**
- ✅ Registro de evidencias
- ✅ Check-in/Check-out
- ✅ Ubicación de almacenamiento
- ✅ Vinculación con incidentes

### **8. Sistema de Despacho**
- ✅ Alertas en tiempo real
- ✅ Tipos de despacho configurables
- ✅ Botón de pánico
- ✅ Alertas automáticas (disparos, robo de vehículos)
- ✅ HUD de despacho

### **9. Sistema de Cámaras**
- ✅ Colocación de cámaras CCTV
- ✅ Visualización de cámaras
- ✅ Gestión por departamento
- ✅ Múltiples modelos de cámaras

### **10. Sistema de Permisos**
- ✅ Permisos por departamento
- ✅ Permisos por rango/grado
- ✅ Permisos granulares (crear, editar, eliminar)

---

## 🔗 SISTEMA DE VINCULACIÓN (LinkManager)

El script utiliza un sistema avanzado de vinculación de entidades:

```lua
MDTLinkManager.createLink(fromType, fromId, toType, toId, linkedBy, metadata)
```

**Ejemplo:**
- Vincular un cargo a un incidente
- Vincular un ciudadano a un incidente
- Vincular evidencia a un incidente
- Vincular vehículos a BOLOs

---

## 🎯 CALLBACKS Y EVENTOS PRINCIPALES

### **Callbacks del Servidor:**
```lua
wsb.registerCallback("mrc_mdt:openMDT")
wsb.registerCallback("mrc_mdt:citizenAction")
wsb.registerCallback("mrc_mdt:vehicleAction")
wsb.registerCallback("mrc_mdt:incidentAction")
wsb.registerCallback("mrc_mdt:chargeAction")
wsb.registerCallback("mrc_mdt:warrantAction")
wsb.registerCallback("mrc_mdt:searchPlayers")
wsb.registerCallback("mrc_mdt:searchVehicles")
wsb.registerCallback("mrc_mdt:globalSearch")
```

### **Eventos Personalizables:**
```lua
-- Cuando se vincula un cargo a un ciudadano
AddEventHandler('mrc_mdt:onChargeLinked', function(chargeData, primaryIdentifier, incidentData, officerData, adjustments)
    -- Aquí puedes integrar con tu sistema de facturación
    -- Aquí puedes integrar con tu sistema de cárcel
end)

-- Cuando se desvincula un cargo
AddEventHandler('mrc_mdt:onChargeUnlinked', function(chargeData, primaryIdentifier, incidentData, officerData)
    -- Aquí puedes reembolsar multas
end)
```

---

## 🔧 INTEGRACIÓN CON FRAMEWORKS

### **ESX:**
```lua
-- Obtiene jugadores de la base de datos ESX
SELECT identifier, firstname, lastname, dateofbirth, phone_number, sex, job, job_grade
FROM users
WHERE LOWER(CONCAT(firstname, ' ', lastname)) LIKE ?
```

### **QBCore:**
```lua
-- Obtiene jugadores de la base de datos QBCore
SELECT citizenid, JSON_EXTRACT(charinfo, '$.firstname') as firstname,
       JSON_EXTRACT(charinfo, '$.lastname') as lastname,
       JSON_EXTRACT(charinfo, '$.birthdate') as birthdate
FROM players
WHERE LOWER(CONCAT(JSON_EXTRACT(charinfo, '$.firstname'), ' ', JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ?
```

---

## 📸 SISTEMA DE FOTOS

Utiliza **FiveManage API** para almacenar screenshots:
- API Key configurada en `server/opensource.lua`
- Integración con `screenshot-basic`
- Almacenamiento en la nube
- Vinculación de fotos a entidades

---

## 🚨 PUNTOS IMPORTANTES

### **✅ Fortalezas:**
1. Sistema OOP bien estructurado
2. Separación clara de responsabilidades
3. Sistema de permisos robusto
4. Vinculación flexible de entidades
5. Compatible con ESX y QBCore
6. Sistema de búsqueda eficiente
7. Interfaz web moderna (React/Vue)
8. Sistema de despacho en tiempo real

### **⚠️ Limitaciones Actuales:**
1. **NO hay búsqueda de jugadores en tiempo real desde la tablet**
2. **NO hay ficha completa del jugador con:**
   - Vehículos que posee
   - Licencias actuales
   - Historial de multas
   - Multas activas
3. **NO hay sistema para aplicar multas directamente desde la tablet**
4. **NO hay integración automática con sistemas de facturación**

---

## 🎯 CONCLUSIÓN

El script `mrc_mdt` es un sistema **profesional y completo** de base de datos policial. Está bien estructurado, utiliza buenas prácticas de programación y es altamente extensible.

**Sin embargo**, le faltan las funcionalidades específicas que solicitaste:
- Búsqueda de jugadores en tiempo real
- Ficha completa del jugador
- Sistema de aplicación de multas desde la tablet

Estas funcionalidades serán **agregadas en la siguiente fase** sin modificar el sistema existente.

---

## 📝 NOTAS TÉCNICAS

- **Bridge System:** Utiliza `mrc_bridge` para abstracción de frameworks
- **Callbacks:** Sistema de callbacks asíncronos con `wsb.registerCallback`
- **Timestamps:** Utiliza `os.time()` (Unix timestamp)
- **JSON:** Almacena metadata en formato JSON en campos LONGTEXT
- **Índices:** Tablas optimizadas con índices para búsquedas rápidas

---

**Fecha de Análisis:** 21 de Noviembre, 2025  
**Analista:** Blackbox AI Assistant  
**Estado:** ✅ Análisis Completo
