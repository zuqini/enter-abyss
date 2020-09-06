require 'camera'
require 'slidable_utils'

local GameMode = {}
GameMode.modeName = "Play Mode"

local worldWidth = resWidth * 20
local worldHeight = resHeight * 5
local parallaxScale = 0.2
local parallaxWorldSizeMultiplier = 1
local foregroundParallaxScale = 1
local parallaxWorldSizeMultiplierForeground = 1

local initialScale = 0.2 * resScale
local startupZoomTimer = 0

local crateWidth, crateHeight = 12, 12
local baseSpriteW, baseSpriteH = 151,74
local baseW, baseH = 150,73
local baseX, baseY = 0 + baseSpriteW / 2, 0 + baseSpriteH / 2
local destinationX, destinationY = 0, 0

local w, h = baseW, baseH
local beamThickness, beamWidth = 5, 57
local doorLength = 18
local doorThickness = 6
local combinedDoorWidth = doorLength * 2
local shelfThickness, shelfLength = 4, 52

local crateColBuffer = {}
local player = {}
local objects = {}
local world = nil
local psystem = nil
local jointLength = 15
local arrowRadius = 20
local fishRange = resWidth * 2

local fishMoveTimer = 1
local disableCollisionTimer = 3

persisting = 0

-- utils -------------------------------------------------------------
local function getAngle(orientation, pitch)
    return -orientation * pitch + (orientation > 0 and math.pi or 0)
end

