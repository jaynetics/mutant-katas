import { EditorState } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { StreamLanguage, syntaxHighlighting, defaultHighlightStyle } from "@codemirror/language";
import { ruby } from "@codemirror/legacy-modes/mode/ruby";
import type { Kata, EditableFile } from "../types";

export interface EditorHandles {
  getSource(): string;
  getSpec(): string;
  setSource(text: string): void;
  setSpec(text: string): void;
}

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
    EditorView.editable.of(editable),
    EditorState.readOnly.of(!editable),
  ];
  return new EditorView({ state: EditorState.create({ doc, extensions }), parent: wrap });
}

export function mountEditors(root: HTMLElement, kata: Kata): EditorHandles {
  root.replaceChildren();
  const can = (f: EditableFile) => kata.meta.editable.includes(f);
  const sourceView = makePane(root, "source.rb", kata.source, can("source"));
  const specView = makePane(root, "spec.rb", kata.spec, can("spec"));
  return {
    getSource: () => sourceView.state.doc.toString(),
    getSpec: () => specView.state.doc.toString(),
    setSource: (text) => setContent(sourceView, text),
    setSpec: (text) => setContent(specView, text),
  };
}
