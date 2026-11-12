import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The prompt page is loaded as a DUI (an off-screen browser the game paints with DrawSprite), from
// https://cfx-nui-sd-interact/web/build/index.html: relative asset paths, unhashed names to match the
// fxmanifest files{} globs, and FiveM's Chromium (103) as the target.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'build',
    emptyOutDir: true,
    assetsDir: 'assets',
    target: 'chrome103',
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]',
      },
    },
  },
});
