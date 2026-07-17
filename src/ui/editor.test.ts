// @vitest-environment happy-dom
import { describe, it, expect, beforeEach } from "vitest";
import { mountEditors } from "./editor";
import type { Kata } from "../types";

const kata: Kata = {
  id: "t",
  meta: {
    title: "t",
    subject: "Person#adult?",
    editable: ["spec"],
   
    difficulty: 1,
    concepts: [],
  },
  source: "class Person; end",
  spec: "RSpec.describe(Person) {}",
  solution: { source: "class Person; end", spec: "RSpec.describe(Person) {}" },
  explanation: "",
};

describe("mountEditors", () => {
  let root: HTMLElement;
  beforeEach(() => {
    root = document.createElement("div");
    document.body.appendChild(root);
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

  it("setSource/setSpec replace buffer contents, even on a locked pane", () => {
    const h = mountEditors(root, kata); // source is locked here
    h.setSource("class Cat; end");
    h.setSpec("RSpec.describe(Cat) {}");
    expect(h.getSource()).toBe("class Cat; end");
    expect(h.getSpec()).toBe("RSpec.describe(Cat) {}");
  });
});
