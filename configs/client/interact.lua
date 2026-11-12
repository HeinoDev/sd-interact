return {
    -- Defaults for every point (a point or one of its options can set its own).
    Distance = 7.0, -- metres from the player within which a point shows (as a dot)
    InteractDistance = 2.6, -- metres within which it can be used (its prompt opens)
    -- A point is measured to its middle, but a player reaches for its near side: a shop keeper behind a
    -- counter, a car's door. This much is added to every distance a prompt is allowed at (the point's
    -- interact distance and any option's own distance).
    Slack = 0.75,

    -- Which point gets the prompt: the one nearest the middle of the screen, among those in range.
    FocusRadius = 0.22, -- how far from the screen's centre a point may be and still take focus (0..1 of the width)
    Stickiness = 0.03, -- a focused point keeps focus until another is this much nearer the centre

    -- A point behind a wall or a door does not open: a ray from the camera must reach it.
    LineOfSight = true,
    LosEveryMs = 100, -- how often the focused point is re-checked

    ScanEveryMs = 200, -- how often points in range, entities of watched models and options are refreshed
    ModelScanRange = 12.0, -- metres around the player searched for entities of watched models / types

    -- Prompts hide while...
    HideInVehicle = true, -- the player is in a vehicle (a point can set allowInVehicle = true)
    HideWhileAiming = true,
    HideWhenNuiFocused = true, -- a menu or inventory has the mouse
    HideWhenDead = true,
}