local function buildBase(centerX, centerY, generateCrates)
    local x, y = centerX - baseSpriteW/2, centerY - baseSpriteH/2

    base = {}
    base.doors = {}
    base.ceil = {}
    base.ground = {}
    base.wall = {}
    base.mid = {}

    for i = 0, 1 do
        base.ceil[i] = {}
        base.ceil[i].body = love.physics.newBody(world, x + i * (beamWidth + combinedDoorWidth) + beamWidth / 2, y + beamThickness / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
        base.ceil[i].shape = love.physics.newRectangleShape(beamWidth, beamThickness)
        base.ceil[i].fixture = love.physics.newFixture(base.ceil[i].body, base.ceil[i].shape) --attach shape to body
        base.ceil[i].fixture:setUserData({
            name = "baseCeil",
            index = i
        })

        base.ground[i] = {}
        base.ground[i].body = love.physics.newBody(world, x + i * (beamWidth + combinedDoorWidth) + beamWidth / 2, y + h - beamThickness / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
        base.ground[i].shape = love.physics.newRectangleShape(beamWidth, beamThickness)
        base.ground[i].fixture = love.physics.newFixture(base.ground[i].body, base.ground[i].shape) --attach shape to body
        base.ground[i].fixture:setUserData({
            name = "baseGround",
            index = i
        })

        base.wall[i] = {}
        base.wall[i].body = love.physics.newBody(world, x + i * (w - beamThickness) + beamThickness / 2, y + h / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
        base.wall[i].shape = love.physics.newRectangleShape(beamThickness, h)
        base.wall[i].fixture = love.physics.newFixture(base.wall[i].body, base.wall[i].shape) --attach shape to body
        base.wall[i].fixture:setUserData({
            name = "baseWall",
            index = i
        })

        base.mid[i] = {}
        base.mid[i].body = love.physics.newBody(world, x + beamThickness + i * (beamWidth + combinedDoorWidth - beamThickness) + shelfLength / 2, y + h / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
        base.mid[i].shape = love.physics.newRectangleShape(shelfLength, shelfThickness)
        base.mid[i].fixture = love.physics.newFixture(base.mid[i].body, base.mid[i].shape) --attach shape to body
        base.mid[i].fixture:setUserData({
            name = "baseMid",
            index = i
        })

        local doors = {}
        for j = 0, 1 do
            doors[j + 1] = {}
            doors[j + 1].spriteIndex = j + 1
            local doorX, doorY = x + beamWidth + j * (doorLength) + doorLength / 2, y + i * (baseSpriteH - doorThickness) + doorThickness / 2
            doors[j + 1].closedX = doorX
            doors[j + 1].openX = x + beamWidth - doorLength / 2 + j * (doorLength * 3)
            doors[j + 1].slidable = {
                x = doorX,
                y = doorY,
                t = 0,
                sourceX = doorX,
                sourceY = doorY,
                targetX = doorX,
                targetY = doorY,
                animationTimeMs = 250,
            }
            doors[j + 1].body = love.physics.newBody(world, doorX, doorY) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
            doors[j + 1].shape = love.physics.newRectangleShape(doorLength, doorThickness)
            doors[j + 1].fixture = love.physics.newFixture(doors[j + 1].body, doors[j + 1].shape) --attach shape to body
            doors[j + 1].fixture:setUserData({
                name = "door",
                isTop = i,
                index = j
            })
        end
        base.doors[i + 1] = doors
    end

    if generateCrates then
        for i = 1, 3 do
            objects.crates[i] = {}
            objects.crates[i].body = love.physics.newBody(world, x + beamWidth + combinedDoorWidth + 0.2 * shelfLength + i * crateWidth, y + h / 2 - crateHeight, "dynamic")
            objects.crates[i].shape = love.physics.newRectangleShape(0, 0, crateWidth, crateHeight)
            objects.crates[i].fixture = love.physics.newFixture(objects.crates[i].body, objects.crates[i].shape, 1) -- A higher density gives it more mass.
            objects.crates[i].fixture:setRestitution(0.1)
            objects.crates[i].fixture:setUserData({
                name = "crate",
                index = i,
                isAttached = false
            })
            objects.crates[i].fixture:setMask(16)
            objects.crates[i].fixture:setCategory(2)
        end
    end

    return base
end

local function getRandomPointOutsidePlayerRange(minRange, maxRange)
    local randomRadius = math.random(minRange, maxRange)
    local randomAngleInDegrees = math.random(1, 360)
    local randomAngle = math.rad(randomAngleInDegrees)
    local x, y = player.body:getX() + randomRadius * math.cos(randomAngle), player.body:getY() + randomRadius * math.sin(randomAngle)
    return x, y
end

-- this is a square range, not a circle range, but it doesn't really matter
local function isOutOfRangeOfPlayer(x, y, range)
    return x < player.body:getX() - range or x > player.body:getX() + range or y < player.body:getY() - range or y > player.body:getY() + range
end

local function createFish(x, y)
    fish = {}
    fish.orientation = -1
    fish.body = love.physics.newBody(world, x, y, "dynamic")
    fish.body:setFixedRotation(true)
    if math.random(1, 2) == 1 then
        -- refactor to enum
        fish.type = "fish"
        fish.shape = love.physics.newRectangleShape(0, 0, 12, 8)
    else
        fish.type = "jelly"
        fish.shape = love.physics.newRectangleShape(0, 0, 7, 10)
    end
    fish.fixture = love.physics.newFixture(fish.body, fish.shape, 1) -- A higher density gives it more mass.
    fish.fixture:setRestitution(0.1)
    fish.fixture:setUserData({
        name = "fish"
    })
    return fish
end

local function replaceFish()
    for i = 1, #objects.fishes do
        if isOutOfRangeOfPlayer(objects.fishes[i].body:getX(), objects.fishes[i].body:getY(), fishRange * 1.5) then
            local x, y = getRandomPointOutsidePlayerRange(fishRange, fishRange * 1.2)
            objects.fishes[i] = createFish(x, y)
        end
    end
end

function GameMode:Init()
    isStartupFinished = false
    camera = cameraInit(0, 0, 1/initialScale, 1/initialScale, 0)
    player = {
        forwardThrust = 60000,
        angularThrust = 0.03,
        pitch = 0,
        orientation = 1,
        animation = newAnimation(love.graphics.newImage("assets/Sub-sheet.png"), 18, 16, 0.5),
        joints = {},
        crates = {},
    }

    love.physics.setMeter(1)
    world = love.physics.newWorld(0, 9.81 * 0.25, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    arrowOpenSprite = newSpriteSheet(love.graphics.newImage("assets/arrow-open.png"), 7, 4)
    arrowFilledSprite = newSpriteSheet(love.graphics.newImage("assets/arrow-fill.png"), 7, 4)

    baseSpriteSheet = newSpriteSheet(love.graphics.newImage("assets/base-2-sheet.png"), baseSpriteW, baseSpriteH)

    --let's create a ball
    player.body = love.physics.newBody(world, 20, 20, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
    player.body:setFixedRotation(true)
    player.shape = love.physics.newCircleShape(8) --the ball's shape has a radius of 12
    player.fixture = love.physics.newFixture(player.body, player.shape, 5) -- Attach fixture to body and give it a density of 1.
    player.fixture:setRestitution(0.2)
    player.fixture:setUserData({
        name = "player"
    })

    --let's create the ground
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, worldWidth/2 * 0.2, worldHeight) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.shape = love.physics.newRectangleShape(worldWidth, 10)
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape) --attach shape to body
    objects.ground.fixture:setUserData({
        name = "ground"
    })

    --let's create a couple blocks to play around with
    crateSprite = newSpriteSheet(love.graphics.newImage("assets/Crate-2.png"), 12, 12)
    objects.crates = {}

    fishSprite = newSpriteSheet(love.graphics.newImage("assets/fish-1.png"), 12, 8)
    jellyFishAnimation = newAnimation(love.graphics.newImage("assets/Jelly-sheet.png"), 7, 10, 0.5)
    objects.fishes = {}
    for i = 1, 64 do
        local scaledWidth, scaledHeight = resWidth * resScale, resHeight * resScale
        local x, y = player.body:getX() - scaledWidth / 2 + math.random(1, scaledWidth), player.body:getY() - scaledHeight / 2 + math.random(1, scaledHeight)
        objects.fishes[i] = createFish(x, y)
    end

    objects.base = buildBase(baseX, baseY, true)

    destinationX, destinationY = math.random(worldWidth * 0.2, worldWidth), math.random(0, worldHeight)
    objects.destination = buildBase(destinationX, destinationY)

    leftDoorSprite = newSpriteSheet(love.graphics.newImage("assets/door-left.png"), 19, 6)
    rightDoorSprite = newSpriteSheet(love.graphics.newImage("assets/door-right.png"), 18, 6)
    background = newSpriteSheet(love.graphics.newImage("assets/currents.png"), 386, 327)

    -- bubbles
    backgroundSprite = newSpriteSheet(love.graphics.newImage("assets/Background-1.png"), 32, 32)
    backgroundBubzSprites = {
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-smol.png"), 2, 2),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz.png"), 4, 4),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-big.png"), 6, 6),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-fat.png"), 16, 16)
    }

    -- note draw bubbles to canvas for performance reasons because we want a lot of bubbles
    -- note2: attempted to start out with few bubbles and dynamically generate bubbles as player moves
    -- however, when player zooms out when there is very few bubbles, the innacurate parallax zooming becomes obvious (2d limitations with parallax implementation)
    -- either remove zoom to dynamically generate bubbles with parallax, or keep zoom and instead just have a lot of bubbles
    backgroundBubzCanvas = {
        love.graphics.newCanvas(parallaxWorldSizeMultiplier * worldWidth * parallaxScale, parallaxWorldSizeMultiplier * worldHeight * parallaxScale),
        love.graphics.newCanvas(parallaxWorldSizeMultiplier * worldWidth * parallaxScale * 2, parallaxWorldSizeMultiplier * worldHeight * parallaxScale * 2),
        love.graphics.newCanvas(parallaxWorldSizeMultiplier * worldWidth * parallaxScale * 3, parallaxWorldSizeMultiplier * worldHeight * parallaxScale * 3)
    }
    for size = 1, #backgroundBubzCanvas do
        love.graphics.setCanvas(backgroundBubzCanvas[size])
        love.graphics.clear()
        for i = 1, 500 do
            local w = worldWidth * parallaxScale * size * parallaxWorldSizeMultiplier
            local h = worldHeight * parallaxScale * size * parallaxWorldSizeMultiplier
            drawSprite(backgroundBubzSprites[size], 1, math.random(1, w), math.random(1, h), 0, 1, 1)
        end
        love.graphics.setCanvas()
    end

    foregroundBubzCanvas = love.graphics.newCanvas(parallaxWorldSizeMultiplierForeground * worldWidth * foregroundParallaxScale, parallaxWorldSizeMultiplierForeground * worldWidth * foregroundParallaxScale)
    love.graphics.setCanvas(foregroundBubzCanvas)
    for i = 1, 2000 do
        local w = worldWidth * foregroundParallaxScale * parallaxWorldSizeMultiplierForeground
        local h = worldHeight * foregroundParallaxScale * parallaxWorldSizeMultiplierForeground
        drawSprite(backgroundBubzSprites[4], 1, math.random(1, w), math.random(1, h), 0, 1, 1)
    end
    love.graphics.setCanvas()

    psystem = love.graphics.newParticleSystem(love.graphics.newImage("assets/bubz.png"), 512)
    psystem:setParticleLifetime(1, 2)
    psystem:setSizes(0.125, 0.25, 0.375, 0.5)
    psystem:setEmissionRate(0)
