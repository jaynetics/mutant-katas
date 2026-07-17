# frozen_string_literal: true
#
# Build-time patch, loaded via RUBYOPT=-r before `rbwasm` runs.
#
# ruby_wasm hardcodes the set of gems excluded from the packed module
# (RubyWasm::Packager::EXCLUDED_GEMS = %w[ruby_wasm bundler]) with no user hook.
# We add irb, reline, and io-console: they are only transitive mutant deps for
# its interactive CLI command, they are never used by the kata runner, and
# io-console ships a C extension that cannot cross-compile to WASI. The runner
# provides pure-Ruby stubs (ruby/stubs/) so `require "irb"` / `require
# "io/console"` still succeed at load time.
require "ruby_wasm"

module RubyWasm
  class Packager
    remove_const(:EXCLUDED_GEMS)
    EXCLUDED_GEMS = %w[ruby_wasm bundler irb reline io-console].freeze
  end
end
