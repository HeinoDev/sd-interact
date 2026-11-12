-- Let sd-interact stand in for another target resource: scripts calling exports.ox_target / exports.qtarget
-- / exports['qb-target'] get floating prompts instead, without a line of them changed.
--
-- Off unless the server turns it on, in server.cfg, naming the ones to answer:
--
--     setr sd_interact:replace "ox_target,qtarget"
--
-- Then STOP the real resource (take it out of your server.cfg): two resources answering one export fight.
-- A script that lists it as a dependency needs something by that name to start; see the README
-- ("Replacing ox_target, qtarget or qb-target") for the two ways to give it one.

---@type table<string, boolean> the names listed in the convar
local listed = {}

for name in GetConvar('sd_interact:replace', ''):gmatch('[^,%s]+') do
    listed[name] = true
end

return {
    ox_target = listed.ox_target == true,
    qtarget = listed.qtarget == true, -- ox_target also answers as qtarget; turn both on to keep that working
    ['qb-target'] = listed['qb-target'] == true,
}
