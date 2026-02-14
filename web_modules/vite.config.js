import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: '../web',
    emptyOutDir: false, // Don't delete Flutter's files
    lib: {
      entry: 'hms-setup.js',
      name: 'HMSSetup',
      fileName: 'hms-bundle',
      formats: ['iife'] // Immediately Invoked Function Expression for browser
    },
    rollupOptions: {
      output: {
        // Put everything in one file
        inlineDynamicImports: true,
        // Don't wrap in var, execute directly
        extend: true,
        // Ensure window globals are set
        globals: {}
      }
    }
  }
});
