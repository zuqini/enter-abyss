require 'camera'
require 'slidable_utils'

local GameMode = {}
GameMode.modeName = "Play Mode"

local worldWidth = resWidth * 3
local worldHeight = resHeight * 3
local parallaxScale = 0.2
local foregroundParallaxScale = 3

local crateColBuffer = {}
local player = {}
local objects = {}
local world = nil
local psystem = nil
local jointLength = 15

local fishMoveTimer = 1
local disableCollisionTimer = 3

persisting = 0

-- utils
local function getAngle(orientation, pitch)
    return -orientation * pitch + (orientation > 0 and math.pi or 0)
end

local function buildBase(x, y)
    local w, h = 128,64
    local beamThickness = 3
    local doorHeight = 32
    local shelfLength = 68
    local shelfThickness = 2

    base = {}
    base.ceil = {}
    base.ceil.body = love.physics.newBody(world, x + w / 2, y + beamThickness / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    base.ceil.shape = love.physics.newRectangleShape(w, beamThickness)
    base.ceil.fixture = love.physics.newFixture(base.ceil.body, base.ceil.shape) --attach shape to body
    base.ceil.fixture:setUserData({
        name = "baseCeil"
    })
    base.lWall = {}
    base.lWall.body = love.physics.newBody(world, x + beamThickness / 2, y + h / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    base.lWall.shape = love.physics.newRectangleShape(beamThickness, h)
    base.lWall.fixture = love.physics.newFixture(base.lWall.body, base.lWall.shape) --attach shape to body
    base.lWall.fixture:setUserData({
        name = "baseLeftWall"
    })
    base.rWall = {}
    -- refactor to variables for clarity
    base.rWall.body = love.physics.newBody(world, x + w - beamThickness / 2, y + doorHeight / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    base.rWall.shape = love.physics.newRectangleShape(beamThickness, doorHeight)
    base.rWall.fixture = love.physics.newFixture(base.rWall.body, base.rWall.shape) --attach shape to body
    base.rWall.fixture:setUserData({
        name = "baseRightWall"
    })
    base.mid = {}
    base.mid.body = love.physics.newBody(world, x + beamThickness + shelfLength / 2, y + h / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    base.mid.shape = love.physics.newRectangleShape(shelfLength, shelfThickness)
    base.mid.fixture = love.physics.newFixture(base.mid.body, base.mid.shape) --attach shape to body
    base.mid.fixture:setUserData({
        name = "baseMid"
    })
    base.ground = {}
    base.ground.body = love.physics.newBody(world, x + w / 2, y + h - beamThickness / 2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    base.ground.shape = love.physics.newRectangleShape(w, beamThickness)
    base.ground.fixture = love.physics.newFixture(base.ground.body, base.ground.shape) --attach shape to body
    base.ground.fixture:setUserData({
        name = "baseGround"
    })
    return base
end

function GameMode:Init()
    camera = cameraInit(0, 0, 1/resScale, 1/resScale, 0)
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

    baseSpriteSheet = newSpriteSheet(love.graphics.newImage("assets/base-sheet.png"), 128, 64)

    --let's create a ball
    player.body = love.physics.newBody(world, 100, 32, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
    player.body:setFixedRotation(true)
    player.shape = love.physics.newCircleShape(8) --the ball's shape has a radius of 12
    player.fixture = love.physics.newFixture(player.body, player.shape, 5) -- Attach fixture to body and give it a density of 1.
    player.fixture:setRestitution(0.2)
    player.fixture:setUserData({
        name = "player"
    })

    objects.base = buildBase(0, 0)

    --let's create the ground
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, worldWidth/2, worldHeight/2 + 40) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.shape = love.physics.newRectangleShape(worldWidth, 10)
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape) --attach shape to body
    objects.ground.fixture:setUserData({
        name = "ground"
    })

    --let's create a couple blocks to play around with
    crateSprite = newSpriteSheet(love.graphics.newImage("assets/Crate-2.png"), 12, 12)
    objects.crates = {}
    
    for i = 1, 5 do
        objects.crates[i] = {}
        objects.crates[i].body = love.physics.newBody(world, worldWidth/2 + 16 * i, worldHeight/2, "dynamic")
        objects.crates[i].shape = love.physics.newRectangleShape(0, 0, 12, 12)
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

    fishSprite = newSpriteSheet(love.graphics.newImage("assets/fish-1.png"), 12, 8)
    jellyFishAnimation = newAnimation(love.graphics.newImage("assets/Jelly-sheet.png"), 7, 10, 0.5)
    objects.fishes = {}
    for i = 1, 64 do
        objects.fishes[i] = {}
        objects.fishes[i].orientation = -1
        objects.fishes[i].body = love.physics.newBody(world, math.random(1, worldWidth), math.random(1, worldHeight), "dynamic")
        objects.fishes[i].body:setFixedRotation(true)
        if math.random(1, 2) == 1 then
            -- refactor to enum
            objects.fishes[i].type = "fish"
            objects.fishes[i].shape = love.physics.newRectangleShape(0, 0, 12, 8)
        else
            objects.fishes[i].type = "jelly"
            objects.fishes[i].shape = love.physics.newRectangleShape(0, 0, 7, 10)
        end
        objects.fishes[i].fixture = love.physics.newFixture(objects.fishes[i].body, objects.fishes[i].shape, 1) -- A higher density gives it more mass.
        objects.fishes[i].fixture:setRestitution(0.1)
        objects.fishes[i].fixture:setUserData({
            name = "fish"
        })
    end

    backgroundSprite = newSpriteSheet(love.graphics.newImage("assets/Background-1.png"), 32, 32)
    backgroundBubzSprites = {
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-smol.png"), 2, 2),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz.png"), 4, 4),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-big.png"), 6, 6),
        newSpriteSheet(love.graphics.newImage("assets/back-bubz-fat.png"), 16, 16)
    }
    backgroundBubz = {}
    for i = 1, 4000 do
        local bub = {}
        -- consider adding physics
        bub.size = math.random(1, 3)
        local w = worldWidth * parallaxScale * bub.size * 10
        local h = worldHeight * parallaxScale * bub.size * 10
        bub.px = - w/2 + math.random(1, w)
        bub.py = - h/2 + math.random(1, h)
        table.insert(backgroundBubz, bub)
    end

    foregroundBubz = {}
    for i = 1, 4000 do
        local bub = {}
        -- consider adding physics
        bub.size = 4
        local w = worldWidth * foregroundParallaxScale * 10
        local h = worldHeight * foregroundParallaxScale * 10
        bub.px = - w/2 + math.random(1, w)
        bub.py = - h/2 + math.random(1, h)
        table.insert(foregroundBubz, bub)
    end

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
end

function GameMode:HandleMouseReleased(x, y, button, istouch, presses)
end

function GameMode:HandleMouseWheel(x, y)
end

function GameMode:Update(dt)
    world:update(dt) --this puts the world into motion
    psystem:update(dt)
    updateAnimation(player.animation, dt)
    updateAnimation(jellyFishAnimation, dt)

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

    -- for i = 1, #backgroundBubz do
    --     backgroundBubz[i].py = backgroundBubz[i].py - 0.05
    -- end

    -- for i = 1, #foregroundBubz do
    --     foregroundBubz[i].py = foregroundBubz[i].py - 0.05
    -- end

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

    if love.mouse.isDown(1) then
        mouse_x, mouse_y = cameraGetMousePosition(camera)
        print(mouse_x, mouse_y)
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

function GameMode:Draw()
    love.graphics.scale(1/camera.scaleX, 1/camera.scaleY)
        -- background
        love.graphics.translate(-camera.x * parallaxScale, -camera.y * parallaxScale)
            love.graphics.setColor(1,1,1)

            -- background image
            -- for i = 1, math.ceil(worldWidth / 32) do
            --     for j = 1, math.ceil(worldHeight / 32) do
            --         drawSprite(backgroundSprite, 1, (i - 1) * 32, (j - 1) * 32, 0, 1, 1, 16, 16)
            --     end
            -- end
        love.graphics.translate(camera.x * parallaxScale, camera.y * parallaxScale)

        --bubbles
        for i = 1, #backgroundBubz do
            love.graphics.translate(-camera.x * parallaxScale * backgroundBubz[i].size, -camera.y * parallaxScale * backgroundBubz[i].size)
                drawSprite(backgroundBubzSprites[backgroundBubz[i].size], 1, backgroundBubz[i].px, backgroundBubz[i].py, 0, 1, 1)
            love.graphics.translate(camera.x * parallaxScale * backgroundBubz[i].size, camera.y * parallaxScale * backgroundBubz[i].size)
        end
    love.graphics.scale(camera.scaleX, camera.scaleY)
    cameraSet(camera)
        -- foreground
        love.graphics.setColor(106/255, 190/255, 48/255) -- set the drawing color to green for the ground
        love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates

        love.graphics.setColor(1,1,1)

        drawSprite(baseSpriteSheet, 1, 64, 32, 0, 1, 1, 64, 32)

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

        drawSprite(baseSpriteSheet, 2, 64, 32, 0, 1, 1, 64, 32)

        -- love.graphics.setColor(1,0,0)
        -- love.graphics.circle("fill", 0, 0, 20)
    cameraUnset(camera)

    love.graphics.scale(1/camera.scaleX, 1/camera.scaleY)
        -- foreground
        love.graphics.setColor(1,1,1)
        for i = 1, #foregroundBubz do
            love.graphics.translate(-camera.x * foregroundParallaxScale, -camera.y * foregroundParallaxScale)
                drawSprite(backgroundBubzSprites[foregroundBubz[i].size], 1, foregroundBubz[i].px, foregroundBubz[i].py, 0, 1, 1)
            love.graphics.translate(camera.x * foregroundParallaxScale, camera.y * foregroundParallaxScale)
        end
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