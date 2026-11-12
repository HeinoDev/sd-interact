---@type table sd-interact config root (configs/config.lua).
local config = require 'configs.config'

-- The prompt is a web page rendered off screen (a DUI) and painted into the game's frame with
-- DrawSprite, its anchor (the selected option's tile) exactly on the point's projected position.
-- Painted by the game, it moves with the world in the same frame: an HTML overlay positioned by
-- messages always trails a frame behind. The page is made at the screen's own pixel size (canvas x the
-- screen's height / 1080 x Draw.Scale) and drawn 1:1, so its text stays sharp.
--
-- The dots for points in range but not focused are two small images drawn the same way.

---@type table Dui module; the table returned at end of file.
local dui = {}

local DRAW = config.Draw
local TXD = 'sd_interact'
local URL = ('https://cfx-nui-%s/web/build/index.html'):format(GetCurrentResourceName())

---@type table|nil { obj, tex, w, h, scale, sw, sh } the live page and the screen it was made for
local page = nil
---@type integer|nil the runtime texture dictionary, made once for the life of the resource
local txd = nil
---@type integer|nil game time the current prompt became drawable (the page needs a frame to repaint)
local readyAt = nil
---@type integer pages made so far: each gets its own texture name (a dictionary cannot reuse one)
local pageCount = 0

---@param msg table
local function send(msg)
    if page then
        SendDuiMessage(page.obj, json.encode(msg))
    end
end

---Create (or re-create, when the resolution changed) the page and its texture.
function dui.ensure()
    local sw, sh = GetActiveScreenResolution()

    if page and page.sw == sw and page.sh == sh then return end

    dui.destroy()

    local scale = (sh / 1080.0) * DRAW.Scale
    local w = math.floor(DRAW.Canvas.w * scale + 0.5)
    local h = math.floor(DRAW.Canvas.h * scale + 0.5)
    local obj = CreateDui(URL, w, h)

    if not txd then
        -- the dots once, the page's texture per page
        txd = CreateRuntimeTxd(TXD)
        CreateRuntimeTextureFromImage(txd, 'dot', 'assets/dot.png')
        CreateRuntimeTextureFromImage(txd, 'ring', 'assets/ring.png')
    end

    pageCount = pageCount + 1
    local tex = ('prompt%d'):format(pageCount)
    CreateRuntimeTextureFromDuiHandle(txd, tex, GetDuiHandle(obj))
    page = { obj = obj, tex = tex, w = w, h = h, scale = scale, sw = sw, sh = sh }

    local deadline = GetGameTimer() + 5000

    while not IsDuiAvailable(obj) and GetGameTimer() < deadline do
        Wait(0)
    end

    send({ type = 'init', scale = scale, hold = locale('hold'), accent = DRAW.Accent })
end

function dui.destroy()
    if page then
        DestroyDui(page.obj)
        page = nil
    end
end

---Show a point's prompt.
---@param id string the candidate's key (a new one replays the entrance)
---@param options table[] { label, icon?, description?, hold? }
---@param selected integer 1-based
---@param key table { device, key }
---@param mode 'enter'|'swap' open from nothing (the page plays its entrance) or move from another point
function dui.show(id, options, selected, key, mode)
    send({ type = 'show', id = id, options = options, selected = selected - 1, key = key, mode = mode })

    -- opening: two frames for the page to paint the new prompt before it is drawn. A swap keeps
    -- drawing: the page's label change covers the frame it takes.
    if mode ~= 'swap' or not readyAt then
        readyAt = GetGameTimer() + 34
    end
end

---@param selected integer 1-based
function dui.select(selected) send({ type = 'select', selected = selected - 1 }) end

---@param key table { device, key }
function dui.key(key) send({ type = 'key', key = key }) end

---@param ms integer
function dui.hold(ms) send({ type = 'hold', ms = ms }) end

function dui.release() send({ type = 'release' }) end

function dui.confirm() send({ type = 'confirm' }) end

function dui.hide()
    send({ type = 'hide' }) -- the page plays its exit; the loop keeps drawing it for Draw.LeaveMs
end

---Paint the prompt with its anchor on a screen position (0..1). Its top-left corner is snapped to a
---whole pixel: drawn 1:1 but between pixels, the page would be resampled and its text go soft.
---@param sx number
---@param sy number
function dui.draw(sx, sy)
    if not page or not readyAt or GetGameTimer() < readyAt then return end

    local ax, ay = DRAW.Anchor.x * page.scale, DRAW.Anchor.y * page.scale
    local left = math.floor(sx * page.sw - ax + 0.5)
    local top = math.floor(sy * page.sh - ay + 0.5)
    local cx = (left + page.w / 2) / page.sw
    local cy = (top + page.h / 2) / page.sh

    DrawSprite(TXD, page.tex, cx, cy, page.w / page.sw, page.h / page.sh, 0.0, 255, 255, 255, 255)
end

---@return number width, number height of the screen, pixels
function dui.screen()
    if page then
        return page.sw, page.sh
    end

    return GetActiveScreenResolution()
end

---Paint a dot (a ring when the point is close enough to use).
---@param sx number
---@param sy number
---@param ring boolean
---@param fade number 0..1
function dui.dot(sx, sy, ring, fade)
    if not page then return end

    local px = DRAW.DotSize * (page.sh / 1080.0) * (64 / 26) -- the png's dot is 26 of its 64 px
    local alpha = math.floor(DRAW.DotAlpha * fade)

    DrawSprite(TXD, ring and 'ring' or 'dot', sx, sy, px / page.sw, px / page.sh, 0.0, 255, 255, 255, alpha)
end

---@return number aspect width / height of the screen
function dui.aspect()
    if page then
        return page.sw / page.sh
    end

    local sw, sh = GetActiveScreenResolution()
    return sw / sh
end

return dui
