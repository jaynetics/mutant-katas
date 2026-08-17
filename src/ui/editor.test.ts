// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mountEditors } from "./editor";
import type { Kata } from "../types";

const kata: Kata = {
  id: "t",
  meta: {
    title: "t",
    subject: "Person#adult?",
    editable: "spec",
    difficulty: 1,
    concepts: [],
  },
  source: "class Person; end",
  spec: "RSpec.describe(Person) {}",
  solution: "RSpec.describe(Person) {}", // the editable buffer only
  explanation: "",
};

const realMatchMedia = window.matchMedia.bind(window);

// happy-dom's simulated device drives matchMedia, so we can mount as if the OS were dark.
const device = (
  window as unknown as { happyDOM: { settings: { device: { prefersColorScheme: string } } } }
).happyDOM.settings.device;

describe("mountEditors", () => {
  let root: HTMLElement;
  beforeEach(() => {
    root = document.createElement("div");
    document.body.appendChild(root);
  });
  afterEach(() => {
    device.prefersColorScheme = "light";
  });

  it("exposes current buffer contents", () => {
    const h = mountEditors(root, kata);
    expect(h.getSource()).toContain("class Person");
    expect(h.getSpec()).toContain("RSpec");
  });

  it("renders two editor panes", () => {
    mountEditors(root, kata);
    expect(root.querySelectorAll(".cm-editor").length).toBe(2);
  });

  it("marks the locked (source) pane read-only and the editable (spec) pane editable", () => {
    mountEditors(root, kata);
    const headings = [...root.querySelectorAll("h3")].map((h) => h.textContent);
    expect(headings).toContain("source.rb (locked)");
    expect(headings).toContain("spec.rb");
  });

  // CodeMirror's base theme hard-codes a black caret and a dark-on-light token palette
  // for any editor without a dark theme, both unreadable on the dark background.
  it("gives the caret One Dark's cursor colour when the page is dark, not the base black", () => {
    device.prefersColorScheme = "dark";
    mountEditors(root, kata);
    const carets = [...root.querySelectorAll(".cm-content")].map(
      (el) => getComputedStyle(el).caretColor,
    );
    expect(carets).toEqual(["#528bff", "#528bff"]);
  });

  it("highlights Ruby with the dark palette when the page is dark", () => {
    device.prefersColorScheme = "dark";
    mountEditors(root, kata);
    const keyword = root.querySelector(".cm-line span")!; // `class` in the source pane
    expect(keyword.textContent).toBe("class");
    expect(getComputedStyle(keyword).color).toBe("#c678dd");
  });

  it("keeps the light palette when the page is light", () => {
    device.prefersColorScheme = "light";
    mountEditors(root, kata);
    const keyword = root.querySelector(".cm-line span")!;
    expect(getComputedStyle(keyword).color).toBe("#708");
  });

  // happy-dom never fires the media query's change event, so these mount against a
  // controllable stand-in query to drive the listener the module registers on import.
  describe("when the OS colour scheme changes while the page is open", () => {
    let query: { matches: boolean; addEventListener(type: string, fn: () => void): void };
    let notify: () => void;
    let mount: typeof mountEditors;

    beforeEach(async () => {
      const listeners: (() => void)[] = [];
      query = { matches: false, addEventListener: (_type, fn) => listeners.push(fn) };
      notify = () => listeners.forEach((fn) => fn());
      // Only the colour-scheme query is ours; CodeMirror itself watches `print`.
      vi.stubGlobal("matchMedia", (q: string) =>
        q.includes("prefers-color-scheme") ? query : realMatchMedia(q),
      );
      vi.resetModules();
      mount = (await import("./editor")).mountEditors;
    });
    afterEach(() => vi.unstubAllGlobals());

    const keywordColour = () => getComputedStyle(root.querySelector(".cm-line span")!).color;

    it("re-themes the open panes in both directions", () => {
      mount(root, kata);
      expect(keywordColour()).toBe("#708");
      query.matches = true;
      notify();
      expect(keywordColour()).toBe("#c678dd");
      query.matches = false;
      notify();
      expect(keywordColour()).toBe("#708");
    });

    it("re-themes the panes of the kata opened most recently", () => {
      mount(root, kata);
      mount(root, kata); // navigating to another kata remounts both panes
      query.matches = true;
      notify();
      expect(keywordColour()).toBe("#c678dd");
    });
  });

  it("setSource/setSpec replace buffer contents, even on a locked pane", () => {
    const h = mountEditors(root, kata); // source is locked here
    h.setSource("class Cat; end");
    h.setSpec("RSpec.describe(Cat) {}");
    expect(h.getSource()).toBe("class Cat; end");
    expect(h.getSpec()).toBe("RSpec.describe(Cat) {}");
  });
});
