-- TODO: refactor slidable
-- must contain following fields
-- x = 0,
-- y = love.graphics.getHeight(),
-- t = 0,
-- sourceX = 0,
-- sourceY = love.graphics.getHeight(),
-- targetX = 0,
-- targetY = love.graphics.getHeight(),
-- animationTimeMs = 250,
function updateSlidable(slidable, dt, easingFunc)
    slidable.t = slidable.t + dt * 1000;
    if slidable.t > slidable.animationTimeMs then
        slidable.t = slidable.animationTimeMs
    end
    slidable.x = easingFunc(slidable.sourceX, slidable.targetX, slidable.t/slidable.animationTimeMs)
    slidable.y = easingFunc(slidable.sourceY, slidable.targetY, slidable.t/slidable.animationTimeMs)
end

function setSlidableTarget(slidable, tx, ty, animationTimeMs)
    slidable.sourceX = slidable.x;
    slidable.sourceY = slidable.y;
    slidable.targetX = tx;
    slidable.targetY = ty;
    slidable.t = 0
    slidable.animationTimeMs = animationTimeMs or 250
end

function lerp(v0, v1, t)
    return (1 - t) * v0 + t * v1;
end

function quadraticEaseOut(v0, v1, t)
    local c = v1 - v0
    local b = v0
    return -c*t*(t-2) + b;
    -- Why isn't this stable. Is it even the correct expansion?
    -- return v0*(t*t - 2*t) + v1*(t*t - 2*t + 1)
end

function cubicEaseOut(v0, v1, t)
    local c = v1 - v0
    local b = v0
    -- Transform from range [-1, 0]
    -- So that we don't have to shift the cubic function horizontally
    -- (t-1)^3 vs t^3
    t = t-1
    return c*(t*t*t + 1) + b;
end

function quarticEaseOut(v0, v1, t)
    local c = v1 - v0
    local b = v0
    t = t-1
    return -c*(t*t*t*t - 1) + b;
end