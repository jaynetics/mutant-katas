import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Default to node; DOM tests opt in per-file with `// @vitest-environment jsdom`.
    environment: "node",
  },
});
