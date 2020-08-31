local GameMode = {}
GameMode.modeName = "Main Menu"

--
-- GAME STATE: Main Menu
--

local mainMenuItems = {
    {x=0, y=0, text="Start"},
    {x=0, y=0, text="Experiments"},
    {x=0, y=0, text="Options"},
    {x=0, y=0, text="Quit"},
}

local mainMenuSelectedItemIdx = 0
local mainMenuClickPrimed = false
local mainMenuUsingKeyboard = false

local sharedStateRef = {}

function GameMode:Init()
    for i=1,#mainMenuItems do
        -- Transform into love2d text objects
        mainMenuItems[i].text = love.graphics.newText(defaultFont24Pt, mainMenuItems[i].text)
        mainMenuItems[i].x = love.graphics.getWidth()/2 - mainMenuItems[i].text:getWidth()/2
        mainMenuItems[i].y = love.graphics.getHeight()/2 + i * (mainMenuItems[i].text:getHeight()+10)
    end
end

function GameMode:HandleKeyReleased(key, scancode, isrepeat)
end

function GameMode:HandleKeyPressed(key, scancode, isrepeat)
    if key == "down" then
        mainMenuUsingKeyboard = true
        mainMenuSelectedItemIdx =  mainMenuSelectedItemIdx + 1
        if mainMenuSelectedItemIdx > #mainMenuItems then mainMenuSelectedItemIdx = #mainMenuItems end
    elseif key == "up" then
        mainMenuUsingKeyboard = true
        mainMenuSelectedItemIdx = mainMenuSelectedItemIdx - 1
        if mainMenuSelectedItemIdx <= 0 then mainMenuSelectedItemIdx = 1 end
    elseif key == "return" then
        if mainMenuSelectedItemIdx == 1 then
            SetCurrentGameMode("Play Mode", nil, true)
        elseif mainMenuSelectedItemIdx == 2 then
        elseif mainMenuSelectedItemIdx == 3 then
        elseif mainMenuSelectedItemIdx == 4 then
            love.event.push("quit")
        end
    elseif key == "escape" then
        love.event.push("quit")
    end
end

function GameMode:HandleMousePressed(x, y, button, istouch, presses)
    if mainMenuSelectedItemIdx ~= 0 then
        mainMenuClickPrimed = true
    end
end

function GameMode:HandleMouseReleased(x, y, button, istouch, presses)
    if not mainMenuClickPrimed then return end
    if mainMenuSelectedItemIdx == 1 then
        SetCurrentGameMode("Play Mode", nil, true)
    elseif mainMenuSelectedItemIdx == 2 then
    elseif mainMenuSelectedItemIdx == 3 then
    elseif mainMenuSelectedItemIdx == 4 then
        love.event.push("quit")
    end
    mainMenuClickPrimed = false
end

function GameMode:HandleMouseWheel(x, y)
end

function GameMode:Update(dt)
    local mx, my = love.mouse.getPosition()
    local lastSelectedIdx = mainMenuSelectedItemIdx
    if not mainMenuUsingKeyboard then
        mainMenuSelectedItemIdx = 0
    end
    -- Check if hovering
    for i=1,#mainMenuItems do
        if (mx >=  mainMenuItems[i].x and mx <= mainMenuItems[i].x + mainMenuItems[i].text:getWidth()
            and my >= mainMenuItems[i].y and my <= mainMenuItems[i].y + mainMenuItems[i].text:getHeight())
        then
            mainMenuUsingKeyboard = false
            mainMenuSelectedItemIdx = i
        end
    end
end

function GameMode:Draw()
    love.graphics.setBackgroundColor(0.2,0.2,0.6)
    --love.graphics.draw(logo, love.graphics.getWidth()/2 - logo:getWidth()/2, love.graphics.getHeight() * 0.25)
    love.graphics.setColor(1, 1, 1, 1)
    for i=1,#mainMenuItems do
        love.graphics.draw(mainMenuItems[i].text, mainMenuItems[i].x, mainMenuItems[i].y)
    end
    if mainMenuSelectedItemIdx ~= 0 then
        love.graphics.rectangle("line",
            mainMenuItems[mainMenuSelectedItemIdx].x,
            mainMenuItems[mainMenuSelectedItemIdx].y,
            mainMenuItems[mainMenuSelectedItemIdx].text:getWidth(),
            mainMenuItems[mainMenuSelectedItemIdx].text:getHeight()
        )
    end
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