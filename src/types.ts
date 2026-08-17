export const APP_NAME = "Mutant Katas";

export type EditableFile = "source" | "spec";

export interface KataMeta {
  title: string;
  subject: string; // mutant subject expression, e.g. "Person#adult?"
  editable: EditableFile; // the one buffer the learner may edit
  difficulty: number; // 1..5
  concepts: string[];
}

export interface Kata {
  id: string; // filename stem, e.g. "001-person-adult"
  meta: KataMeta;
  source: string; // starting source.rb
  spec: string; // starting spec.rb
  solution: string; // reference version of the editable buffer
  explanation: string; // markdown shown on success
}

export interface Mutant {
  id: string;
  diff: string; // unified diff of the mutation
  location: string; // "path:line"
}

export interface SpecFailure {
  description: string; // RSpec's full description, e.g. "Person#adult? at 18"
  location: string; // "spec.rb:4" — where the failing example is defined
  message: string; // RSpec's failure message verbatim, diff and all
}

export type KataResult =
  | { status: "red"; failures: SpecFailure[] } // suite failing; no mutation run
  | { status: "green"; total: number; killed: number; alive: Mutant[] }
  | { status: "error"; message: string };
