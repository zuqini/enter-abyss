local baseW, baseH = 128,64
local baseX, baseY = 0 + baseW / 2, 0 + baseH / 2

local function buildBaseLegacy()
    local x, y = baseX - baseW/2, baseY - baseH/2
    local w, h = baseW, baseH
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