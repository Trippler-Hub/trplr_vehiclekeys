fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot & Lenix'
description 'Manages vehicle doors and keys for players to lock/unlock them'
version '1.3.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/function.lua',
}

server_script 'server/main.lua'

ui_page 'NUI/index.html'

files {
    'NUI/index.html',
    'NUI/style.css',
    'NUI/script.js',
    'NUI/images/*',
}
