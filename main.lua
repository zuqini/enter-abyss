require 'camera'
require 'utils'
require 'sprite_utils'
require 'mode_manager'

local MainMenu = require 'main_menu_mode'

globalState = {}
globalState.mode = ""

-- declaring for clarity
currentMode = nil

defaultFont12Pt = love.graphics.newFont(12)
defaultFont14Pt = love.graphics.newFont(14)
defaultFont24Pt = love.graphics.newFont(24)

spriteWidth = 128
spriteHeight = spriteWidth
spriteScale = 0.5
scaledSpriteWidth = spriteWidth * spriteScale

function love.load()
    math.randomseed(os.time())
    RegisterGameMode("Main Menu", MainMenu)
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