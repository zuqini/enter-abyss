local GameMode = {}
GameMode.modeName = "Main Menu"

-- Maybe don't need to do this if it's a true global
local globalStateRef = {}
local sharedStateRef = {}

function GameMode:Init()
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
end

function GameMode:Draw()
end

function GameMode:TransitionIn()
end

function GameMode:TransitionOut()
end

function GameMode:SetExternalState(globalState, sharedState)
    -- NOTE(ray): Any amount of state that you want to transfer into this mode can be done
    if sharedState ~= nil then
        sharedStateRef = sharedState
    end
    if globalState ~= nil then
        globalStateRef = globalState
    end
end

return GameMode