import { describe, it, expect } from "vitest";
import { APP_NAME } from "./types";

describe("scaffold", () => {
  it("exposes the app name", () => {
    expect(APP_NAME).toBe("Mutant Katas");
  });
});
