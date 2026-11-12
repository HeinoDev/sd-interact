import { handle, type Message } from './store';

/**
 * The dev preview. `#mock` loops through every state; `#mock&step=N` freezes on one (for screenshots):
 * 0 a single option, 1 a rack slot with three options, 2 the next one selected, 3 holding, 4 on a pad.
 */
const STEPS: Message[][] = [
  [{ type: 'show', id: 'sign', options: [{ icon: 'smartphone', label: 'Send owner contact to phone' }] }],
  [
    {
      type: 'show',
      id: 'slot',
      options: [
        { icon: 'fa-solid fa-hand', label: 'Take Pump Shotgun' },
        {
          icon: 'fa-solid fa-magnifying-glass',
          label: 'Inspect',
          description: 'Serial, ammo, attachments, who racked it',
        },
        { icon: 'fa-solid fa-handcuffs', label: 'Seize', hold: 1500 },
      ],
    },
  ],
  [
    {
      type: 'show',
      id: 'slot2',
      mode: 'swap',
      options: [
        { icon: 'fa-solid fa-gun', label: 'Rack Carbine Rifle' },
        { icon: 'fa-solid fa-list', label: 'Choose weapon...' },
      ],
    },
  ],
  [{ type: 'select', selected: 2 }, { type: 'hold', ms: 1500 }],
  [
    { type: 'key', key: { device: 'pad', key: 'LRIGHT_INDEX' } },
    { type: 'select', selected: 0 },
  ],
];

export function runMock(step: string | null) {
  handle({ type: 'init', scale: 1 });
  if (step !== null) {
    const n = Math.max(0, Math.min(STEPS.length - 1, Number(step) || 0));
    // replay up to the step so state builds as it would
    const start = n >= 1 && n <= 4 ? 1 : n;
    for (let i = start; i <= n; i++) STEPS[i].forEach(handle);
    return;
  }
  let i = 0;
  const tick = () => {
    STEPS[i % STEPS.length].forEach(handle);
    i++;
    setTimeout(tick, 1800);
  };
  tick();
}
