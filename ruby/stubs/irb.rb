# frozen_string_literal: true
#
# WASM stub for `irb`. Mutant hard-depends on irb only for its `mutant environment
# irb` CLI command (TOPLEVEL_BINDING.irb), which the kata runner never invokes.
# The real irb pulls in reline -> io-console, whose C extension does not
# cross-compile to WASI. Loading this stub instead breaks that chain at the root.
# Defines just enough for `require "irb"` to succeed at mutant load time.
#
# Note: mutant references `Tempfile` but never requires "tempfile" itself — it
# relied on the real irb pulling it in transitively. tempfile is pure-Ruby
# stdlib (wasm-safe), so we require it here to preserve that.
require "tempfile"

module IRB; end
