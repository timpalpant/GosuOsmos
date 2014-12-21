$LOAD_PATH << File.expand_path('.')
require 'game_window'

$DEBUG = true
FULLSCREEN = false

if FULLSCREEN
	SCREEN_WIDTH = Gosu.screen_width
	SCREEN_HEIGHT = Gosu.screen_height
else
	SCREEN_WIDTH = 800
	SCREEN_HEIGHT = 600
end

window = GameWindow.new(SCREEN_WIDTH, SCREEN_HEIGHT, FULLSCREEN)
window.show