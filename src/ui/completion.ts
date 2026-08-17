const KEY = "mutant-katas:solved";
const CURRENT_KEY = "mutant-katas:current";

function solvedSet(): Set<string> {
  try {
    return new Set(JSON.parse(localStorage.getItem(KEY) ?? "[]"));
  } catch {
    return new Set();
  }
}

export function isSolved(id: string): boolean {
  return solvedSet().has(id);
}

export function markSolved(id: string): void {
  const s = solvedSet();
  s.add(id);
  localStorage.setItem(KEY, JSON.stringify([...s]));
}

export function rememberKata(id: string): void {
  localStorage.setItem(CURRENT_KEY, id);
}

// Which kata to open on load: the one the learner was last on — so going back to an
// earlier kata survives a refresh — else the first unsolved one, else the last. A
// remembered id that no longer exists (kata renamed or removed) falls back the same way.
export function resumeIndex(ids: string[]): number {
  const remembered = ids.indexOf(localStorage.getItem(CURRENT_KEY) ?? "");
  if (remembered !== -1) return remembered;
  const unsolved = ids.findIndex((id) => !isSolved(id));
  return unsolved === -1 ? ids.length - 1 : unsolved;
}

// Whether solving the kata at `index` finishes the whole set: it has to be the last kata,
// and every earlier one already solved. Solving an earlier kata again finishes nothing,
// even when the rest is already done.
export function completesEveryKata(ids: string[], index: number): boolean {
  return index === ids.length - 1 && ids.every((id, i) => i === index || isSolved(id));
}
