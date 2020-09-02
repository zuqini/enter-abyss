require 'camera'
require 'slidable_utils'

local GameMode = {}
GameMode.modeName = "Play Mode"

local worldWidth = resWidth * 3
local worldHeight = resHeight * 3
local parallaxScale = 0.2

local crateColBuffer = {}
local player = {}
local objects = {}
local world = nil
local psystem = nil

local fishMoveTimer = 1

persisting = 0

-- utils
local function getAngle(orientation, pitch)
    return -orientation * pitch + (orientation > 0 and math.pi or 0)
end

function GameMode:Init()
    camera = cameraInit(resWidth, resHeight, 0, 0, 1, 1, 0)
    backgroundSprite = newSpriteSheet(love.graphics.newImage("assets/Background-1.png"), 32, 32)
    player = {
        forwardThrust = 60000 * 5,
        angularThrust = 0.03,
        pitch = 0,
        orientation = 1,
        animation = newAnimation(love.graphics.newImage("assets/Sub-sheet.png"), 18, 16, 0.5),
        sprite = newSpriteSheet(love.graphics.newImage("assets/Submarine-smol-2.png"), 18, 16),
        joints = {},
        crates = {},
    }

    love.physics.setMeter(1)
    world = love.physics.newWorld(0, 9.81 * 0.25, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)

    --let's create a ball
    player.body = love.physics.newBody(world, worldWidth/2, worldHeight/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
    player.body:setFixedRotation(true)
    player.shape = love.physics.newCircleShape(8) --the ball's shape has a radius of 12
    player.fixture = love.physics.newFixture(player.body, player.shape, 10) -- Attach fixture to body and give it a density of 1.
    player.fixture:setRestitution(0.9)
    player.fixture:setUserData({
        name = "player"
    })

    --let's create the ground
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, worldWidth/2, worldHeight/2 + 40) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.shape = love.physics.newRectangleShape(worldWidth, 10)
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape) --attach shape to body
    objects.ground.fixture:setUserData({
        name = "ground"
    })

    objects.ceil = {}
    objects.ceil.body = love.physics.newBody(world, worldWidth/2, 40) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ceil.shape = love.physics.newRectangleShape(worldWidth, 10)
    objects.ceil.fixture = love.physics.newFixture(objects.ceil.body, objects.ceil.shape) --attach shape to body
    objects.ceil.fixture:setUserData({
        name = "ceil"
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
    end

    fishSprite = newSpriteSheet(love.graphics.newImage("assets/fish-1.png"), 12, 8)
    objects.fishes = {}
    for i = 1, 32 do
        objects.fishes[i] = {}
        objects.fishes[i].orientation = -1
        objects.fishes[i].body = love.physics.newBody(world, math.random(1, worldWidth), math.random(1, worldHeight), "dynamic")
        objects.fishes[i].body:setFixedRotation(true)
        objects.fishes[i].shape = love.physics.newRectangleShape(0, 0, 12, 8)
        objects.fishes[i].fixture = love.physics.newFixture(objects.fishes[i].body, objects.fishes[i].shape, 1) -- A higher density gives it more mass.
        objects.fishes[i].fixture:setRestitution(0.1)
        objects.fishes[i].fixture:setUserData({
            name = "fish"
        })
    end

    psystem = love.graphics.newParticleSystem(love.graphics.newImage("assets/bubz.png"), 512)
    psystem:setParticleLifetime(1, 2)
    psystem:setSizes(0.125, 0.25, 0.375, 0.5)
    psystem:setEmissionRate(0)
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
    world:update(dt) --this puts the world into motion
    psystem:update(dt)
    updateAnimation(player.animation, dt)

    -- handle physics collision buffer
    for i = 1, #crateColBuffer do
        print("handling collision buffer")
        local crateCol = crateColBuffer[i]
        local crate = objects.crates[crateCol.index]
        crateColBuffer[i] = nil

        local userData = crate.fixture:getUserData()
        if not userData.isAttached then
            userData.isAttached = true
            crate.fixture:setUserData(userData)

            if #player.crates == 0 then
                table.insert(player.joints, love.physics.newRopeJoint(player.body, crate.body, player.body:getX(), player.body:getY(), crate.body:getX(), crate.body:getY(), 20, false))
            else
                local playerCrateData = player.crates[#player.crates]
                local playerCrate = objects.crates[playerCrateData.index]
                table.insert(player.joints, love.physics.newRopeJoint(playerCrate.body, crate.body, playerCrate.body:getX(), playerCrate.body:getY(), crate.body:getX(), crate.body:getY(), 20, false))
            end
            table.insert(player.crates, crateCol)
        end
    end

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
    if love.keyboard.isDown('k') then
    end

    if player.pitch > 0 then
        player.pitch = player.pitch - 0.005
    elseif player.pitch < 0 then
        player.pitch = player.pitch + 0.005
    end

    if fishMoveTimer > 0.5 then
        fishMoveTimer = 0
        for i = 1, #objects.fishes do
            local xForce = -50000 + 10000 * math.random(1, 10)
            local yForce = -1000 * math.random(1, 10)
            objects.fishes[i].body:applyForce(xForce, yForce)
            objects.fishes[i].orientation = xForce < 0 and -1 or 1
        end
    end
    fishMoveTimer = fishMoveTimer + dt
end

function GameMode:Draw()
    love.graphics.scale(resScale, resScale)

    -- background
    love.graphics.translate(-camera.x * parallaxScale, -camera.y * parallaxScale)
        love.graphics.setColor(1,1,1)
        for i = 1, math.ceil(worldWidth / 32) do
            for j = 1, math.ceil(worldHeight / 32) do
                drawSprite(backgroundSprite, 1, (i - 1) * 32, (j - 1) * 32, 0, 1, 1, 16, 16)
            end
        end
    love.graphics.translate(camera.x * parallaxScale, camera.y * parallaxScale)

    cameraSet(camera)
        -- foreground
        love.graphics.setColor(106/255, 190/255, 48/255) -- set the drawing color to green for the ground
        love.graphics.polygon("fill", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates
        love.graphics.polygon("fill", objects.ceil.body:getWorldPoints(objects.ceil.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates

        love.graphics.setColor(1,1,1)
        -- crates
        for i = 1, #objects.crates do
            drawSprite(crateSprite, 1, objects.crates[i].body:getX(), objects.crates[i].body:getY(), objects.crates[i].body:getAngle(), 1, 1, 6, 6)
        end

        -- fishes
        for i = 1, #objects.fishes do
            drawSprite(fishSprite, 1, objects.fishes[i].body:getX(), objects.fishes[i].body:getY(), objects.fishes[i].body:getAngle(), -objects.fishes[i].orientation, 1, 6, 4)
        end

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

        -- player
        love.graphics.setColor(1,1,1)
        drawAnimation(player.animation, player.body:getX(), player.body:getY(), player.pitch * -player.orientation, -player.orientation, 1, 9, 8)
        --drawSprite(player.sprite, 1, player.body:getX(), player.body:getY(), player.pitch * -player.orientation, -player.orientation, 1, 9, 8)

        -- particles
        love.graphics.draw(psystem, 0, 0)
    cameraUnset(camera)

    --love.graphics.setColor(0.76, 0.18, 0.05) --set the drawing color to red for the ball
    --love.graphics.circle("fill", player.body:getX(), player.body:getY(), player.shape:getRadius())
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
    print(a:getUserData().name.." colliding with "..b:getUserData().name.." with a vector normal of: "..x..", "..y)

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