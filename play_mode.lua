local GameMode = {}
GameMode.modeName = "Play Mode"

local gameState = {}

function GameMode:Init()
    gameState.player = {
        px = 30,
        py = 30,
        r = 0,
        thrust = 0,
        orientation = 1,
        sprite = newSpriteSheet(love.graphics.newImage("assets/Submarine-1.png"), 28, 24)
    }
end

function GameMode:HandleKeyReleased(key, scancode, isrepeat)
end

function GameMode:HandleKeyPressed(key, scancode, isrepeat)
end

function GameMode:HandleMousePressed(x, y, button, istouch, presses)
end

function GameMode:HandleMouseReleased(x, y, button, istouch, presses)
end

function GameMode:HandleMouseWheel(x, y)
end

function GameMode:Update(dt)
    if love.keyboard.isDown('w') then
        gameState.player.r = gameState.player.r + 0.1
    end
    if love.keyboard.isDown('s') then
        gameState.player.r = gameState.player.r - 0.1
    end
    if love.keyboard.isDown('a') then
        gameState.player.orientation = 1
    end
    if love.keyboard.isDown('d') then
        gameState.player.orientation = -1
    end

    if love.keyboard.isDown('j') then
        gameState.player.thrust = gameState.player.thrust + 0.1
    end
    if love.keyboard.isDown('k') then
    end

    if gameState.player.r > 0 then
        gameState.player.r = gameState.player.r - 0.05
    elseif gameState.player.r < 0 then
        gameState.player.r = gameState.player.r + 0.05
    end

    gameState.player.px = gameState.player.px - gameState.player.thrust * gameState.player.orientation

    gameState.player.thrust = math.max(0, gameState.player.thrust - 0.01)
end

function GameMode:Draw()
    love.graphics.scale(scale, scale)
    drawSprite(gameState.player.sprite, 1, gameState.player.px, gameState.player.py, gameState.player.r, gameState.player.orientation, 1, 12, 14)
end

function GameMode:TransitionIn()
end

function GameMode:TransitionOut()
end

function GameMode:SetExternalState(globalState, sharedState)
    if sharedState ~= nil then
        sharedStateRef = sharedState
    end
    if globalState ~= nil then
        globalStateRef = globalState
    end
end

return GameMode