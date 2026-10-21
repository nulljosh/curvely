import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// ponytail: app lives at /app so landing/index.html can own the root.
export default defineConfig({
  base: '/app/',
  build: { outDir: 'dist/app', emptyOutDir: true },
  plugins: [react()],
  server: { port: 5174 },
});
