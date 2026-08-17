# frozen_string_literal: true

# In-browser kata runner.
#
# IMPORTANT ARCHITECTURE NOTE (proven by the Task 2 spike):
# Mutant's own run path (Mutation::Runner -> Parallel -> Worker) ALWAYS forks a
# worker process and spawns a thread, regardless of `isolation`. And the
# mutant-rspec integration is not re-entrant in-process (RSpec keeps global
# state in RSpec.world; after one run later runs see 0 examples). Neither works
# under ruby.wasm (no fork, no threads).
#
# So we use mutant ONLY for the parts that are pure and in-process:
#   1. mutation GENERATION (parse -> mutate -> unparse) via Bootstrap
#   2. mutation.insert (re-parses the source file, applies the mutation, evals)
# and we drive the RSpec kill-loop OURSELVES, resetting RSpec.world between
# mutations. This needs no fork, no threads, no subprocess.

# Prepend our stubs dir so `require "irb"` resolves to ruby/stubs/irb.rb (an empty
# stub) instead of the real irb -> reline -> io-console chain, whose C extension
# cannot cross-compile to WASI. Mutant only needs irb for its interactive CLI
# command, which the kata runner never calls. Must run before requiring mutant.
$LOAD_PATH.unshift(File.expand_path("stubs", __dir__))

require "json"
require "stringio"
require "rspec/core"

# unparser (a mutant dependency) uses the prism parser when RUBY_VERSION > 3.4 and
# the pure-Ruby whitequark parser otherwise. On Ruby > 3.4 (e.g. native 4.0) its
# `Builder < Prism::Translation::Parser::Builder` needs the translation layer fully
# loaded first (otherwise `modernize` is undefined). On the ruby.wasm 3.3 base
# unparser takes the whitequark path and prism must NOT be loaded (its C ext is
# absent / crashes). Gate the preload on the Ruby version accordingly.
if Gem::Version.new(RUBY_VERSION) > Gem::Version.new("3.4")
  require "prism"
  require "prism/translation/parser"
end

require "mutant"

