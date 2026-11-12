import { useEffect, useRef, useState } from 'react';
import { Icon } from './Icon';
import { KeyChip } from './KeyChip';
import { usePrompt } from './store';

/**
 * The page is a fixed canvas the game paints over the world with its anchor on the point: the selected
 * option's tile sits exactly on the anchor. These numbers are also in configs/client/draw.lua (the
 * sprite's size and where its anchor is); change them together.
 */
export const CANVAS = { w: 760, h: 420 };
export const ANCHOR = { x: 48, y: 210 };
/** The selected tile, and the smaller tiles of its neighbours. */
const TILE = 38;
const SMALL = 28;
const ROW = 44;
/** Only the selected option and its immediate neighbours are drawn: a hint that there is more, no list. */
const FADE = [1, 0.5];

/**
 * The drum: options stacked down a column, the whole column sliding so the selected one is always on
 * the anchor. Only the selected row says what it does and which key does it; its neighbours are small
 * glass tiles above and below. It springs out of the point when it opens, shrinks back into it when it
 * closes, and moving to a neighbouring point (`swap`) only swaps the label.
 */
export function Prompt() {
  const { id, options, selected, key, holding, pulse, holdWord, accent, epoch, leaving } = usePrompt();
  if (!id || options.length === 0) return null;
  const current = options[Math.min(selected, options.length - 1)];

  return (
    <div className={leaving ? 'prompt is-out' : 'prompt is-in'} key={epoch}>
      <div className="drum" style={{ transform: `translateY(${-selected * ROW}px)` }}>
        {options.map((o, i) => {
          const d = Math.abs(i - selected);
          if (d >= FADE.length) return null;
          const on = i === selected;
          const size = on ? TILE : SMALL;
          return (
            <div
              key={i}
              className={on ? 'tile tile-on' : 'tile'}
              style={{
                left: ANCHOR.x - size / 2,
                top: ANCHOR.y - size / 2 + i * ROW,
                width: size,
                height: size,
                opacity: FADE[d],
              }}
            >
              {on && <Ring ms={holding} accent={accent} />}
              <span className={on ? 'face face-on' : 'face'} key={on ? `p${pulse}` : 'idle'}>
                <Icon name={o.icon} size={on ? 19 : 14} />
              </span>
            </div>
          );
        })}
      </div>

      <div className="label" key={`${id}:${selected}`} style={{ left: ANCHOR.x + TILE / 2 + 14, top: ANCHOR.y }}>
        <div className="line">
          <span className="text">{current.label}</span>
          <span className="hint">
            {current.hold ? <span className="hold">{holdWord}</span> : null}
            <KeyChip hint={key} />
          </span>
        </div>
        {current.description ? <div className="desc">{current.description}</div> : null}
      </div>
    </div>
  );
}

/** The hold outline: GAP px outside the selected tile, its corners the tile's radius plus the gap so the
 *  spacing is even all the way round (the tile is TILE square with an 11px radius, styles.css .tile-on). */
const GAP = 4;
const OUTLINE = TILE + GAP * 2;
const OUTLINE_R = 11 + GAP;
const BOX = 56;

/** The outline as one path that starts at the top centre and runs clockwise, so the fill does too. */
function outlinePath() {
  const lo = (BOX - OUTLINE) / 2;
  const hi = lo + OUTLINE;
  const mid = BOX / 2;
  const r = OUTLINE_R;
  return [
    `M ${mid} ${lo}`,
    `H ${hi - r}`,
    `A ${r} ${r} 0 0 1 ${hi} ${lo + r}`,
    `V ${hi - r}`,
    `A ${r} ${r} 0 0 1 ${hi - r} ${hi}`,
    `H ${lo + r}`,
    `A ${r} ${r} 0 0 1 ${lo} ${hi - r}`,
    `V ${lo + r}`,
    `A ${r} ${r} 0 0 1 ${lo + r} ${lo}`,
    'Z',
  ].join(' ');
}

const OUTLINE_PATH = outlinePath();

/**
 * The hold outline round the selected tile, its own shape a little larger: empty, it fills clockwise from
 * the top over the hold's length; let go and it runs back. Started a frame after mounting so the
 * transition has a starting point.
 */
function Ring({ ms, accent }: { ms: number; accent: string | null }) {
  const [full, setFull] = useState(false);
  const raf = useRef(0);
  useEffect(() => {
    cancelAnimationFrame(raf.current);
    setFull(false);
    if (ms > 0) raf.current = requestAnimationFrame(() => requestAnimationFrame(() => setFull(true)));
    return () => cancelAnimationFrame(raf.current);
  }, [ms]);
  return (
    <svg className="hold-ring" width={BOX} height={BOX} viewBox={`0 0 ${BOX} ${BOX}`} aria-hidden>
      <path
        d={OUTLINE_PATH}
        fill="none"
        stroke="rgba(0,0,0,.28)"
        strokeWidth="4"
        style={{ opacity: ms > 0 ? 1 : 0, transition: 'opacity 120ms' }}
      />
      <path
        d={OUTLINE_PATH}
        pathLength={100}
        fill="none"
        stroke={accent ?? 'currentColor'}
        strokeWidth="2.25"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeDasharray={100}
        strokeDashoffset={full ? 0 : 100}
        style={{
          transition: full ? `stroke-dashoffset ${ms}ms linear` : 'stroke-dashoffset 180ms ease-out',
          opacity: ms > 0 || full ? 1 : 0,
        }}
      />
    </svg>
  );
}
