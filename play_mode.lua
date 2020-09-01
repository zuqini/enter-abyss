require 'camera'
require 'slidable_utils'

local GameMode = {}
GameMode.modeName = "Play Mode"

local worldWidth = resWidth
local worldHeight = resHeight

local player = {}
local objects = {}
local world = nil
local psystem = nil

-- utils
local function getAngle(orientation, pitch)
    return -orientation * pitch + (orientation > 0 and math.pi or 0)
end

function GameMode:Init()
    camera = cameraInit(resWidth, resHeight, 0, 0, 1, 1, 0)
    player = {
        forwardThrust = 1500,
        angularThrust = 0.03,
        pitch = 0,
        orientation = 1,
        sprite = newSpriteSheet(love.graphics.newImage("assets/Submarine-smol.png"), 18, 16),
    }

    love.physics.setMeter(1)
    world = love.physics.newWorld(0, 9.81 * 0.25, true)

    --let's create a ball
    player.body = love.physics.newBody(world, worldWidth/2, worldHeight/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
    player.shape = love.physics.newCircleShape(8) --the ball's shape has a radius of 12
    player.fixture = love.physics.newFixture(player.body, player.shape, 1) -- Attach fixture to body and give it a density of 1.
    player.fixture:setRestitution(0.9) --let the ball bounce

    --let's create the ground
    objects.ground = {}
    objects.ground.body = love.physics.newBody(world, worldWidth/2, worldHeight-10/2) --remember, the shape (the rectangle we create next) anchors to the body from its center, so we have to move it to (650/2, 650-50/2)
    objects.ground.shape = love.physics.newRectangleShape(worldWidth, 10) --make a rectangle with a width of 650 and a height of 50
    objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape) --attach shape to body
    
    --let's create a couple blocks to play around with
    objects.block1 = {}
    objects.block1.body = love.physics.newBody(world, 200, 550, "dynamic")
    objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
    objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5) -- A higher density gives it more mass.
    
    objects.block2 = {}
    objects.block2.body = love.physics.newBody(world, 200, 400, "dynamic")
    objects.block2.shape = love.physics.newRectangleShape(0, 0, 100, 50)
    objects.block2.fixture = love.physics.newFixture(objects.block2.body, objects.block2.shape, 2)

    particle_canvas = love.graphics.newCanvas(1, 1)
    love.graphics.setCanvas(particle_canvas)
        love.graphics.clear()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(106/255, 190/255, 48/255, 1)
        love.graphics.circle("fill", 1, 1, 1)
    love.graphics.setCanvas()
    psystem = love.graphics.newParticleSystem(particle_canvas, 512)
    psystem:setParticleLifetime(1, 2)
    psystem:setSizeVariation(1)
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
        psystem:setSpread(1)
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
end

function GameMode:Draw()
    love.graphics.scale(resScale, resScale)
    cameraSet(camera)
        love.graphics.setColor(106/255, 190/255, 48/255) -- set the drawing color to green for the ground
        love.graphics.polygon("line", objects.ground.body:getWorldPoints(objects.ground.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates
        
        love.graphics.setColor(0.20, 0.20, 0.20)
        love.graphics.polygon("fill", objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
        love.graphics.polygon("fill", objects.block2.body:getWorldPoints(objects.block2.shape:getPoints()))

        love.graphics.setColor(1,1,1)
        drawSprite(player.sprite, 1, player.body:getX(), player.body:getY(), player.pitch * -player.orientation, -player.orientation, 1, 9, 8)
        love.graphics.draw(psystem, 0, 0)
    cameraUnset(camera)

    --love.graphics.setColor(0.76, 0.18, 0.05) --set the drawing color to red for the ball
    --love.graphics.circle("fill", player.body:getX(), player.body:getY(), player.shape:getRadius())
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