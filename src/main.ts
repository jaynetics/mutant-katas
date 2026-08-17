import { loadKatas } from "./katas/load";
import { markSolved, isSolved, rememberKata, resumeIndex, completesEveryKata } from "./ui/completion";
import { mountEditors, type EditorHandles } from "./ui/editor";
import { renderResult } from "./ui/results";
import { bootRuntime, type Runtime } from "./runtime/bridge";
import "./style.css";

const app = document.querySelector<HTMLDivElement>("#app")!;
app.innerHTML = `
  <main>
    <p id="progress"></p>
    <h1 id="kata-title"></h1>
    <div id="editors"></div>
    <div id="controls">
      <button id="run" disabled>Booting Ruby…</button>
      <button id="hint" type="button">Hint</button>
      <button id="show-solution" type="button">Show solution</button>
    </div>
    <div id="explanation" hidden></div>
    <div id="results"></div>
    <nav id="kata-nav">
      <button id="prev" hidden>← Previous kata</button>
      <button id="next" hidden>Next kata →</button>
    </nav>
  </main>`;

const katas = loadKatas();
const $ = <T extends HTMLElement>(sel: string) => document.querySelector<T>(sel)!;

const FINAL_MESSAGE =
  "🎉 That's every kata solved! Your tests now catch the mutations that slip past weaker specs. Thanks for playing!";

let runtime: Runtime | null = null;
let index = 0;
let handles: EditorHandles | null = null;

// Prev is available whenever there's an earlier kata; Next once the current kata
// has been solved (this session or previously) and a later kata exists.
function updateNav() {
  $<HTMLButtonElement>("#prev").hidden = index === 0;
  $<HTMLButtonElement>("#next").hidden = !(isSolved(katas[index].id) && index + 1 < katas.length);
}

function open(i: number) {
  index = i;
  const kata = katas[i];
  rememberKata(kata.id); // so a refresh reopens this kata, not the furthest one reached
  $("#progress").textContent = `Kata ${i + 1} of ${katas.length}`;
  $("#kata-title").textContent = kata.meta.title;
  handles = mountEditors($("#editors"), kata);
  $("#results").replaceChildren();
  const explanation = $<HTMLDivElement>("#explanation");
  explanation.innerHTML = kata.explanation; // compiled HTML (escaped + <code>) from ruby/kata.rb
  explanation.hidden = true;
  updateNav();
}

// Wait for the browser to paint. runKata runs synchronously in the wasm VM and
// blocks the main thread, so without yielding first the loading state never
// renders — the UI would just freeze until results appear.
const nextPaint = () =>
  new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve())));

async function run() {
  if (!runtime || !handles) return;
  const kata = katas[index];
  const btn = $<HTMLButtonElement>("#run");
  btn.disabled = true;
  btn.classList.add("running");
  btn.textContent = "Running mutant…";
  await nextPaint();
  try {
    const result = await runtime.runKata({
      source: handles.getSource(),
      spec: handles.getSpec(),
      subject: kata.meta.subject,
    });
    // A joyful message when this solve finishes the set, which only the last kata can do.
    const willSolve = result.status === "green" && result.alive.length === 0;
    const finishes = willSolve && completesEveryKata(katas.map((k) => k.id), index);
    const { solved } = renderResult($("#results"), result, finishes ? FINAL_MESSAGE : undefined);
    if (solved) markSolved(kata.id); // the explanation is revealed only via the Hint button
    updateNav();
  } catch (error) {
    // A failure inside the VM (its linear memory only ever grows, and past ~2 GB the JS
    // bridge throws) escapes Ruby's own rescue. Without this the button would just be
    // re-enabled with nothing rendered, which reads as "Run does nothing".
    const message = error instanceof Error ? error.message : String(error);
    renderResult($("#results"), { status: "error", message: `${message} — reload the page to continue.` });
  } finally {
    btn.disabled = false;
    btn.classList.remove("running");
    btn.textContent = "Run";
  }
}

open(resumeIndex(katas.map((k) => k.id)));

$("#run").addEventListener("click", run);
$("#hint").addEventListener("click", () => {
  const explanation = $<HTMLDivElement>("#explanation");
  explanation.hidden = !explanation.hidden; // toggle the explanation as a hint
});
$("#show-solution").addEventListener("click", () => {
  if (!handles) return;
  const kata = katas[index];
  // The solution is the reference version of the editable buffer; the other one never changes.
  if (kata.meta.editable === "source") handles.setSource(kata.solution);
  else handles.setSpec(kata.solution);
  $<HTMLDivElement>("#explanation").hidden = false; // solution comes with the explanation
});
$("#prev").addEventListener("click", () => open(index - 1));
$("#next").addEventListener("click", () => open(index + 1));

// Fetch the packed module and boot (bridge takes ArrayBuffer — see Task 3).
fetch(`${import.meta.env.BASE_URL}ruby.wasm`)
  .then((r) => r.arrayBuffer())
  .then(bootRuntime)
  .then((rt) => {
    runtime = rt;
    const btn = $<HTMLButtonElement>("#run");
    btn.disabled = false;
    btn.textContent = "Run";
  });
