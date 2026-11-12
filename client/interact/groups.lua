-- Job and gang checks for points and options that name `groups` (the same shapes ox_target takes:
-- 'police', { 'police', 'ambulance' } or { police = 2 } for a lowest grade). Read from whichever
-- framework is running; with none, a restricted option is never shown.

---@type table Groups module; the table returned at end of file.
local groups = {}

---The running framework's player data (uncached: the compat layer reads items from it too).
---@return table|nil player data with job / gang
function groups.playerData()
    if GetResourceState('qbx_core') == 'started' then
        local ok, d = pcall(function() return exports.qbx_core:GetPlayerData() end)

        if ok then
            return d
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, d = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayerData() end)

        if ok then
            return d
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local ok, d = pcall(function() return exports.es_extended:getSharedObject().GetPlayerData() end)

        if ok then
            return d
        end
    end

    return nil
end

---@param g any a job or gang table from any framework
---@return string|nil name, integer grade
local function nameGrade(g)
    if type(g) ~= 'table' then
        return nil, 0
    end

    local grade = g.grade

    if type(grade) == 'table' then
        grade = grade.level or grade.grade
    end

    return g.name, tonumber(grade) or 0
end

---@type table|nil, integer cached player data and when it was read (groups are checked often)
local cachedData, cachedAt = nil, 0

---Does the player belong to one of these groups (job or gang, at the grade asked)?
---@param want string|string[]|table<string, integer>|nil
---@return boolean
function groups.allowed(want)
    if want == nil then return true end

    local now = GetGameTimer()

    if not cachedData or now - cachedAt > 1000 then
        cachedData, cachedAt = groups.playerData(), now
    end

    if not cachedData then return false end

    local jn, jg = nameGrade(cachedData.job)
    local gn, gg = nameGrade(cachedData.gang)

    local function has(name, min)
        min = tonumber(min) or 0
        return (jn == name and jg >= min) or (gn == name and gg >= min)
    end

    if type(want) == 'string' then
        return has(want, 0)
    end

    if type(want) ~= 'table' then return false end

    if want[1] then
        for _, name in ipairs(want) do
            if has(name, 0) then return true end
        end

        return false
    end

    for name, min in pairs(want) do
        if has(name, min) then return true end
    end

    return false
end

return groups
