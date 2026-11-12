-- Default bindings. They are FiveM key mappings, so every player can change them in
-- Settings > Key Bindings > FiveM (sd-interact); these are only what a new player starts with.
-- Keyboard keys: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
-- Pad buttons (PAD_DIGITALBUTTON): LUP_INDEX LDOWN_INDEX LLEFT_INDEX LRIGHT_INDEX (the D-pad),
-- RUP_INDEX RDOWN_INDEX RLEFT_INDEX RRIGHT_INDEX (Y A X B), L1_INDEX R1_INDEX L2_INDEX R2_INDEX ...
return {
    Key = 'E', -- confirm on keyboard
    Next = 'IOM_WHEEL_DOWN', -- next option: mouse wheel down
    Prev = 'IOM_WHEEL_UP', -- previous option: mouse wheel up

    Pad = 'LRIGHT_INDEX', -- confirm on a pad: D-pad right, GTA's own button for "interact"
    PadNext = 'LDOWN_INDEX', -- next option: D-pad down
    PadPrev = 'LUP_INDEX', -- previous option: D-pad up

    -- While a prompt with more than one option is open, these game controls are blocked so the
    -- wheel and the D-pad change the option instead of the weapon, the phone or the radio.
    Block = { 14, 15, 16, 17, 99, 100, 261, 262, 27, 172, 173, 19 },
}
