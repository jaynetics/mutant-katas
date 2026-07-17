import type { Kata } from "../types";
// Compiled from katas/*.md by ruby/compile_katas.rb (the pre{dev,build,test} npm
// hooks keep it fresh). Parsing lives in one place — Ruby — so the app and the
// validation harness never drift.
import katas from "./katas.json";

export function loadKatas(): Kata[] {
  return katas as unknown as Kata[];
}
