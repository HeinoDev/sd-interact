---@type table Every interaction point (client.interact.points).
local points = require 'client.interact.points'

-- Which points a target resource's call made, by what it was made on ("local:123", "model:<hash>",
-- "zone:stash_1", "global:vehicle"), so that call's remove can find them again: by everything, or
-- by option names (ox_target) / labels (qb-target). Each stand-in layer works through its own scope
-- (book.scope), so ox_target, qtarget and qb-target calls never share a key.

---@type table Book module; the table returned at end of file.
local book = {}

---@type table<string, integer[]> point ids by key
local byKey = {}

---@param key string
---@param id integer|nil
function book.add(key, id)
    if not id then return end

    byKey[key] = byKey[key] or {}
    table.insert(byKey[key], id)
end

---@param key string
---@return boolean
function book.has(key)
    return byKey[key] ~= nil and #byKey[key] > 0
end

---@param key string
---@return integer[] the point ids under a key (some may be gone until the next prune)
function book.ids(key)
    return byKey[key] or {}
end

---Remove what was made under a key: everything, or only the options whose `field` ('name' or
---'label') is listed, optionally only on the points one resource made.
---@param key string
---@param names string|string[]|nil
---@param field? 'name'|'label'
---@param resource? string
function book.remove(key, names, field, resource)
    local ids = byKey[key]

    if not ids then return end

    if names == nil then
        for _, id in ipairs(ids) do
            points.remove(id)
        end

        byKey[key] = nil
        return
    end

    local drop = {}

    for _, n in ipairs(type(names) == 'table' and names or { names }) do
        drop[n] = true
    end

    local keep = {}

    for _, id in ipairs(ids) do
        local p = points.get(id)

        if p and resource and p.resource ~= resource then
            keep[#keep + 1] = id
        elseif p then
            local left = {}

            for _, o in ipairs(p.options) do
                if not drop[o[field]] then
                    left[#left + 1] = o
                end
            end

            if #left == 0 then
                points.remove(id)
            else
                if #left ~= #p.options then
                    points.update(id, { options = left })
                end

                keep[#keep + 1] = id
            end
        end
    end

    byKey[key] = #keep > 0 and keep or nil
end

---The target resource's own option tables behind the points under a key, each once, in order.
---@param key string
---@return table[]|nil nil when nothing is left under the key
function book.sources(key)
    local out, seen = {}, {}

    for _, id in ipairs(book.ids(key)) do
        local p = points.get(id)

        for _, o in ipairs(p and p.options or {}) do
            local s = o.source

            if s and not seen[s] then
                seen[s] = true
                out[#out + 1] = s
            end
        end
    end

    return out[1] and out or nil
end

---Forget every key whose points are all gone (their resource stopped).
function book.prune()
    for key, ids in pairs(byKey) do
        local live = {}

        for _, id in ipairs(ids) do
            if points.get(id) then
                live[#live + 1] = id
            end
        end

        byKey[key] = #live > 0 and live or nil
    end
end

---The book as one stand-in layer sees it: the same calls, every key prefixed with the name the layer
---answers as ('ox_target', 'qtarget', 'qb-target').
---@param name string
---@return table
function book.scope(name)
    local prefix = name .. '|'

    return {
        add = function(key, id) book.add(prefix .. key, id) end,
        has = function(key) return book.has(prefix .. key) end,
        ids = function(key) return book.ids(prefix .. key) end,
        remove = function(key, names, field, resource) book.remove(prefix .. key, names, field, resource) end,
        sources = function(key) return book.sources(prefix .. key) end,
    }
end

return book