end

function GameMode:HandleKeyReleased(key, scancode, isrepeat)
end

function GameMode:HandleKeyPressed(key, scancode, isrepeat)
    if key == "k" then
        if #player.joints > 0 and #player.crates > 0 then
            -- release activated, disable collision
            disableCollisionTimer = 0
            local jointToPop = table.remove(player.joints, 1)
            local crateToPop = table.remove(player.crates, 1)
            jointToPop:destroy()

            local crateData = objects.crates[crateToPop.index]
            local userData = crateData.fixture:getUserData()
            userData.isAttached = false
            crateData.fixture:setUserData(userData)

            local xImpulse = -15000 * math.cos(getAngle(player.orientation, player.pitch))
            local yImpulse = -15000 * math.sin(getAngle(player.orientation, player.pitch))
            crateData.body:applyLinearImpulse(xImpulse, yImpulse)

            if #player.joints > 0 and #player.crates > 0 then
                local playerCrate = objects.crates[player.crates[1].index]
                player.joints[1]:destroy()
                player.joints[1] = love.physics.newRopeJoint(player.body, playerCrate.body, player.body:getX(), player.body:getY(), playerCrate.body:getX(), playerCrate.body:getY(), jointLength, false)
            end
        end
    end
end

function GameMode:HandleMousePressed(x, y, button, istouch, presses)
    mouse_x, mouse_y = cameraGetMousePosition(camera)
    print(mouse_x, mouse_y)