module Runner
  # In wasm we preopen a writable in-memory dir at /kata; override for native tests.
  KATA_DIR      = ENV.fetch("KATA_DIR", "/kata")
  SOURCE_PATH   = File.join(KATA_DIR, "source.rb")
  SPEC_FILENAME = "spec.rb" # the name of the pane the spec comes from

  module_function

  # input: { source:, spec:, subject: } (strings). Returns a JSON string.
  def call(source:, spec:, subject:)
    spec = spec.gsub(/^\s*require_relative.*/, "") # source is loaded separately

    write_source(source)
    load_subject

    # 1. Baseline: the suite must be green before mutation testing means anything.
    _count, failures = run_spec(spec)
    return dump(status: "red", failures: failures) unless failures.empty?
    # return dump(status: "red", failures: ["no examples were run"]) if count.zero?

    # 2. Generate mutations with real mutant.
    mutations = mutations_for(source, subject)

    # 3. Kill-loop: insert each mutation, run the suite ourselves.
    alive = []
    mutations.each do |mutation|
      mutation.insert(Mutant::WORLD.kernel)
      _c, fails = run_spec(spec)
      alive << present(mutation) if fails.empty? # suite still green => undetected
    end

    dump(status: "green", total: mutations.length, killed: mutations.length - alive.length, alive: alive)
  rescue StandardError, SyntaxError => e
    dump(status: "error", message: "#{e.class}: #{e.message}")
  end

  def write_source(source)
    Dir.mkdir(KATA_DIR) unless Dir.exist?(KATA_DIR)
    File.write(SOURCE_PATH, source)
  end

  def load_subject
    load SOURCE_PATH
  end

  # Runs the spec in-process against whatever the subject currently is.
  # Returns [example_count, failures].
  def run_spec(spec_src)
    RSpec.reset
    # The filename makes example locations and the backtraces RSpec embeds in its
    # messages read as "spec.rb:4" — the pane the learner is looking at — instead
    # of "(eval)". Passing nil keeps the binding this eval already used.
    eval(spec_src, nil, SPEC_FILENAME) # rubocop:disable Security/Eval -- curated kata content
    sink = StringIO.new
    RSpec::Core::Runner.new(spec_options).run(sink, sink)
    # Traverse descendants: examples in nested `describe`/`context` groups live in
    # child groups, not the top-level ones.
    examples = RSpec.world.example_groups.flat_map(&:descendants).flat_map(&:examples)
    failures = examples.select { |ex| ex.execution_result.status == :failed }
                       .map { |ex| present_failure(ex) }
    [examples.length, failures]
  end

  # Run only the examples we just eval'd — a non-matching --pattern stops RSpec from
  # auto-loading an ambient spec/ directory (e.g. ruby/spec when the harness runs from
  # ruby/), which would otherwise inject unrelated example groups.
  #
  # Built once and reused: parsing RSpec's option set through optparse allocates ~10 MB
  # that the wasm heap never returns, and run_spec runs once per mutation — so building
  # it per run cost ~200 MB per kata and killed the VM after a handful of runs. The
  # options are identical every time.
  def spec_options
    @spec_options ||= RSpec::Core::ConfigurationOptions.new(["--pattern", "__mutant_katas_none__"])
  end

  # Shape matches the TS `SpecFailure` type: { description, location, message }.
  # An unmet expectation already reads as the failure ("expected: 5 / got: 4", plus
  # RSpec's diff); any other exception needs its class for the message to mean
  # anything, since e.g. ArgumentError#message is bare "boom".
  def present_failure(example)
    error   = example.execution_result.exception
    message = error.message.to_s.strip
    message = "#{error.class}: #{message}" unless error.class.name.start_with?("RSpec::Expectations::")
    { description: example.full_description, location: failure_line(example, error), message: message }
  end

  # Where the learner has to look: the line the expectation failed on, not the line the
  # example opens on (which is all example.location knows). RSpec puts it in the
  # exception's backtrace — the topmost frame from the eval'd spec, since the frames above
  # it belong to rspec itself. For an aggregate_failures block that frame is the block's
  # own line, and the message lists the line of each failure inside it. example.location
  # remains a safety net for an exception that carries no spec frame at all.
  def failure_line(example, error)
    frame = (error.backtrace || []).find { |line| line.start_with?("#{SPEC_FILENAME}:") }
    frame&.slice(/\A#{Regexp.escape(SPEC_FILENAME)}:\d+/) || example.location
  end

  # Bootstrapping mutant allocates ~11 MB that the wasm heap never gives back (it builds
  # RSpec's option parser via mutant's rspec integration), so a learner rerunning a kata
  # pays it again every time. Mutations depend only on the source and the subject, and
  # most katas keep the source locked — so remember the last set. One entry is enough:
  # a run only ever needs the buffers in front of the learner.
  def mutations_for(source, subject)
    key = [source, subject]
    return @mutations if @mutations_key == key

    @mutations_key = key
    @mutations = generate_mutations(subject).reject { |m| m.identification.start_with?("neutral") }
  end

  def generate_mutations(subject)
    expr = Mutant::Config::DEFAULT.expression_parser.call(subject).from_right
    config = Mutant::Config::DEFAULT.with(
      # for more mutations, use `.with(operators: Mutant::Mutation::Operators::Full.new)`,
      mutation:    Mutant::Mutation::Config::DEFAULT,
      # Bootstrap requires an integration to be configured even though we never
      # use mutant's (fork-based, non-re-entrant) runner — we drive RSpec ourselves.
      integration: Mutant::Integration::Config::DEFAULT.with(name: "rspec"),
      matcher:     Mutant::Matcher::Config::DEFAULT.with(subjects: [expr]),
      requires:    [SOURCE_PATH]
    )
    env = Mutant::Bootstrap.call(Mutant::Env.empty(Mutant::WORLD, config)).from_right
    env.subjects.flat_map(&:mutations)
  end

  # Shape matches the TS `Mutant` type: { id, diff, location }.
  # identification is "evil:<subject>:<path>:<line>:<hash>" — the location is its
  # last-three colon-separated fields (path:line), which is more robust than
  # reaching into mutant's subject internals.
  def present(mutation)
    id    = mutation.identification
    parts = id.split(":")
    {
      id:       id,
      diff:     unified_diff(mutation.subject.source, mutation.source),
      location: "#{parts[-3]}:#{parts[-2]}"
    }
  end

  # Minimal unified diff (changed lines only) between the original subject source
  # and the mutated source, e.g. "  - @age >= 18\n  + @age > 18".
  require "diff/lcs"
  def unified_diff(original, mutated)
    Diff::LCS.sdiff(original.lines, mutated.lines).each_with_object([]) do |change, out|
      case change.action
      when "-" then out << "- #{change.old_element.chomp}"
      when "+" then out << "+ #{change.new_element.chomp}"
      when "!" then out << "- #{change.old_element.chomp}" << "+ #{change.new_element.chomp}"
      end
    end.join("\n")
  end

  def dump(hash) = JSON.generate(hash)
end
