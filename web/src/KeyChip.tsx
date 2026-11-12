import type { KeyHint } from './store';

/**
 * The key that confirms. On keyboard, the bound key's own name (whatever the player bound in the
 * FiveM key settings). On a pad, a drawn glyph of the button: face buttons as lettered circles,
 * the D-pad as a cross with the pressed arm filled, bumpers and triggers as short pills.
 */
export function KeyChip({ hint }: { hint: KeyHint }) {
  if (hint.device === 'pad') return <PadGlyph button={hint.key} />;
  const text = hint.key.length > 6 ? hint.key.slice(0, 6) : hint.key;
  return <span className="chip">{text}</span>;
}

const FACE: Record<string, string> = {
  RDOWN_INDEX: 'A',
  RRIGHT_INDEX: 'B',
  RLEFT_INDEX: 'X',
  RUP_INDEX: 'Y',
};
const PILL: Record<string, string> = {
  L1_INDEX: 'LB',
  R1_INDEX: 'RB',
  L2_INDEX: 'LT',
  R2_INDEX: 'RT',
  L3_INDEX: 'LS',
  R3_INDEX: 'RS',
  SELECT_INDEX: 'View',
  START_INDEX: 'Menu',
};
const DPAD: Record<string, 'up' | 'down' | 'left' | 'right'> = {
  LUP_INDEX: 'up',
  LDOWN_INDEX: 'down',
  LLEFT_INDEX: 'left',
  LRIGHT_INDEX: 'right',
};

function PadGlyph({ button }: { button: string }) {
  const face = FACE[button];
  if (face) {
    return (
      <svg className="glyph" viewBox="0 0 22 22" width={22} height={22} aria-label={face}>
        <circle cx="11" cy="11" r="10" fill="#f8f8f6" />
        <text x="11" y="15.2" textAnchor="middle" fontSize="11.5" fontWeight="700" fill="#141619">
          {face}
        </text>
      </svg>
    );
  }
  const arm = DPAD[button];
  if (arm) {
    // a cross; the pressed arm filled
    const arms = {
      up: 'M8.5 2.5h5v6h-5z',
      down: 'M8.5 13.5h5v6h-5z',
      left: 'M2.5 8.5h6v5h-6z',
      right: 'M13.5 8.5h6v5h-6z',
    };
    return (
      <svg className="glyph" viewBox="0 0 22 22" width={22} height={22} aria-label={`D-pad ${arm}`}>
        <path d="M8 2h6v6h6v6h-6v6H8v-6H2V8h6z" fill="#f8f8f6" strokeLinejoin="round" />
        <path d={arms[arm]} fill="#141619" />
      </svg>
    );
  }
  return <span className="chip">{PILL[button] ?? button.replace('_INDEX', '')}</span>;
}
