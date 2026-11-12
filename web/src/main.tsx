import '@fontsource/geist-sans/500.css';
import '@fontsource/geist-sans/600.css';
import '@fontsource/geist-sans/700.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import './styles.css';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import { handle, type Message } from './store';
import { runMock } from './mock';

// The game talks to the page with SendDuiMessage (a JSON string in a window message).
window.addEventListener('message', (e: MessageEvent) => {
  let m: unknown = e.data;
  if (typeof m === 'string') {
    try {
      m = JSON.parse(m);
    } catch {
      return;
    }
  }
  if (m && typeof m === 'object' && 'type' in m) handle(m as Message);
});

// Opened in a browser with #mock (vite dev / preview): a scripted run of every state, over an
// optional background shot (#mock&bg=<url>), for working on the look without the game.
// #shot=<messages> shows one state, given as a JSON array of the messages above, for README pictures.
const hash = new URLSearchParams(location.hash.slice(1));
const mock = hash.has('mock');
const shot = hash.get('shot');
const mockBg = mock || shot ? (hash.get('bg') ?? undefined) : undefined;

createRoot(document.getElementById('root')!).render(<App mockBg={mockBg} />);

if (mock) runMock(hash.get('step'));

if (shot) {
  handle({ type: 'init', scale: 1 });
  (JSON.parse(shot) as Message[]).forEach(handle);
}