end

function GameMode:HandleMouseReleased(x, y, button, istouch, presses)
end

function GameMode:HandleMouseWheel(x, y)
    -- Zoom towards the mouse cursor
    local worldMouseX, worldMouseY = love.mouse.getX() * camera.scaleX + camera.x, love.mouse.getY() * camera.scaleY + camera.y
    -- Zoom towards center
    -- local old_cx = camera.x + (camera.scaleX * love.graphics.getWidth())/2
    -- local old_cy = camera.y + (camera.scaleY * love.graphics.getHeight())/2
    camera.scaleX = clamp(camera.scaleX - y * 0.01, 0.2, 5)
    camera.scaleY = clamp(camera.scaleY - y * 0.01, 0.2, 5)
    local newWorldMouseX, newWorldMouseY = love.mouse.getX() * camera.scaleX + camera.x, love.mouse.getY() * camera.scaleY + camera.y
    -- local new_cx = camera.x + (camera.scaleX * love.graphics.getWidth())/2
    -- local new_cy = camera.y + (camera.scaleY * love.graphics.getHeight())/2
    -- local dx = new_cx - old_cx
    -- local dy = new_cy - old_cy
    local dx = newWorldMouseX - worldMouseX
    local dy = newWorldMouseY - worldMouseY
    camera.x = camera.x - dx
    camera.y = camera.y - dy
end

