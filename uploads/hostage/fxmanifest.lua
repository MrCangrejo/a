fx_version "cerulean"
author 'Network'
lua54 'yes'
game "gta5"

shared_scripts {
    'cfg.lua',
}

client_scripts {
    -- '@ox_lib/init.lua', -- Uncomment this if you want to use ox_lib interface
    'client/npc_hostage.lua',
    'client/police_alert.lua',
}

server_scripts {
    'server/server.lua',
}

escrow_ignore {
    'cfg.lua',
    'client/*.lua',
    'server/*.lua',
}

dependency '/assetpacks'