import { create } from 'zustand';

/** One option of the prompt, as client/interact/dui.lua sends it. */
export type PromptOption = {
  label: string;
  icon?: string;
  description?: string;
  /** Hold to confirm, milliseconds (absent = press). */
  hold?: number;
};

/** Which key or pad button confirms, as the player is playing right now. */
export type KeyHint = { device: 'keyboard' | 'pad'; key: string };

type State = {
  scale: number;
  holdWord: string;
  accent: string | null;
  /** The point being shown. */
  id: string | null;
  options: PromptOption[];
  selected: number;
  key: KeyHint;
  /** Holding: the hold's length, or 0 when not holding. */
  holding: number;
  /** Bumped on every confirm: replays the press. */
  pulse: number;
  /** Bumped when a prompt opens from nothing: replays the entrance. A move to a neighbouring point
   *  (`swap`) keeps it, so the prompt glides over instead of popping in again. */
  epoch: number;
  /** The prompt is on its way out (it keeps its content until the exit has played). */
  leaving: boolean;
};

export const usePrompt = create<State>(() => ({
  scale: 1,
  holdWord: 'Hold',
  accent: null,
  id: null,
  options: [],
  selected: 0,
  key: { device: 'keyboard', key: 'E' },
  holding: 0,
  pulse: 0,
  epoch: 0,
  leaving: false,
}));

/** Every message the game sends the page (SendDuiMessage, JSON). */
export type Message =
  | { type: 'init'; scale?: number; hold?: string; accent?: string | null }
  | { type: 'show'; id: string; options: PromptOption[]; selected?: number; key?: KeyHint; mode?: 'enter' | 'swap' }
  | { type: 'select'; selected: number }
  | { type: 'key'; key: KeyHint }
  | { type: 'hold'; ms: number }
  | { type: 'release' }
  | { type: 'confirm' }
  | { type: 'hide' };

/** How long the exit plays before the prompt's content is dropped (matches .is-out in styles.css). */
const LEAVE_MS = 150;
let leaveTimer = 0;

export function handle(m: Message) {
  const set = usePrompt.setState;
  switch (m.type) {
    case 'init':
      set({ scale: m.scale ?? 1, holdWord: m.hold ?? 'Hold', accent: m.accent ?? null });
      break;
    case 'show':
      window.clearTimeout(leaveTimer);
      set((s) => {
        const swap = m.mode === 'swap' && s.id !== null && !s.leaving;
        return {
          id: m.id,
          options: m.options,
          selected: Math.min(Math.max(m.selected ?? 0, 0), Math.max(m.options.length - 1, 0)),
          key: m.key ?? s.key,
          holding: 0,
          leaving: false,
          epoch: swap ? s.epoch : s.epoch + 1,
        };
      });
      break;
    case 'select':
      set((s) => ({ selected: Math.min(Math.max(m.selected, 0), Math.max(s.options.length - 1, 0)), holding: 0 }));
      break;
    case 'key':
      set({ key: m.key });
      break;
    case 'hold':
      set({ holding: m.ms });
      break;
    case 'release':
      set({ holding: 0 });
      break;
    case 'confirm':
      set((s) => ({ holding: 0, pulse: s.pulse + 1 }));
      break;
    case 'hide':
      if (usePrompt.getState().id === null) break;
      set({ leaving: true, holding: 0 });
      window.clearTimeout(leaveTimer);
      leaveTimer = window.setTimeout(() => set({ id: null, options: [], leaving: false }), LEAVE_MS);
      break;
  }
}
