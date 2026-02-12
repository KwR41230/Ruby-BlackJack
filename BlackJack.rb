require 'tty-prompt'
require 'json'

require_relative 'lib/color'
require_relative 'lib/card'
require_relative 'lib/deck'
require_relative 'lib/hand'
require_relative 'lib/player'
require_relative 'lib/game'

Game.new.main_menu
