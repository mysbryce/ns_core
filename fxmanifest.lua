fx_version 'cerulean'
game 'gta5'

name 'ns_core'
description 'Official core utility functions'
version '1.0.0'
author '999s'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
  '@ox_lib/init.lua'
}

server_scripts {
  'server/init.lua',
  'server/player.lua'
}

dependecies {
  'es_extended',
  'ox_lib'
}

files {
  'lib/client.lua'
}
