import { defineConfig } from "vite";

export default defineConfig({
  // ruby.wasm is large; keep it as a static asset served from /public.
  assetsInclude: ["**/*.wasm"],
  // GitHub Pages base path (adjust to the deploy target in Task 11).
  base: "/mutant-katas/",
});
