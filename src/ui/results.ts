import type { KataResult } from "../types";

function el(tag: string, className: string, text?: string): HTMLElement {
  const n = document.createElement(tag);
  n.className = className;
  if (text !== undefined) n.textContent = text;
  return n;
}

export function renderResult(
  root: HTMLElement,
  result: KataResult,
  successMessage = "No mutations left 🎉",
): { solved: boolean } {
  root.replaceChildren();

  if (result.status === "error") {
    root.appendChild(el("div", "error", `Error: ${result.message}`));
    return { solved: false };
  }

  if (result.status === "red") {
    root.appendChild(el("div", "gate", "Your suite is red — make your tests pass first."));
    const list = el("ul", "failures");
    for (const f of result.failures) list.appendChild(el("li", "failure", f));
    root.appendChild(list);
    return { solved: false };
  }

  if (result.alive.length === 0) {
    root.appendChild(el("div", "success", successMessage));
    return { solved: true };
  }

  const survivors = el("div", "survivors");
  survivors.appendChild(el("h4", "survivors-title", "These mutations survive the tests"));
  for (const m of result.alive) {
    const card = el("div", "survivor");
    card.appendChild(el("code", "location", m.location));
    const diff = el("pre", "diff");
    for (const line of m.diff.split("\n")) {
      const cls = line.startsWith("+") ? "diff-add" : line.startsWith("-") ? "diff-del" : "diff-ctx";
      const span = el("span", cls, line);
      span.style.display = "block";
      diff.appendChild(span);
    }
    card.appendChild(diff);
    survivors.appendChild(card);
  }
  root.appendChild(survivors);
  return { solved: false };
}
