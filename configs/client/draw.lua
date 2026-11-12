return {
    -- The prompt page's canvas and where on it the point goes (the selected option's tile). These match
    -- web/src/Prompt.tsx CANVAS and ANCHOR; change them together.
    Canvas = { w = 760, h = 420 },
    Anchor = { x = 48, y = 210 },

    Scale = 1.08, -- prompt size (1.0 = designed at 1080p, and it scales with the screen's height)
    Accent = nil, -- hold-ring colour, e.g. '#7cc4ff'; nil keeps the prompt all white

    -- Motion (ms): moving from one point to the next glides the prompt there; closing plays a short exit.
    GlideMs = 140,
    LeaveMs = 150, -- keep in step with LEAVE_MS in web/src/store.ts

    -- Points in range but not focused: a small dot, a ring when close enough to use.
    Dots = true,
    DotSize = 7, -- pixels at 1080p
    DotAlpha = 165,
    DotMerge = 28, -- dots closer than this on screen (pixels at 1080p) merge into one
    DotClear = 120, -- no dots this close to the open prompt (pixels at 1080p)
    DotFade = 10, -- how fast dots fade in and out (higher is quicker)
}