local function updateDoors(structure, dt)
    for i = 1, #structure.doors do
        for j = 1, #structure.doors[i] do
            local door = structure.doors[i][j]
            local minDistance = love.physics.getDistance( player.fixture, door.fixture )
            for k = 1, #player.crates do
                local playerCrateData = player.crates[#player.crates]
                local playerCrate = objects.crates[playerCrateData.index]
                minDistance = math.min(love.physics.getDistance(playerCrate.fixture, door.fixture), minDistance)
            end
            if minDistance < 20 and door.slidable.targetX ~= door.openX then
                setSlidableTarget(door.slidable, door.openX, door.body:getY())
            elseif minDistance >= 20 and door.slidable.targetX ~= door.closedX then
                setSlidableTarget(door.slidable, door.closedX, door.body:getY())
            end
            updateSlidable(door.slidable, dt, quarticEaseOut)
            door.body:setPosition(door.slidable.x, door.slidable.y)
        end
    end
end

function GameMode:Update(dt)
    world:update(dt) --this puts the world into motion
    psystem:update(dt)
    updateAnimation(player.animation, dt)
    updateAnimation(jellyFishAnimation, dt)
    updateDoors(objects.base, dt)
    updateDoors(objects.destination, dt)
    replaceFish()

    if not isStartupFinished then
        startupZoomTimer = startupZoomTimer + dt
        if startupZoomTimer > 0.01 then
            startupZoomTimer = 0
            camera.scaleX = camera.scaleX * 0.992
            camera.scaleY = camera.scaleY * 0.992
            if camera.scaleX <= 1/resScale then
                camera.scaleX = 1 / resScale
                camera.scaleY = 1 / resScale
                isStartupFinished = true
            end
        end
    end

    -- handle physics collision buffer
    for i = 1, #crateColBuffer do
        -- print("handling collision buffer")
        local crateCol = crateColBuffer[i]
        local crate = objects.crates[crateCol.index]
        crateColBuffer[i] = nil

        local userData = crate.fixture:getUserData()
        if not userData.isAttached then
            userData.isAttached = true
            crate.fixture:setUserData(userData)

            if #player.crates == 0 then
                table.insert(player.joints, love.physics.newRopeJoint(player.body, crate.body, player.body:getX(), player.body:getY(), crate.body:getX(), crate.body:getY(), jointLength, false))
            else
                local playerCrateData = player.crates[#player.crates]
                local playerCrate = objects.crates[playerCrateData.index]
                table.insert(player.joints, love.physics.newRopeJoint(playerCrate.body, crate.body, playerCrate.body:getX(), playerCrate.body:getY(), crate.body:getX(), crate.body:getY(), jointLength, false))
            end
            table.insert(player.crates, crateCol)
        end
    end

    if fishMoveTimer > 0.5 then
        fishMoveTimer = 0
        for i = 1, #objects.fishes do
            local xImpulse = -500 + 100 * math.random(1, 10)
            local yImpulse = -10 * math.random(1, 20)
            objects.fishes[i].body:applyLinearImpulse(xImpulse, yImpulse)
            objects.fishes[i].orientation = xImpulse < 0 and -1 or 1
        end
    end
    fishMoveTimer = fishMoveTimer + dt

    if disableCollisionTimer < 2 then
        player.fixture:setCategory(16)
    else
        player.fixture:setCategory(1)
    end
    disableCollisionTimer = disableCollisionTimer + dt

    cameraSetTargetCenter(camera, player.body:getX(), player.body:getY())
    cameraSetPositionCenter(camera, player.body:getX(), player.body:getY())
 
    --here we are going to create some keyboard events
    if love.keyboard.isDown("d") then --press the right arrow key to push the ball to the right
        player.orientation = 1
    end
    if love.keyboard.isDown("a") then --press the left arrow key to push the ball to the left
        player.orientation = -1
    end
    if love.keyboard.isDown("w") then
        player.pitch = math.min(1, player.pitch + player.angularThrust)
    end
    if love.keyboard.isDown("s") then
        player.pitch = math.max(-1, player.pitch - player.angularThrust)
    end

    if love.keyboard.isDown('j') then
        player.body:applyForce(player.forwardThrust * player.orientation * math.cos(player.pitch), -player.forwardThrust * math.sin(player.pitch))
        local angle = getAngle(player.orientation, player.pitch)
        psystem:setPosition(player.body:getX() + math.cos(angle) * 8, player.body:getY() + math.sin(angle) * 8)
        psystem:setSpeed(10,20)
        psystem:setSpread(3)
        psystem:setDirection(angle)
        psystem:emit(2)
    end

    if player.pitch > 0 then
        player.pitch = player.pitch - 0.005
    elseif player.pitch < 0 then
        player.pitch = player.pitch + 0.005
    end
end

local function drawDoors(structure)
    for i = 1, #structure.doors do
        for j = 1, #structure.doors[i] do
            local door = structure.doors[i][j]
            drawSprite(door.spriteIndex == 1 and leftDoorSprite or rightDoorSprite, 1, door.body:getX(), door.body:getY(), 0, 1, 1, doorLength / 2, doorThickness / 2)
        end
    end
end

function GameMode:Draw()
    -- first scale graphics to current expected scale (resScale)
    -- btw, this is an incorrect approximation of parallax zooming in 2D, need more investigation
    -- for real parallax zooming, we need to simulate camera becoming closer to the scene rather than simply scaling/magnifying
    love.graphics.scale(1/camera.scaleX, 1/camera.scaleY)
        -- background
        -- local translateX, translateY = camera.x * 0.05, camera.y * 0.05
        -- love.graphics.translate(-translateX, -translateY)
        --     drawSprite(background, 1, 0, 0, 0, 1, 1, 0, 0)
        -- love.graphics.translate(translateX, translateY)

        -- bubbles
        for size = 1, #backgroundBubzCanvas do
            local translateX, translateY = camera.x * parallaxScale * size, camera.y * parallaxScale * size
            love.graphics.translate(-translateX, -translateY)
            for i = -10, 100 do
                for j = -10, 100 do
                    love.graphics.draw(backgroundBubzCanvas[size], i * backgroundBubzCanvas[size]:getWidth(), j * backgroundBubzCanvas[size]:getHeight())
                end
            end
            love.graphics.translate(translateX, translateY)
        end
    -- pop for cameraSet to rescale back
    love.graphics.scale(camera.scaleX, camera.scaleY)
    cameraSet(camera)
        -- foreground
        love.graphics.setColor(106/255, 190/255, 48/255) -- set the drawing color to green for the ground
        love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates

        love.graphics.setColor(1,1,1)

        drawDoors(objects.base)
        drawDoors(objects.destination)
        drawSprite(baseSpriteSheet, 1, baseX, baseY, 0, 1, 1, baseSpriteW / 2, baseSpriteH / 2)
        drawSprite(baseSpriteSheet, 1, destinationX, destinationY, 0, 1, 1, baseSpriteW / 2, baseSpriteH / 2)

        -- crate lines
        for i = 1, #player.crates do
            local playerCrateData = player.crates[i]
            local playerCrate = objects.crates[playerCrateData.index]
            love.graphics.setColor(153/255, 229/255, 80/255) -- set the drawing color to green for the line
            if i == 1 then
                love.graphics.line(player.body:getX(), player.body:getY(), playerCrate.body:getX(), playerCrate.body:getY())
            else
                local prevCrate = objects.crates[player.crates[i - 1].index]
                love.graphics.line(playerCrate.body:getX(), playerCrate.body:getY(), prevCrate.body:getX(), prevCrate.body:getY())
            end
        end
        love.graphics.setColor(1,1,1)

        -- crates
        for i = 1, #objects.crates do
            drawSprite(crateSprite, 1, objects.crates[i].body:getX(), objects.crates[i].body:getY(), objects.crates[i].body:getAngle(), 1, 1, 6, 6)
        end

        -- fishes
        for i = 1, #objects.fishes do
            local fish = objects.fishes[i]
            if fish.type == "fish" then
                drawSprite(fishSprite, 1, fish.body:getX(), fish.body:getY(), fish.body:getAngle(), -fish.orientation, 1, 6, 4)
            else
                drawAnimation(jellyFishAnimation, fish.body:getX(), fish.body:getY(), 0, -fish.orientation, 1, 3, 5)
            end
        end

        -- player
        drawAnimation(player.animation, player.body:getX(), player.body:getY(), player.pitch * -player.orientation, -player.orientation, 1, 9, 8)

        -- particles
        love.graphics.draw(psystem, 0, 0)

        -- base glass
        drawSprite(baseSpriteSheet, 2, baseX, baseY, 0, 1, 1, baseSpriteW / 2, baseSpriteH / 2)
        drawSprite(baseSpriteSheet, 2, destinationX, destinationY, 0, 1, 1, baseSpriteW / 2, baseSpriteH / 2)

        -- UI
        local angleToDestination = math.atan2(destinationY - player.body:getY(), destinationX - player.body:getX())
        drawSprite(arrowFilledSprite, 1, player.body:getX() + arrowRadius * math.cos(angleToDestination), player.body:getY() + arrowRadius * math.sin(angleToDestination), angleToDestination + math.pi / 2, 1, 1, 3.5, 2)

        -- arrow to crates
        for i = 1, #objects.crates do
            local crate = objects.crates[i]
            local userData = crate.fixture:getUserData()
            if not userData.isAttached then
                local angleToCrate = math.atan2(crate.body:getY() - player.body:getY(), crate.body:getX() - player.body:getX())
                drawSprite(arrowOpenSprite, 1, player.body:getX() + arrowRadius * math.cos(angleToCrate), player.body:getY() + arrowRadius * math.sin(angleToCrate), angleToCrate + math.pi / 2, 1, 1, 3.5, 2)
            end
        end
        -- debug
        -- for i = 0, 1 do
        --     love.graphics.setColor(0.20, 0.20, 0.20) -- set the drawing color to grey for the blocks
        --     love.graphics.polygon("fill", base.ceil[i].body:getWorldPoints(base.ceil[i].shape:getPoints()))
        --     love.graphics.polygon("fill", base.wall[i].body:getWorldPoints(base.wall[i].shape:getPoints()))
        --     love.graphics.polygon("fill", base.ground[i].body:getWorldPoints(base.ground[i].shape:getPoints()))
        --     love.graphics.polygon("fill", base.mid[i].body:getWorldPoints(base.mid[i].shape:getPoints()))
        -- end
        love.graphics.setColor(1, 1, 1) -- set the drawing color to grey for the blocks
    cameraUnset(camera)

    love.graphics.scale(1/camera.scaleX, 1/camera.scaleY)
        local translateX, translateY = camera.x * foregroundParallaxScale, camera.y * foregroundParallaxScale
        love.graphics.translate(-translateX, -translateY)
            love.graphics.draw(foregroundBubzCanvas, -foregroundBubzCanvas:getWidth() / 2, -foregroundBubzCanvas:getHeight() / 2)
        love.graphics.translate(translateX, translateY)
    love.graphics.scale(camera.scaleX, camera.scaleY)
end

function GameMode:TransitionIn()
    backgroundMusic:play()
end

function GameMode:TransitionOut()
    backgroundMusic:stop()
end

function GameMode:SetExternalState(globalState, sharedState)
    if sharedState ~= nil then
        sharedStateRef = sharedState
    end
    if globalState ~= nil then
        globalStateRef = globalState
    end
end

-- physics callbacks``

function beginContact(a, b, coll)
    x,y = coll:getNormal()
    -- print(a:getUserData().name.." colliding with "..b:getUserData().name.." with a vector normal of: "..x..", "..y)

    if a:getUserData().name == "player" or b:getUserData().name == "player" then
        if a:getUserData().name == "crate" then
            table.insert(crateColBuffer, a:getUserData())
        elseif b:getUserData().name == "crate" then
            table.insert(crateColBuffer, b:getUserData())
        end
    end

end

function endContact(a, b, coll)
    persisting = 0    -- reset since they're no longer touching
    -- print(a:getUserData().name.." uncolliding with "..b:getUserData().name)
end

function preSolve(a, b, coll)
    if persisting == 0 then    -- only say when they first start touching
        -- print(a:getUserData().name.." touching "..b:getUserData().name)
    elseif persisting < 20 then    -- then just start counting
        -- print(" "..persisting)
    end
    persisting = persisting + 1    -- keep track of how many updates they've been touching for
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

return GameMode