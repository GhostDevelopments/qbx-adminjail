fx_version 'cerulean'
game 'gta5'

description 'Admin Jail for QBox'
version '1.0.0'
author 'Ghost Developments'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'qbx_core',
    'oxmysql',
    'ox_lib'
}

lua54 'yes'