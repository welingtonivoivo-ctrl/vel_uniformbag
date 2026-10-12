fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'street_uniformbag'
author 'Street Roleplay'
description 'Sistema de Bolsas de Uniformes do Street Roleplay'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locale.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

-- Obrigatórias (TRD §1). Opcionais (mri_Qadmin, ps-dispatch, mri_Qbossmenu,
-- mri_Qinteract) são verificadas em tempo de execução, sem impedir a subida.
dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'ox_inventory',
    'mri_Qappearance',
}
