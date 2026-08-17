import { Compartment, EditorState, type Extension } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { StreamLanguage, syntaxHighlighting, defaultHighlightStyle } from "@codemirror/language";
import { ruby } from "@codemirror/legacy-modes/mode/ruby";
import { oneDark } from "@codemirror/theme-one-dark";
import type { Kata, EditableFile } from "../types";

export interface EditorHandles {
  getSource(): string;
  getSpec(): string;
  setSource(text: string): void;
  setSpec(text: string): void;
}

// Without a dark theme CodeMirror styles the editor for a light background: a black caret
// and dark token colours, both unreadable on the dark page. One Dark supplies both, and
// supersedes the fallback highlight style below. A theme is a static extension, so it lives
// in a compartment that gets swapped when the OS colour scheme changes.
const themeCompartment = new Compartment();
const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");
const themeFor = (dark: boolean): Extension => (dark ? oneDark : []);

// The panes of the kata currently open, so the listener reconfigures those and not the
// detached views of katas visited earlier.
let panes: EditorView[] = [];
darkQuery.addEventListener("change", () => {
  const effects = themeCompartment.reconfigure(themeFor(darkQuery.matches));
  for (const pane of panes) pane.dispatch({ effects });
});

// Replace a view's whole document. Works even on a read-only (locked) pane, since
// readOnly only blocks user input, not programmatic transactions.
function setContent(view: EditorView, text: string): void {
  view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: text } });
}

function makePane(root: HTMLElement, label: string, doc: string, editable: boolean): EditorView {
  const wrap = document.createElement("section");
  wrap.className = "editor-pane";
  const heading = document.createElement("h3");
  heading.textContent = editable ? label : `${label} (locked)`;
  wrap.appendChild(heading);
  root.appendChild(wrap);

  const extensions = [
    history(),
    keymap.of([...defaultKeymap, ...historyKeymap]),
    StreamLanguage.define(ruby),
    syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
    themeCompartment.of(themeFor(darkQuery.matches)),
    EditorView.editable.of(editable),
    EditorState.readOnly.of(!editable),
  ];
  return new EditorView({ state: EditorState.create({ doc, extensions }), parent: wrap });
}

export function mountEditors(root: HTMLElement, kata: Kata): EditorHandles {
  // Release the previous kata's views (DOM observers, window handlers, print listener).
  // Dispatches to a destroyed view are no-ops, so lingering handles stay harmless.
  panes.forEach((pane) => pane.destroy());
  root.replaceChildren();
  const can = (f: EditableFile) => kata.meta.editable === f;
  const sourceView = makePane(root, "source.rb", kata.source, can("source"));
  const specView = makePane(root, "spec.rb", kata.spec, can("spec"));
  panes = [sourceView, specView];
  return {
    getSource: () => sourceView.state.doc.toString(),
    getSpec: () => specView.state.doc.toString(),
    setSource: (text) => setContent(sourceView, text),
    setSpec: (text) => setContent(specView, text),
  };
}
