// @vitest-environment happy-dom
import { describe, it, expect, beforeEach } from "vitest";
import { markSolved, isSolved, rememberKata, resumeIndex, completesEveryKata } from "./completion";

describe("completion state", () => {
  beforeEach(() => localStorage.clear());

  it("persists solved katas", () => {
    expect(isSolved("001")).toBe(false);
    markSolved("001");
    expect(isSolved("001")).toBe(true);
  });
});

describe("resumeIndex", () => {
  const ids = ["000-first", "010-second", "020-third"];
  beforeEach(() => localStorage.clear());

  it("returns the kata last opened, even when a later one is already solved", () => {
    markSolved("000-first");
    rememberKata("000-first");
    expect(resumeIndex(ids)).toBe(0);
  });

  it("returns the first unsolved kata when none was opened before", () => {
    markSolved("000-first");
    expect(resumeIndex(ids)).toBe(1);
  });

  it("falls back to the first unsolved kata when the remembered one is gone", () => {
    markSolved("000-first");
    rememberKata("005-removed");
    expect(resumeIndex(ids)).toBe(1);
  });

  it("returns the last kata once everything is solved", () => {
    ids.forEach(markSolved);
    expect(resumeIndex(ids)).toBe(2);
  });
});

describe("completesEveryKata", () => {
  const ids = ["000-first", "010-second", "020-third"];
  beforeEach(() => localStorage.clear());

  it("is true on the last kata once every earlier one is solved", () => {
    markSolved("000-first");
    markSolved("010-second");
    expect(completesEveryKata(ids, 2)).toBe(true);
  });

  // Solving an earlier kata again finishes nothing, however much is already solved.
  it("is false on an earlier kata, even when everything else is solved", () => {
    ids.forEach(markSolved);
    expect(completesEveryKata(ids, 0)).toBe(false);
    expect(completesEveryKata(ids, 1)).toBe(false);
  });

  it("is false on the last kata while an earlier one is unsolved", () => {
    markSolved("000-first");
    expect(completesEveryKata(ids, 2)).toBe(false);
  });

  it("is true for a single kata, which is also the last one", () => {
    expect(completesEveryKata(["000-only"], 0)).toBe(true);
  });
});
