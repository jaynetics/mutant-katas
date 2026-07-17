#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI wrapper around the in-browser runner: reads {source, spec, subject} as JSON
# on stdin and prints the runner's JSON result. Used by the katas spec so the
# runner's in-process RSpec.reset can't clobber the RSpec suite driving the spec.
require "json"
require_relative "runner"

input = JSON.parse($stdin.read)
print Runner.call(
  source: input.fetch("source"),
  spec: input.fetch("spec"),
  subject: input.fetch("subject")
)
