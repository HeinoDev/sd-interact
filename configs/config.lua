-- Aggregate config root: `require 'configs.config'`. sd-interact is client-only, so every file is in
-- configs/client/.
return {
    Locale = 'en', -- lib.locale loads locales/<Locale>.json, falling back to en per-key
    Debug = false, -- prints focus changes and draws every point's anchor

    Interact = require 'configs.client.interact', -- distances, focus, line of sight, when prompts hide
    Controls = require 'configs.client.controls', -- default keys and pad buttons (players rebind them)
    Draw = require 'configs.client.draw', -- prompt size, dots, accent
    Replace = require 'configs.client.replace', -- answer ox_target / qtarget / qb-target calls with prompts
}
