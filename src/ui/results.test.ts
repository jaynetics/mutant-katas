// @vitest-environment happy-dom
import {describe, it, expect, beforeEach} from "vitest"
import {renderResult} from "./results"

describe("renderResult", () => {
  let root: HTMLElement
  beforeEach(() => {
    root = document.createElement("div")
  })

  it("gates on a red suite", () => {
    const r = renderResult(root, {
      status: "red",
      failures: ["Person#adult? age 18"],
    })
    expect(r.solved).toBe(false)
    expect(root.textContent).toContain("make your tests pass")
    expect(root.textContent).toContain("age 18")
  })

  it("shows only surviving-mutant diffs when green (no killed count)", () => {
    const r = renderResult(root, {
      status: "green",
      total: 9,
      killed: 7,
      alive: [
        {id: "m1", diff: "- @age >= 18\n+ @age > 18", location: "source.rb:2"},
      ],
    })
    expect(r.solved).toBe(false)
    expect(root.querySelector(".survivor")?.textContent).toContain("@age > 18")
    expect(root.textContent).not.toContain("7 / 9") // no killed score
    expect(root.querySelector(".score")).toBeNull()
  })

  it("reports solved with a success message when all mutants killed", () => {
    const r = renderResult(root, {
      status: "green",
      total: 9,
      killed: 9,
      alive: [],
    })
    expect(r.solved).toBe(true)
    expect(root.textContent).toContain("No mutations left")
    expect(root.textContent).not.toMatch(/killed ✓|9 \/ 9/)
  })

  it("uses a custom success message when one is given", () => {
    const r = renderResult(
      root,
      {status: "green", total: 3, killed: 3, alive: []},
      "You finished everything!",
    )
    expect(r.solved).toBe(true)
    expect(root.querySelector(".success")?.textContent).toBe(
      "You finished everything!",
    )
  })

  it("shows an error state", () => {
    const r = renderResult(root, {status: "error", message: "boom"})
    expect(r.solved).toBe(false)
    expect(root.textContent).toContain("boom")
  })
})
