#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")" # ruby/

# Deferred packing (see evilmartians TutorialKit-rb article + design doc).
#
# WHY not a monolithic `rbwasm build`: our locally-built interpreter miscompiles
# `class_eval` (crashes at boot). The official prebuilt ruby.wasm binaries are
# known-good, so we use one as a base and layer our pure-Ruby gems onto it with
# `wasi-vfs pack` (seconds, no interpreter recompile).
#
# BASE = Ruby 3.3 specifically: unparser uses the pure-Ruby whitequark `parser`
# when RUBY_VERSION <= 3.4, and only pulls in the prism C-extension gem when
# > 3.4. Ruby 3.3 therefore avoids prism entirely (prism is a C ext and cannot
# be deferred-packed).
#
# Produces ../public/ruby.wasm. Requires: `npm install` (for the prebuilt base)
# and `bundle install` already run.

WASI_VFS_VERSION="0.5.0"
BASE="../node_modules/@ruby/3.3-wasm-wasi/dist/ruby+stdlib.wasm"
OUT="../public/ruby.wasm"
TOOLS="$PWD/.tools"
STAGE="$PWD/.stage"

[ -f "$BASE" ] || { echo "missing $BASE — run: npm install"; exit 1; }

# 1. Standalone gem bundle: pure-Ruby gems + a setup.rb that sets $LOAD_PATH
#    without rubygems. `without build` drops ruby_wasm (build-only).
#    Use env vars (not `bundle config set --local`) so this does NOT persist into
#    .bundle/config and hijack the regular `bundle exec` used for native runs.
export BUNDLE_GEMFILE="$PWD/Gemfile"
BUNDLE_PATH="$PWD/vendor/bundle" BUNDLE_WITHOUT="build" bundle install --standalone >/dev/null

# 2. wasi-vfs CLI (ruby_wasm only ships the library, not the packer CLI).
VFS="$TOOLS/wasi-vfs"
if [ ! -x "$VFS" ]; then
  mkdir -p "$TOOLS"
  arch="$(uname -m)"; [ "$arch" = "arm64" ] && arch="aarch64"  # release assets use aarch64
  host="${arch}-apple-darwin"; [ "$(uname)" = "Linux" ] && host="${arch}-unknown-linux-gnu"
  url="https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/wasi-vfs-cli-${host}.zip"
  echo "downloading wasi-vfs CLI: $url"
  curl -fsSL -o "$TOOLS/cli.zip" "$url"
  (cd "$TOOLS" && unzip -o cli.zip >/dev/null && chmod +x wasi-vfs)
fi

# 3. Stage the app files that get mapped to guest /app.
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp runner.rb "$STAGE/"
cp -R stubs "$STAGE/"
cp -R vendor "$STAGE/"

# Strip compiled native extensions from the staged bundle. We ship pure-Ruby gems
# only (prism is kept off the load path, io-console is stubbed, and racc/parser
# fall back to their pure-Ruby cores). The wasm runtime cannot load a native ext,
# but if one's filename matches what `require` searches for, loading it aborts
# boot with `... unimplemented on this machine (NotImplementedError)` instead of
# the LoadError that triggers the pure-Ruby fallback. This bites only on Linux
# (CI): there `bundle install` builds `racc/cparse.so`, whose `.so` name the wasm
# Ruby tries to load; on macOS the ext is a `.bundle`, which it ignores. Deleting
# them makes the pack platform-independent (and much smaller).
find "$STAGE/vendor" \( -name '*.so' -o -name '*.bundle' -o -name '*.o' \) -delete
rm -rf "$STAGE"/vendor/bundle/ruby/*/extensions

# 4. Deferred pack: layer /app onto the prebuilt base.
mkdir -p ../public
"$VFS" pack "$BASE" --mapdir /app::"$STAGE" -o "$OUT"
echo "packed $OUT"
ls -lh "$OUT"
