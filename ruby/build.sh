#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Builds ruby.wasm with the Gemfile's gems (rspec, mutant, mutant-rspec, js)
# packed into an in-memory VFS, plus runner.rb mapped to /runner.rb, and a
# writable /kata dir the runner writes source into.
#
# Requires: ruby_wasm (rbwasm) installed, and `bundle install` already run.

OUT="../public/ruby.wasm"
mkdir -p ../public

export BUNDLE_GEMFILE="$PWD/Gemfile"
# Preload the packager patch that excludes irb/reline/io-console (io-console's
# C extension cannot cross-compile to WASI; the runner stubs them at runtime).
export RUBYOPT="-r$PWD/wasm_build_patch.rb"
bundle exec rbwasm build --ruby-version 3.4 -o "$OUT"

echo "built $OUT"
ls -lh "$OUT"
