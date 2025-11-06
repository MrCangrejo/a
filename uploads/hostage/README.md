# FiveM Hostage Script - REPARADO

Script de rehenes para FiveM completamente funcional y reparado.

## 🔧 Características

- ✅ Someter NPCs con arma
- ✅ Sistema de rehenes con múltiples opciones
- ✅ Comandos para controlar rehenes (seguir, arrodillar, amenazar, liberar)
- ✅ Sistema de alertas policiales
- ✅ Compatible con ESX y QBCore
- ✅ Soporte para ox_lib (opcional)
- ✅ Sistema de notificaciones personalizable
- ✅ Límite de rehenes configurable
- ✅ Sistema de escape de rehenes por distancia

## 📦 Instalación

1. Extrae la carpeta `hostage` en tu directorio de resources
2. Añade `ensure hostage` o `start hostage` en tu `server.cfg`
3. Configura el archivo `cfg.lua` según tu framework

## ⚙️ Configuración

Edita el archivo `cfg.lua`:

```lua
Cfg.Framework = 'esx' -- 'qbcore', 'esx' o 'custom'
Cfg.CustomNotify = true -- Usar notificaciones personalizadas
Cfg.Percentage = 20 -- Probabilidad de alerta policial (%)
Cfg.Language = 'es' -- 'es', 'en', 'it'
Cfg.MaxHostages = 5 -- Máximo de rehenes por jugador
Cfg.DistanceToEscape = 30.0 -- Distancia para que el rehén escape
```

### Teclas por defecto:
- **E (38)**: Someter NPC / Abrir menú de rehén
- **S (149)**: Volver a arrodillar al rehén

## 🎮 Uso

1. **Someter un NPC**: Acércate a un NPC con un arma equipada y presiona `E`
2. **Controlar rehén**: Presiona `E` cerca del rehén para abrir el menú con opciones:
   - **Liberar**: Suelta al rehén
   - **Sígueme**: El rehén te seguirá
   - **Arrodíllate**: El rehén se arrodillará
   - **Amenazar**: Tomas al rehén del cuello con el arma

## 🔌 Compatibilidad con QBCore

Si usas **QBCore**, necesitas modificar el archivo `qb-menu` según las instrucciones en `instalation.md`:

En `qb-menu/client.lua`, reemplaza la función `RegisterNUICallback('clickedButton')` para añadir soporte para `handler`:

```lua
elseif data.params.handler then
    data.params.handler(data.params.args)
```

## 📝 Funciones Personalizables

### Alerta Policial
Edita la función `sendPoliceAlert()` en `cfg.lua` para integrar con tu sistema de alertas:

```lua
function sendPoliceAlert(coords)
    -- Tu código de alerta policial aquí
end
```

### Notificaciones
Si usas `Cfg.CustomNotify = true`, personaliza la función `ShowNotification()`:

```lua
function ShowNotification(msg)
    -- Tu sistema de notificaciones aquí
end
```

### Framework Personalizado
Para frameworks personalizados, configura:

```lua
Cfg.Framework = 'custom'

function GetCoreObject()
    return YOUR_CORE_EXPORT
end
```

## 🐛 Solución de Problemas

### El script no funciona
- Verifica que el archivo `client/npc_hostage.lua` existe
- Revisa la consola F8 para errores
- Asegúrate de tener el framework correcto configurado

### Los rehenes no responden
- Verifica que tienes un arma equipada
- Comprueba que no has alcanzado el límite de rehenes
- Revisa la distancia al NPC (debe ser < 3 metros)

### Errores con el menú
- Si usas QBCore, aplica el parche de `instalation.md`
- Si usas ox_lib, descomenta la línea en `fxmanifest.lua`
- Configura `Cfg.CustomMenu` según tu preferencia

## 📄 Archivos Incluidos

```
hostage/
├── client/
│   └── npc_hostage.lua    # Script principal del cliente
├── cfg.lua                 # Configuración y funciones personalizables
├── fxmanifest.lua         # Manifest del resource
├── instalation.md         # Instrucciones para QBCore
└── README.md              # Este archivo
```

## 🌐 Idiomas Disponibles

- Español (es)
- English (en)
- Italiano (it)

## ⚠️ Notas Importantes

- El script requiere que el jugador tenga un arma equipada para someter NPCs
- Los rehenes escaparán si te alejas más de la distancia configurada
- Existe una probabilidad configurable de alertar a la policía al someter un NPC
- Los NPCs pueden ignorar tu amenaza aleatoriamente (30% de probabilidad)

## 🔄 Cambios Realizados en la Reparación

1. ✅ Creado el archivo faltante `client/npc_hostage.lua`
2. ✅ Implementado sistema completo de rehenes
3. ✅ Añadido sistema de detección de NPCs cercanos
4. ✅ Implementadas todas las funciones (release, follow, kneel, threaten)
5. ✅ Añadido sistema de animaciones
6. ✅ Implementado sistema de escape por distancia
7. ✅ Mejorado el sistema de notificaciones con fallback
8. ✅ Añadida limpieza automática al detener el resource
9. ✅ Implementado contador de rehenes
10. ✅ Añadido soporte completo para ESX y QBCore

## 📞 Soporte

Si encuentras algún problema, verifica:
1. Versión de FiveM actualizada
2. Framework correctamente instalado
3. Configuración en `cfg.lua` correcta
4. Consola F8 para errores específicos

---

**Versión**: 1.0 Reparado
**Autor Original**: Network
**Reparado por**: Blackbox AI
