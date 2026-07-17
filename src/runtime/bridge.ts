import { File, OpenFile, PreopenDirectory, WASI } from "@bjorn3/browser_wasi_shim";
import { RubyVM } from "@ruby/wasm-wasi/dist/vm";
import type { KataResult } from "../types";

export interface Runtime {
  runKata(input: { source: string; spec: string; subject: string }): Promise<KataResult>;
}

// The boot sequence proven during the Task 2 feasibility spike. Order matters:
// rubygems (for Gem::Version) -> no-op `gem` -> gem load paths (excluding the
// prism C-ext gem) -> stubs first -> preload deps -> load the runner. The vendor
// path glob is Ruby-version-agnostic (matches whatever api-version pack.sh staged).
const BOOT: string[] = [
  'require "rubygems"',
  "module Kernel; def gem(*) = nil; private :gem; end",
  'Dir["/app/vendor/bundle/ruby/*/gems/*/lib"].each { |p| $LOAD_PATH.unshift(p) unless p.include?("/prism-") }',
  '$LOAD_PATH.unshift("/app/stubs")',
  'require "parser/current"',
  'require "diff/lcs"',
  'require "regexp_parser"',
  'require "sorbet-runtime"',
  'require "unparser"',
  'require "rspec/core"',
  'require "/app/runner"',
];

// Base64 that is safe for arbitrary UTF-8 source (btoa alone mishandles it).
function toBase64(s: string): string {
  const bytes = new TextEncoder().encode(s);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

export async function bootRuntime(wasmBytes: ArrayBuffer): Promise<Runtime> {
  // Writable "/" via browser_wasi_shim (coexists with wasi-vfs serving /app);
  // the runner writes source under /kata on this FS.
  const fds = [
    new OpenFile(new File([])),
    new OpenFile(new File([])),
    new OpenFile(new File([])),
    new PreopenDirectory("/", new Map()),
  ];
  const wasi = new WASI([], [], fds, { debug: false });
  const mod = await WebAssembly.compile(wasmBytes);
  const { vm } = await RubyVM.instantiateModule({ module: mod, wasip1: wasi });
  for (const line of BOOT) vm.eval(line);

  return {
    async runKata({ source, spec, subject }) {
      const code =
        `Runner.call(` +
        `source: ${JSON.stringify(toBase64(source))}.unpack1("m"), ` +
        `spec: ${JSON.stringify(toBase64(spec))}.unpack1("m").gsub(/^require_relative.*\\n/, ""), ` +
        `subject: ${JSON.stringify(subject)})`;
      return JSON.parse(vm.eval(code).toString()) as KataResult;
    },
  };
}
