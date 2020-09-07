local GameMode = {}
GameMode.modeName = "Main Menu"

--
-- GAME STATE: Main Menu
--

function GameMode:Init()
    menuSprite = newSpriteSheet(love.graphics.newImage("assets/Start Page.png"), 160, 144)
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
    love.graphics.setColor(255,255,255)
    drawSprite(menuSprite, 1, 0, 0, 0, 1, 1, 0, 0)
    love.graphics.setColor(255,255,255)
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