// @vitest-environment happy-dom
import {describe, it, expect, beforeEach} from "vitest"
import {renderResult} from "./results"

describe("renderResult", () => {
  let root: HTMLElement
  beforeEach(() => {
    root = document.createElement("div")
  })

  const failure = {
    description: "Person#adult? age 18",
    location: "spec.rb:4",
    message: "expected: true\n     got: false\n\n(compared using ==)",
  }

  it("gates on a red suite", () => {
    const r = renderResult(root, {status: "red", failures: [failure]})
    expect(r.solved).toBe(false)
    expect(root.textContent).toContain("make your tests pass")
    expect(root.textContent).toContain("age 18")
  })

  it("shows each failing spec's location and full message", () => {
    renderResult(root, {status: "red", failures: [failure]})
    const card = root.querySelector(".failure")!
    expect(card.querySelector(".location")?.textContent).toBe("spec.rb:4")
    const message = card.querySelector(".failure-message")
    expect(message?.textContent).toContain("expected: true")
    expect(message?.textContent).toContain("got: false")
    expect(message?.textContent).toContain("(compared using ==)")
    expect(message?.tagName).toBe("PRE") // keeps RSpec's own layout and diff
  })

  it("lists every failing spec", () => {
    renderResult(root, {
      status: "red",
      failures: [failure, {...failure, description: "Person#adult? age 17"}],
    })
    const cards = [...root.querySelectorAll(".failure")]
    expect(cards.map((c) => c.querySelector(".failure-title")?.textContent)).toEqual([
      "Person#adult? age 18",
      "Person#adult? age 17",
    ])
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
