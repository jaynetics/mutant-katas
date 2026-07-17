#!/usr/bin/env ruby
# frozen_string_literal: true

# Compiles katas/*.md -> src/katas/katas.json (a sorted array of kata hashes) for
# the browser app to import. Uses only stdlib (yaml/json) — no bundle needed.
# Run via `npm run compile:katas`; the pre{dev,build,test} npm hooks keep it fresh.

require_relative "kata"
require "json"

root  = File.expand_path("..", __dir__)
files = Dir[File.join(root, "katas", "*.md")].sort
katas = files.map { |path| Kata.load(path) }

out = File.join(root, "src", "katas", "katas.json")
File.write(out, "#{JSON.pretty_generate(katas)}\n")
puts "compiled #{katas.length} katas -> #{out.sub("#{root}/", "")}"
