fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbmetaldetecting'
author 'qbcore2'
version '3.0.0'
description 'QB metal detecting with qblib minigames and qbskills progression'

dependencies {
    'qb-core',
    'qblib',
    'qbskills',
}

shared_scripts {
    '@qblib/init.lua',
    '@qbcore/init.lua',
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

files {
    'stream/bostra_detector.ytyp',
    'items/images/*.png',
}

data_file 'DLC_ITYP_REQUEST' 'stream/bostra_detector.ytyp'
