const KEY = "mutant-katas:solved";

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
