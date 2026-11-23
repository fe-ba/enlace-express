import { defineConfig } from 'vite';

// El desarrollo usa el servidor de Vite con proxy de /api hacia Spring Boot (mismo origen para el navegador).
// La compilacion deja los archivos planos en la carpeta estatica de Spring Boot (no se versiona).
export default defineConfig({
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8080',
    },
  },
  build: {
    outDir: '../backend/src/main/resources/static',
    emptyOutDir: true,
    sourcemap: false,
  },
});
