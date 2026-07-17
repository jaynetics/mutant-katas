import { describe, it, expect } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { bootRuntime } from "./bridge";

const wasmPath = fileURLToPath(new URL("../../public/ruby.wasm", import.meta.url));
const maybe = existsSync(wasmPath) ? describe : describe.skip;

maybe("bridge (needs built ruby.wasm — run ruby/pack.sh first)", () => {
  const source =
    "class Person\n  def initialize(age:)\n    @age = age\n  end\n\n  def adult?\n    @age >= 18\n  end\nend\n";
  const weak =
    'RSpec.describe Person do\n  it("19") { expect(Person.new(age: 19).adult?).to be(true) }\n  it("17") { expect(Person.new(age: 17).adult?).to be(false) }\nend\n';
  const solution =
    'RSpec.describe Person do\n  it("19") { expect(Person.new(age: 19).adult?).to be(true) }\n  it("18") { expect(Person.new(age: 18).adult?).to be(true) }\n  it("17") { expect(Person.new(age: 17).adult?).to be(false) }\nend\n';

  it("reports surviving mutants for a weak spec", async () => {
    const rt = await bootRuntime(readFileSync(wasmPath).buffer);
    const r = await rt.runKata({ source, spec: weak, subject: "Person#adult?" });
    expect(r.status).toBe("green");
    if (r.status === "green") {
      expect(r.total).toBeGreaterThan(0);
      expect(r.alive.length).toBeGreaterThan(0);
      expect(r.alive.some((m) => m.diff.includes("@age > 18"))).toBe(true);
    }
  }, 120_000);

  it("reports 100% for the solution spec", async () => {
    const rt = await bootRuntime(readFileSync(wasmPath).buffer);
    const r = await rt.runKata({ source, spec: solution, subject: "Person#adult?" });
    expect(r.status).toBe("green");
    if (r.status === "green") expect(r.alive.length).toBe(0);
  }, 120_000);

  it("returns an error (not a crash) for a syntactically invalid spec", async () => {
    const rt = await bootRuntime(readFileSync(wasmPath).buffer);
    const r = await rt.runKata({ source, spec: "RSpec.describe Person do\n  it('x') {", subject: "Person#adult?" });
    expect(r.status).toBe("error");
    if (r.status === "error") expect(r.message).toContain("SyntaxError");
  }, 120_000);

  it("returns an error for syntactically invalid source", async () => {
    const rt = await bootRuntime(readFileSync(wasmPath).buffer);
    const r = await rt.runKata({ source: "class Person\n  def adult?\n", spec: weak, subject: "Person#adult?" });
    expect(r.status).toBe("error");
    if (r.status === "error") expect(r.message).toContain("SyntaxError");
  }, 120_000);
});
