-- Which point gets the prompt. Pure (no natives): given the candidates as the frame sees them, it
-- picks one, so it can be tested offline.
--
-- A candidate can take focus when it is on screen, close enough to use, and near the middle of the
-- screen. Of those, the nearest the middle wins, with the player's distance as a small tie-breaker
-- (two slots side by side: the one you look at, then the nearer). The point already focused keeps
-- focus until another is clearly better (Stickiness), so a prompt does not flicker between two
-- neighbours as the camera drifts.

---@type table Focus module; the table returned at end of file.
local focus = {}

---@class FocusCandidate
---@field key string a stable identity (point id + entity)
---@field onScreen boolean
---@field sx number screen x 0..1
---@field sy number screen y 0..1
---@field dist number player to point, metres
---@field reach number the point's interact distance
---@field blocked? boolean line of sight is known to be blocked

---How far from the screen's centre, width-relative (aspect corrected).
---@param c FocusCandidate
---@param aspect number width / height
---@return number
function focus.offCentre(c, aspect)
    local dx = c.sx - 0.5
    local dy = (c.sy - 0.5) / aspect
    return math.sqrt(dx * dx + dy * dy)
end

---@param c FocusCandidate
---@param aspect number
---@return number score lower is better
function focus.score(c, aspect)
    return focus.offCentre(c, aspect) + c.dist * 0.01
end

---@param c FocusCandidate
---@param aspect number
---@param radius number
---@return boolean
function focus.eligible(c, aspect, radius)
    return c.onScreen and not c.blocked and c.dist <= c.reach and focus.offCentre(c, aspect) <= radius
end

---Pick the focused candidate.
---@param list FocusCandidate[]
---@param current string|nil the key focused last frame
---@param aspect number
---@param radius number FocusRadius
---@param sticky number Stickiness
---@return FocusCandidate|nil
function focus.choose(list, current, aspect, radius, sticky)
    local best, bestScore, held, heldScore

    for _, c in ipairs(list) do
        if focus.eligible(c, aspect, radius) then
            local s = focus.score(c, aspect)

            if not best or s < bestScore then
                best, bestScore = c, s
            end

            if c.key == current then
                held, heldScore = c, s
            end
        end
    end

    if held and best ~= held and heldScore <= bestScore + sticky then
        return held
    end

    return best
end

return focus
