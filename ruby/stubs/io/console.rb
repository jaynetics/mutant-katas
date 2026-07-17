# frozen_string_literal: true
#
# WASM stub for `io/console` (a C extension that cannot cross-compile to WASI).
# Mutant's only use is CLI terminal-width detection in reporter/cli/format.rb,
# guarded by `tty? && respond_to?(:winsize)`. In the browser stdout is not a tty,
# so the guard short-circuits and no io/console methods are ever called. An empty
# stub therefore suffices; the kata runner emits JSON, not CLI-formatted output.
