fx_version 'cerulean'
games { 'gta5' }

author 'YesItsArchie'
description 'QB-Core Black Market'
version '1.0.0'

shared_script 'config.lua'

server_scripts {
  '@qb-core/shared/locale.lua',
  'server/server.lua',
  'server/stock_rotation.lua'
}

client_scripts {
  'client/client.lua'
}

files {
  'html/index.html'
}

lua54 'yes'
