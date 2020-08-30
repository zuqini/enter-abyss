function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = newSpriteSheet(image, width, height);
    animation.duration = duration or 1
    animation.currentTime = 0
    animation.cycleCount = 0

    return animation
end

function resetAnimation(animation)
    animation.currentTime = 0
    animation.cycleCount = 0
end

function updateAnimation(animation, dt)
    animation.currentTime = animation.currentTime + dt
    if animation.currentTime >= animation.duration then
        animation.currentTime = animation.currentTime - animation.duration
        animation.cycleCount = animation.cycleCount + 1
    end
end

function drawAnimation(animation, x, y, r, sx, sy, ox, oy)
    local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.spriteSheet.quads) + 1
    love.graphics.draw(animation.spriteSheet.image, animation.spriteSheet.quads[spriteNum], x, y, r, sx, sy, ox, oy)
end

function newSpriteSheet(image, width, height, padding)
    local spriteSheet = {}
    spriteSheet.image = image;
    spriteSheet.quads = {};

    local xStride = width
    local yStride = height
    if padding ~= nil then
        xStride = xStride + padding
        yStride = yStride + padding
    end

    for y = 0, image:getHeight() - height, yStride do
        for x = 0, image:getWidth() - width, xStride do
            table.insert(spriteSheet.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    return spriteSheet
end