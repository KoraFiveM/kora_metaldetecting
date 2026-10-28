fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_metaldetecting'
author 'qbcore2'
version '3.0.0'
description 'QB metal detecting with qblib minigames and qbskills progression'

dependencies {
    'kora_core',
    'kora_inventory',
    'kora_lib',
    'kora_skills',
}

shared_scripts {
    '@kora_lib/init.lua',
    '@kora_core/init.lua',
    'shared/config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/catalog.lua',
    'client/shop.lua',
}

