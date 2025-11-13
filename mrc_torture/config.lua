Config = {}

--\n-- CONFIGURACIÓN GENERAL\n-- Ajusta libremente estos valores para adaptar el recurso a tu servidor.\n--\nConfig.Locale = 'es'

-- Permisos: si AllowEveryone es false, solo los jobs listados podrán iniciar torturas.
Config.AllowEveryone = false
Config.AllowedJobs = { 'police', 'mafia' } -- Añade más jobs si lo necesitas.

-- Si es true, la víctima debe aceptar la tortura mediante un menú de confirmación.
Config.RequireVictimConsent = true
Config.ConsentTimeout = 15000 -- Tiempo máximo (ms) para que la víctima responda.

-- Distancias y rangos
Config.InteractionDistance = 3.0 -- Distancia máxima para seleccionar a un jugador cercano.
Config.SpotRange = 4.0 -- Distancia máxima para validar que ambos jugadores están junto al punto.

-- Control de uso
Config.SceneCooldown = 60 -- Segundos de cooldown para volver a iniciar una sesión tras finalizar.
Config.ToolCooldown = 5000 -- Milisegundos de cooldown entre usos de herramientas.
Config.DisableVictimControls = true -- Bloquea controles básicos mientras la víctima está atada.
Config.KeepTorturerStill = false -- Si quieres evitar que el torturador se mueva durante la animación.

-- Integraciones opcionales
Config.StressEvent = nil -- Ejemplo: 'qs-core:server:addStress'. Si es nil no se dispara ningún evento.

-- Configuración de blips generales (puedes sobrescribir por punto)
Config.DefaultBlip = {
    enabled = true,
    sprite = 52,
    colour = 1,
    scale = 0.8,
    name = 'Sala de interrogatorio'
}

--\n-- PUNTOS DE TORTURA\n-- Para añadir nuevos puntos, copia la estructura de la tabla y cambia las coordenadas/modelos.\n-- coords: vector3 de la silla.\n-- heading: rotación principal de la silla.\n-- chairProp: modelo de la silla a spawn.\n-- victimOffset: ajuste de posición de la víctima respecto al centro de la silla.\n-- torturerOffset: posición relativa donde se coloca el torturador.\n-- victimRotation: rotación adicional para la víctima (útil cuando el prop no está alineado).\n-- scenario: texto descriptivo para identificar el interior/escena.\n-- blip: configuración individual del punto (si se omite, usa Config.DefaultBlip).\n--\nConfig.TortureSpots = {
    {
        label = 'Almacén abandonado',
        coords = vec3(963.34, -122.16, 74.35),
        heading = 180.0,
        chairProp = 'prop_torture_chair',
        victimOffset = vec3(0.0, 0.0, 0.0),
        victimRotation = vec3(0.0, 0.0, 180.0),
        torturerOffset = vec3(0.0, -1.2, 0.0),
        scenario = 'Hangar industrial',
        blip = {
            enabled = true,
            sprite = 480,
            colour = 1,
            scale = 0.75,
            name = 'Zona de interrogatorios'
        }
    }
}

