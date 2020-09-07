local GameMode = {}
GameMode.modeName = "Main Menu"

--
-- GAME STATE: Main Menu
--

function GameMode:Init()
    menuSprite = newSpriteSheet(love.graphics.newImage("assets/Start Page.png"), 160, 144)
    mainMenuCanvas = love.graphics.newCanvas(160, 144)
end

function GameMode:HandleKeyReleased(key, scancode, isrepeat)
end

function GameMode:HandleKeyPressed(key, scancode, isrepeat)
    if key == "j" then
        SetCurrentGameMode("Play Mode", nil, true)
    elseif key == "k" then
        love.event.push("quit")
    end
end

function GameMode:HandleMousePressed(x, y, button, istouch, presses)
    
end

function GameMode:HandleMouseReleased(x, y, button, istouch, presses)
    
end

function GameMode:HandleMouseWheel(x, y)
end

function GameMode:Update(dt)
    
end

function GameMode:Draw()
    love.graphics.setCanvas(mainMenuCanvas)
    love.graphics.clear()
    love.graphics.setBackgroundColor(55/255,148/255,110/255)
    love.graphics.setColor(1,1,1,1)
    drawSprite(menuSprite, 1, 0, 0, 0, 1, 1, 0, 0)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas()
    love.graphics.scale(viewportScale, viewportScale)
    love.graphics.draw(mainMenuCanvas)
    love.graphics.scale(1/viewportScale, 1/viewportScale)
    love.graphics.setBackgroundColor(55/255,148/255,110/255)
    love.graphics.setColor(1,1,1,1)
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