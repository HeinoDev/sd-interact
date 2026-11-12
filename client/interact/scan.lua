---@type table sd-interact config root (configs/config.lua).
local config = require 'configs.config'
---@type table Every interaction point (client.interact.points).
local points = require 'client.interact.points'
---@type table Job / gang checks (client.interact.groups).
local groups = require 'client.interact.groups'

-- A few times a second: which points are near enough to matter, where they are, and which of their
-- options the player may use right now. The frame loop (client.interact.loop) only draws and picks
-- from this list, so the expensive parts (entity pools, canInteract callbacks into other resources)
-- run at ScanEveryMs, not every frame. Entity-anchored candidates keep their entity, and the loop
-- re-reads their position every frame so a prompt rides a moving door or vehicle.

---@class InteractCandidate
---@field key string point id + entity: one prompt per point per entity
---@field point InteractPoint
---@field entity integer|nil
---@field pos vector3
---@field dist number
---@field options { option: InteractOption, index: integer, label: string }[] the options shown, in order
---@field reach number the interact distance

---@type table Scan module; the table returned at end of file.
local scan = {}

---@type InteractCandidate[] The points in range, as of the last scan.
scan.candidates = {}

local CFG = config.Interact

---@type table<integer, vector3> A model's bounding-box middle (the default anchor on an entity).
local middles = {}

---@param entity integer
---@return vector3 offset from the entity's origin to its middle
local function middle(entity)
    local model = GetEntityModel(entity)
    local m = middles[model]

    if not m then
        local lo, hi = GetModelDimensions(model)
        m = vector3((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (lo.z + hi.z) / 2)
        middles[model] = m
    end

    return m
end

---Where a point's prompt goes on an entity: its bone, its offset, or the middle of its model.
---@param p InteractPoint
---@param entity integer
---@return vector3
function scan.anchor(p, entity)
    if p.bone then
        local idx

        if type(p.bone) == 'string' then
            idx = GetEntityBoneIndexByName(entity, p.bone)
        else
            idx = GetPedBoneIndex(entity, p.bone)
        end

        if idx and idx ~= -1 then
            local b = GetWorldPositionOfEntityBone(entity, idx)

            if p.offset then
                return b + p.offset
            end

            return b
        end
    end

    local o = p.offset or middle(entity)
    return GetOffsetFromEntityInWorldCoords(entity, o.x, o.y, o.z)
end

---The options of a point the player may use here and now, in order.
---@param p InteractPoint
---@param entity integer|nil
---@param pos vector3
---@param dist number
---@return { option: InteractOption, index: integer }[]
local function usable(p, entity, pos, dist)
    local out = {}

    if p.groups and not groups.allowed(p.groups) then
        return out
    end

    for i, o in ipairs(p.options) do
        local ok = true
        local label

        if o.groups and not groups.allowed(o.groups) then
            ok = false
        end

        if ok and o.distance and dist > o.distance + CFG.Slack then
            ok = false
        end

        if ok and o.canInteract then
            -- a second return value is the label to show now ("Take Pump Shotgun"): an option table
            -- crosses into this resource as a copy, so its owner cannot just rewrite o.label
            local fine, res, now = pcall(o.canInteract, entity, pos, o.args, dist)
            ok = fine and res and true or false

            if ok and type(now) == 'string' and now ~= '' then
                label = now
            end
        end

        if ok then
            out[#out + 1] = { option = o, index = i, label = label or o.label }
        end
    end

    return out
end

---@param list InteractCandidate[]
---@param p InteractPoint
---@param entity integer|nil
---@param pos vector3
---@param from vector3 the player
local function consider(list, p, entity, pos, from)
    local dist = #(pos - from)

    if dist > p.distance then return end

    local opts = usable(p, entity, pos, dist)

    if #opts == 0 then return end

    list[#list + 1] = {
        key = entity and ('%d:%d'):format(p.id, entity) or tostring(p.id),
        point = p,
        entity = entity,
        pos = pos,
        dist = dist,
        options = opts,
        reach = p.interactDistance + CFG.Slack,
    }
end

---Entities of the given pool near the player.
---@param pool string
---@param from vector3
---@param range number
---@return integer[]
local function near(pool, from, range)
    local out = {}

    for _, e in ipairs(GetGamePool(pool)) do
        if #(GetEntityCoords(e) - from) <= range then
            out[#out + 1] = e
        end
    end

    return out
end

---Is this entity one a global point of this kind goes on? (Players and other peds share a pool.)
---@param kind 'vehicle'|'ped'|'object'|'player'
---@param entity integer
---@return boolean
local function isKind(kind, entity)
    if kind == 'object' or kind == 'vehicle' then return true end

    local isPlayer = IsPedAPlayer(entity)

    if kind == 'player' then
        return isPlayer
    end

    return kind == 'ped' and not isPlayer
end

---Rebuild the candidate list.
---@param ped integer the player's ped
---@param inVehicle boolean
function scan.run(ped, inVehicle)
    local from = GetEntityCoords(ped)
    local list = {}
    local wantModels, wantGlobal = false, {}

    for _, p in pairs(points.all()) do
        if inVehicle and not p.allowInVehicle and CFG.HideInVehicle then goto continue end

        if p.kind == 'coords' then
            consider(list, p, nil, p.coords, from)
        elseif p.kind == 'entity' then
            if DoesEntityExist(p.entity) then
                consider(list, p, p.entity, scan.anchor(p, p.entity), from)
            end
        elseif p.kind == 'net' then
            if NetworkDoesNetworkIdExist(p.netId) then
                local e = NetworkGetEntityFromNetworkId(p.netId)

                if e and e ~= 0 and DoesEntityExist(e) then
                    consider(list, p, e, scan.anchor(p, e), from)
                end
            end
        elseif p.kind == 'model' then
            wantModels = true
        elseif p.kind == 'global' then
            wantGlobal[p.global] = true
        end

        ::continue::
    end

    local wantObjects = wantModels or wantGlobal.object
    local wantPeds = wantModels or wantGlobal.ped or wantGlobal.player
    local wantVehicles = wantModels or wantGlobal.vehicle

    if not wantObjects and not wantPeds and not wantVehicles then
        scan.candidates = list
        return
    end

    local range = CFG.ModelScanRange
    local pools = {}

    if wantObjects then
        pools.CObject = near('CObject', from, range)
    end

    if wantPeds then
        pools.CPed = near('CPed', from, range)
    end

    if wantVehicles then
        pools.CVehicle = near('CVehicle', from, range)
    end

    for _, p in pairs(points.all()) do
        if inVehicle and not p.allowInVehicle and CFG.HideInVehicle then goto skip end

        if p.kind == 'model' then
            for _, pool in pairs(pools) do
                for _, e in ipairs(pool) do
                    if p.models[GetEntityModel(e)] and e ~= ped then
                        consider(list, p, e, scan.anchor(p, e), from)
                    end
                end
            end
        elseif p.kind == 'global' then
            local pool = pools.CPed

            if p.global == 'object' then
                pool = pools.CObject
            elseif p.global == 'vehicle' then
                pool = pools.CVehicle
            end

            for _, e in ipairs(pool or {}) do
                if e ~= ped and isKind(p.global, e) then
                    consider(list, p, e, scan.anchor(p, e), from)
                end
            end
        end

        ::skip::
    end

    scan.candidates = list
end

return scan
