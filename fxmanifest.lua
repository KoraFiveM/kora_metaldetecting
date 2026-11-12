fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_metaldetecting'
author 'qbcore2'
version '0.2.0'
description 'Kora metal detecting with kora_lib minigames and kora_skills progression'

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


-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
