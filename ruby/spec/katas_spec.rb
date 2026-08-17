# frozen_string_literal: true

require "open3"
require "tmpdir"
require "json"
require_relative "../kata"

# runner.rb writes source into ENV["KATA_DIR"]; give the run_kata subprocess a
# writable dir (inherited via the environment).
ENV["KATA_DIR"] ||= Dir.mktmpdir
RUN_KATA = File.expand_path("../run_kata.rb", __dir__)

module KataValidation
  module_function

  # Ground truth: real fork-based mutant. Returns the number of surviving mutants.
  def fork_alive(source:, spec:, subject:)
    Dir.mktmpdir do |dir|
      File.write("#{dir}/source.rb", source)
      # mutant loads --require files during bootstrap, before the rspec integration
      # sets up RSpec — so the spec must load rspec + the subject itself.
      File.write("#{dir}/spec.rb", "require 'rspec'\nrequire_relative 'source'\n#{spec}")
      # --usage opensource: this is a public open-source teaching project.
      cmd = "bundle exec mutant run --usage opensource --integration rspec --jobs 1 " \
            "--require ./spec.rb -- '#{subject}'"
      out, _err, _st = Open3.capture3(cmd, chdir: dir)
      alive = out[/Alive:\s+(\d+)/, 1]
      raise "mutant produced no result for #{subject}:\n#{out}" unless alive
      alive.to_i
    end
  end

  # Browser path: the same hybrid runner that runs in ruby.wasm. Run in a
  # subprocess (run_kata.rb) so the runner's in-process RSpec.reset can't disturb
  # the RSpec suite driving this spec.
  def runner_alive(source:, spec:, subject:)
    input = JSON.generate("source" => source, "spec" => spec, "subject" => subject)
    out, err, status = Open3.capture3("bundle", "exec", "ruby", RUN_KATA, stdin_data: input)
    raise "run_kata failed:\n#{err}" unless status.success?
    result = JSON.parse(out[/\{.*\}/m])
    unless result["status"] == "green"
      raise "runner not green: #{result["status"]} #{result["failures"] || result["message"]}"
    end
    result["alive"].length
  end
end

RSpec.describe "katas" do
  Dir[File.expand_path("../../katas/*.md", __dir__)].sort.each do |path|
    kata = Kata.load(path)

    it "#{kata["id"]} is solvable and matches the in-browser runner", :aggregate_failures do
      subject    = kata.dig("meta", "subject")
      start      = kata["source"]
      start_spec = kata["spec"]
      # The solution replaces the one buffer the kata lets the learner edit; the other
      # stays as it starts. Real mutant needs both files either way.
      editable   = kata.dig("meta", "editable")
      sol_source = editable == "source" ? kata["solution"] : start
      sol_spec   = editable == "spec" ? kata["solution"] : start_spec

      sol_alive   = KataValidation.fork_alive(source: sol_source, spec: sol_spec, subject: subject)
      start_alive = KataValidation.fork_alive(source: start, spec: start_spec, subject: subject)

      expect(sol_alive).to eq(0), "solution should kill every mutant, #{sol_alive} survived"
      expect(start_alive).to be > 0, "starting state should leave survivors to teach the lesson"

      expect(KataValidation.runner_alive(source: start, spec: start_spec, subject: subject))
        .to eq(start_alive), "in-browser runner disagrees with fork mutant on starting survivors"
      expect(KataValidation.runner_alive(source: sol_source, spec: sol_spec, subject: subject))
        .to eq(sol_alive), "in-browser runner disagrees with fork mutant on the solution"
    end
  end
end
