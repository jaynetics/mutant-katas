import { describe, it, expect } from "vitest";
import { loadKatas } from "./load";

describe("loadKatas", () => {
  it("loads and sorts katas by id", () => {
    const katas = loadKatas();
    expect(katas.length).toBeGreaterThan(0);
    expect(katas[0].id).toBe("000-hello-world");
    const ids = katas.map((k) => k.id);
    expect([...ids].sort()).toEqual(ids);
  });
});
