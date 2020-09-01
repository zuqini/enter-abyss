--
-- Camera
--

require 'slidable_utils'

function cameraInit(resW, resH, x, y, sx, sy, r)
    local camera = {}
    camera.resW = resW
    camera.resH = resH
    camera.x = x
    camera.y = y
    camera.scaleX = sx
    camera.scaleY = sy
    camera.rotation = r
    camera.cx = 0;
    camera.cy = 0;

    -- For interpolating
    camera.slidable = {}
    camera.slidable.x = 0;
    camera.slidable.y = 0;
    camera.slidable.sourceX = 0;
    camera.slidable.sourceY = 0;
    camera.slidable.targetX = 0;
    camera.slidable.targetY = 0;
    camera.slidable.t = 0;
    camera.slidable.animationTimeMs = 500

    -- For camera controls
    camera.lastMouseX = 0
    camera.lastMouseY = 0
    camera.mouseX = 0
    camera.mouseY = 0

    return camera
end

function cameraSet(camera, isCenter)
    love.graphics.push()
    love.graphics.scale(1 / camera.scaleX, 1 / camera.scaleY)
    love.graphics.rotate(-camera.rotation)
    if isCenter then
        love.graphics.translate(-camera.cx + (camera.scaleX * camera.resW)/2, -camera.cy + (camera.scaleY * camera.resH)/2)
    else
        love.graphics.translate(-camera.x, -camera.y)
    end
end

function cameraCenter(camera, cx, cy)
    camera.cx = cx;
    camera.cy = cy;
end

function cameraSetTarget(camera, tx, ty)
    setSlidableTarget(camera.slidable, tx, ty)
end

function cameraSetTargetCenter(camera, tx, ty)
    cameraSetTarget(camera, tx - (camera.scaleX * camera.resW)/2, ty - (camera.scaleY * camera.resH)/2)
end

function cameraUnset(camera)
    love.graphics.pop()
end

function cameraMove(camera, dx, dy)
    camera.x = camera.x + (dx or 0)
    camera.y = camera.y + (dy or 0)
end

function cameraAnimate(camera, dt, easingFunc)
    updateSlidable(camera.slidable, dt, easingFunc)
    camera.x = camera.slidable.x
    camera.y = camera.slidable.y
end

function cameraLerp(camera, dt)
    cameraAnimate(camera, dt, lerp)
end

function cameraRotate(dr)
    camera.rotation = camera.rotation + dr
end

function cameraScale(camera, sx, sy)
    sx = sx or 1
    camera.scaleX = camera.scaleX * sx
    camera.scaleY = camera.scaleY * (sy or sx)
end

function cameraSetPosition(camera, x, y)
    camera.x = x or camera.x
    camera.y = y or camera.y
end

function cameraSetPositionCenter(camera, x, y)
    camera.x = x or camera.x
    camera.x = camera.x - (camera.scaleX * camera.resW)/2
    camera.y = y or camera.y
    camera.y = camera.y - (camera.scaleY * camera.resH)/2
end

function cameraSetScale(camera, sx, sy)
    camera.scaleX = sx or camera.scaleX
    camera.scaleY = sy or camera.scaleY
end

function cameraGetMousePosition(camera)
  return love.mouse.getX() * camera.scaleX + camera.x, love.mouse.getY() * camera.scaleY + camera.y
end

function rectIntersectsCamera(camera, x, y, w, h)
    return AABB2Intersection(camera.x, camera.y, camera.scaleX * camera.resW, camera.scaleY * camera.resH, x, y, w, h)
end

function rectInsideCamera(camera, x, y, w, h)
    return AABB2Overlaps(camera.x, camera.y, camera.scaleX * camera.resW, camera.scaleY * camera.resH, x, y, w, h)
end

-- TODO(ray): Should maybe be in a geometry/math/utils file
function AABB2Intersection(x1, y1, w1, h1, x2, y2, w2, h2)
    if (x1 + w1 < x2) or (x2 + w2 < x1) then
        return false
    end
    if (y1 + h1 < y2) or (y2 + h2 < y1) then
        return false
    end
    return true
end

-- Does Rect1 contain all of Rect2
function AABB2Overlaps(x1, y1, w1, h1, x2, y2, w2, h2)
    if x2 >= x1 and x1+w1 >= x2+w2 and y2 >= y1 and y1+h1 >= y2+h2 then return true end
    return false
end

function basicCameraControl(camera, dt)
    if love.keyboard.isDown("left") then
        cameraMove(camera, -500 * dt, 0)
    end
    if love.keyboard.isDown("right") then
        cameraMove(camera, 500 * dt, 0)
    end
    if love.keyboard.isDown("up") then
        cameraMove(camera, 0, -500 * dt)
    end
    if love.keyboard.isDown("down") then
        cameraMove(camera, 0, 500 * dt)
    end
    camera.lastMouseX = camera.mouseX
    camera.lastMouseY = camera.mouseY
    camera.mouseX, camera.mouseY = love.mouse.getPosition()
    if love.mouse.isDown(3) then
        local dx = camera.mouseX - camera.lastMouseX
        local dy = camera.mouseY - camera.lastMouseY
        cameraMove(camera, -200 * camera.scaleX * dx * dt, -200 * camera.scaleY * dy * dt)
    end
end