--\n-- HERRAMIENTAS DE TORTURA\n-- Copia cualquier entrada y cámbiala para crear nuevas herramientas.\n-- name: identificador único (clave de la tabla).\n-- label: texto que se mostrará al torturador.\n-- duration: duración total de la animación (ms).\n-- anim: animación del torturador (dict, clip y flag).\n-- victimAnim: animación de reacción de la víctima (dict, clip, flag, duration opcional).\n-- prop: modelo opcional que se adjuntará a la mano del torturador (bone y offsets).\n-- effects: tabla de efectos aplicados a la víctima (daño, estrés, pantalla, cámara, etc.).\n-- sound: sonido opcional que se reproducirá para ambos jugadores.\n--\nConfig.Tools = {
    alicates = {
        label = 'Alicates',
        duration = 6000,
        icon = 'fa-solid fa-screwdriver-wrench',
        anim = { dict = 'anim@heists@humane_labs@finale@keycards@heistkeycard@', clip = 'exit_loop', flag = 49 },
        victimAnim = { dict = 'anim@heists@ornate_bank@hostages@ped_c@', clip = 'flinch_loop', flag = 49, duration = 3500 },
        prop = { model = 'prop_tool_screwdvr01', bone = 60309, pos = vec3(0.05, 0.02, -0.02), rot = vec3(90.0, 0.0, 90.0) },
        effects = {
            health = { amount = 12, canKill = false },
            stress = { amount = 15 },
            screen = { effect = 'CamPushInNeutral', duration = 3000 },
            shake = { amplitude = 0.4, duration = 3000 }
        },
        sound = { name = 'PINCH', reference = 'DLC_TG_Running_SoundSet' }
    },
    porra = {
        label = 'Porra eléctrica',
        duration = 5000,
        icon = 'fa-solid fa-bolt',
        anim = { dict = 'anim@mp_player_intmenu@key_fob@', clip = 'fob_click', flag = 49 },
        victimAnim = { dict = 'random@arrests', clip = 'generic_radio_chatter', flag = 49, duration = 2500 },
        prop = { model = 'w_pi_stungun', bone = 57005, pos = vec3(0.12, 0.02, -0.02), rot = vec3(0.0, 90.0, 0.0) },
        effects = {
            health = { amount = 8, canKill = false },
            screen = { effect = 'Dont_tazeme_bro', duration = 4000 },
            shake = { amplitude = 0.6, duration = 4000 }
        },
        sound = { name = 'Taser_Spark', reference = 'DLC_PRISON_BREAK_HEIST_SOUNDS' }
    },
    llave = {
        label = 'Llave inglesa',
        duration = 5500,
        icon = 'fa-solid fa-hammer',
        anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_front_takedown', flag = 48 },
        victimAnim = { dict = 'anim@heists@ornate_bank@hostages@ped_m@', clip = 'flinch_loop', flag = 49, duration = 4000 },
        prop = { model = 'prop_cs_wrench', bone = 60309, pos = vec3(0.1, 0.0, 0.0), rot = vec3(0.0, 90.0, 0.0) },
        effects = {
            health = { amount = 18, canKill = false },
            stress = { amount = 20 },
            shake = { amplitude = 0.8, duration = 4000 }
        },
        sound = { name = 'WEAPON_CLUB_HIT', reference = 'RESIDENT_WEAPONS_HAND_GUN_SOUNDSET' }
    }
}

--\n-- Texto de notificaciones/menús. Puedes modificarlo sin afectar la lógica.\n--\nConfig.Texts = {
    start_title = 'Iniciar tortura',
    start_description = 'Selecciona a una víctima cercana.',
    no_players = 'No hay jugadores cercanos para torturar.',
    already_active = 'Ya hay una sesión activa en esta silla.',
    no_permission = 'No tienes permiso para usar este lugar de tortura.',
    consent_question = '¿Aceptar tortura de %s?',
    consent_accept = 'Aceptar',
    consent_decline = 'Rechazar',
    consent_timeout = 'No respondiste a tiempo.',
    scene_started = 'Has iniciado una sesión de tortura.',
    scene_victim = 'Has sido atado a la silla. Mantén la calma.',
    scene_denied = 'La víctima ha rechazado la tortura.',
    scene_busy = 'Esa persona ya está involucrada en otra sesión.',
    victim_too_far = 'La víctima no está lo suficientemente cerca de la silla.',
    cooldown = 'Debes esperar unos segundos antes de iniciar otra sesión.',
    tool_cooldown = 'Debes esperar antes de usar otra herramienta.',
    tool_menu = 'Herramientas de tortura',
    tool_used = 'Aplicaste %s sobre la víctima.',
    tool_received = 'Están usando %s contra ti.',
    scene_finished = 'La víctima ha sido liberada.',
    scene_cancelled = 'La sesión de tortura ha terminado.',
    victim_released = 'Has sido liberado.',
    victim_disconnected = 'La sesión se canceló porque un participante se desconectó.',
    victim_dead = 'La sesión se canceló porque la víctima murió.',
    you_are_victim = 'No puedes iniciar torturas mientras eres víctima.',
    same_target = 'No puedes torturarte a ti mismo.'
}

--\n-- Animaciones base para la víctima mientras está atada.\n--\nConfig.BaseVictimAnim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_crouch_spraying_02_inspector', flag = 1 }

-- Ajustes visuales adicionales.
Config.ScreenFadeDuration = 1000 -- ms para el fade al liberar.
