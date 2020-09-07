require 'camera'
require 'utils'
require 'sprite_utils'
require 'mode_manager'

globalState = {}
globalState.mode = ""

-- declaring for clarity
currentMode = nil

resWidth = 160
resHeight= 144
resScale = 1
viewportScale = 1

spriteWidth = 128
spriteHeight = spriteWidth
spriteScale = 0.5
scaledSpriteWidth = spriteWidth * spriteScale

local MainMenu = require 'main_menu_mode'
local PlayMode = require 'play_mode'

function love.load()
    math.randomseed(os.time())
    love.window.setTitle("Enter Abyss")
    love.window.setIcon(love.image.newImageData("assets/icon.png") )
    
    font = love.graphics.newFont("assets/PixelOperator-Bold.ttf", 20)
    font:setFilter( "nearest", "nearest" )
    fontSmall = love.graphics.newFont("assets/PixelOperator.ttf", 10)
    fontSmall:setFilter( "nearest", "nearest" )

    fontUltraSmall = love.graphics.newFont("assets/PixelOperator.ttf", 5)
    fontUltraSmall:setFilter( "nearest", "nearest" )

    love.window.setMode(resWidth * viewportScale, resHeight * viewportScale)
    love.graphics.setDefaultFilter("nearest", "nearest", 0)

    backgroundMusic = love.audio.newSource("assets/the-abyss-2.wav", "stream")
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(0.6)

    RegisterGameMode("Main Menu", MainMenu)
    RegisterGameMode("Play Mode", PlayMode)
    SetCurrentGameMode("Main Menu", nil, true)
end

function love.keyreleased(key, scancode, isrepeat)
    currentMode:HandleKeyReleased(key, scancode, isrepeat)
end

function love.keypressed(key, scancode, isrepeat)
    currentMode:HandleKeyPressed(key, scancode, isrepeat)
    if key == "escape" then
        SetCurrentGameMode("Main Menu")
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    currentMode:HandleMousePressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    currentMode:HandleMouseReleased(x, y, button, istouch, presses)
end

function love.wheelmoved(x, y)
    currentMode:HandleMouseWheel(x, y)
end

function love.update(dt)
    currentMode:Update(dt)
end

function love.draw()
    currentMode:Draw()
end