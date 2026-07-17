// @vitest-environment happy-dom
import { describe, it, expect, beforeEach } from "vitest";
import { markSolved, isSolved } from "./completion";

describe("completion state", () => {
  beforeEach(() => localStorage.clear());

  it("persists solved katas", () => {
    expect(isSolved("001")).toBe(false);
    markSolved("001");
    expect(isSolved("001")).toBe(true);
  });
});
