import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://autom8.oslabs.com.br',
  vite: {
    plugins: [tailwindcss()]
  }
});
