# Mutant Katas

Mutant Katas is a browser-based set of exercises for learning mutation testing in Ruby. Each kata presents a small piece of Ruby code together with a test suite. The learner improves the tests until they detect every change ("mutation") that the [mutant](https://github.com/mbj/mutant) gem can make to the code. Everything runs in the browser; there is no server.

## Design goals

- Run the mutant gem in the browser, for real mutation testing without a server.
- Work entirely on the client as a static site that can be hosted anywhere.
- Keep katas self-contained and easy to author.
- Show clear feedback: the code changes that the tests failed to detect.

## Architecture

- **Two environments.** Katas are authored and validated offline with native Ruby. The application itself runs in the browser, with Ruby compiled to WebAssembly.
- **Kata format.** Each kata is a single Markdown file holding its metadata, starting code, starting tests, reference solution, and explanation. A Ruby tool parses the Markdown and compiles all katas to a JSON file that the frontend loads. Parsing exists only in Ruby so the app and the offline tooling cannot drift apart.
- **In-browser execution.** Ruby runs via ruby.wasm. The application uses mutant to generate the mutated versions of the code and to apply each one, then runs the test suite itself and resets test state between runs. It reports which mutations the tests failed to detect.
- **Packaging.** The browser build starts from an official prebuilt ruby.wasm binary and adds the pure-Ruby gems on top with wasi-vfs, instead of compiling a custom interpreter.
- **Frontend.** TypeScript with Vite and CodeMirror. The learner works through one kata at a time, with previous/next navigation and a hint that reveals the explanation.
- **Validation.** An offline RSpec spec runs the real fork-based mutant against every kata to confirm that each solution detects all mutations, that the starting tests leave some undetected, and that the in-browser runner produces the same result as native mutant.

## Authoring a kata

- Each kata is one Markdown file with frontmatter (title, subject, editable files, difficulty, concepts) and sections for the starting code, starting tests, reference solution, and explanation. A solution file that is omitted inherits the starting version.
- A valid kata must satisfy three conditions: the starting tests pass; the starting tests leave at least one mutation undetected (so there is something to fix); and the reference solution detects every mutation.
- The subject's code must not produce equivalent mutants: mutations that cannot change behaviour and therefore can never be detected by any test. These make a kata impossible to complete. In practice they come from adjacent `case`/`when` ranges and from comparisons where both sides of a boundary return the same value, so avoid those shapes when choosing subject code.
- Keep the subject free of unbounded loops and recursion, because a mutation could otherwise cause an infinite loop, which cannot be interrupted in the browser.
- The validation spec (`bundle exec rspec spec` in `ruby/`) checks all of this for every kata.

## Main issues found and how they were handled

- mutant isolates each mutation by forking a process and uses threads. WebAssembly (WASI) provides neither. The app therefore controls mutant manually to generate and insert mutations, and runs the test suite directly, resetting test state between mutations.
- RSpec keeps global state and considers all examples as seen when mutant calls it repeatedly in one process. The app drives RSpec directly instead of through mutant's RSpec integration.
- Compiling the Ruby interpreter to WebAssembly locally produced a broken interpreter that crashed on startup. The host Ruby version, the JavaScript binding version, and disabling gems were each ruled out as causes, leaving a bug in the local build toolchain. The build therefore uses an official prebuilt ruby.wasm as the base and adds gems separately. This is similar to [this approach taken by Evil Martians](https://evilmartians.com/chronicles/tutorialkit-rb-interactive-ruby-tutorials-entirely-in-the-browser).
- One dependency (mutant's unparser dependency) needs the prism parser, whose C extension cannot be added to the prebuilt base. Targeting Ruby 3.3 avoids this, because there that dependency uses a pure-Ruby parser and prism is not required.
- Loading mutant pulls in irb, which in turn pulls in a C-extension library that cannot run in WebAssembly. The app supplies small stand-in files for those libraries and excludes them from the browser bundle; the affected features are never used.
- Some mutations cannot be detected by any test because they do not change behaviour (equivalent mutants), which would make a kata impossible to complete by changing only the specs. Katas are written to avoid code that produces such mutations.
- A mutation could cause an infinite loop, which cannot be interrupted in the single-threaded browser environment. Kata code must be kept free of unbounded loops and recursion.
