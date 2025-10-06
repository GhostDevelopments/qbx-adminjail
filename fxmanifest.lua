fx_version 'cerulean'
game 'gta5'

description 'Admin Jail Script for QBox'
version '1.0.0'
author 'Ghost Developments'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qbx_core',
    'oxmysql',
    'ox_lib'
}

lua54 'yes'
