import { CANVAS, Prompt } from './Prompt';
import { usePrompt } from './store';

/**
 * The canvas at the game's scale: the DUI is created CANVAS x scale pixels big (scale = the screen's
 * height over 1080, times the configured size), and zoom draws the 1080p layout at that size so text
 * stays sharp instead of being stretched by the sprite.
 */
export function App({ mockBg }: { mockBg?: string }) {
  const scale = usePrompt((s) => s.scale);
  return (
    <>
      {mockBg ? <div className="mock-bg" style={{ backgroundImage: `url(${mockBg})` }} /> : null}
      <div className="canvas" style={{ width: CANVAS.w, height: CANVAS.h, zoom: scale }}>
        <Prompt />
      </div>
    </>
  );
}
