fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vel_uniformbag'
author 'Vel'
description 'Sistema de Bolsas de Uniformes para servidores FiveM (QBox)'
version '0.4.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locale.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db/schema.lua',
    'server/db/migrations.lua',
    'server/utils.lua',
    'server/permissions.lua',
    'server/appearance.lua',
    'server/uniforms.lua',
    'server/bags.lua',
    'server/locks.lua',
    'server/ground.lua',
    'server/stashes.lua',
    'server/ustash.lua',
    'server/supply.lua',
    'server/issue.lua',
    'server/alerts.lua',
    'server/change.lua',
    'server/panel.lua',
    'server/recovery.lua',
    'server/points.lua',
    'server/discord.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/appearance.lua',
    'client/bag.lua',
    'client/ground.lua',
    'client/panel.lua',
    'client/alerts.lua',
    'client/recovery.lua',
    'client/points.lua',
    'client/ustash.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/panel.css',
    'web/panel.js',
    'web/plugin.html',
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
