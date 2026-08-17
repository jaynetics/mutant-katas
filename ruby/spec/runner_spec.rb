# frozen_string_literal: true

require "open3"
require "tmpdir"
require "json"

# What the learner sees when the suite is red: the runner reports each failing
# example with enough detail to fix it, before any mutation is generated.
module RedRun
  # runner.rb writes source into ENV["KATA_DIR"]; the subprocess inherits it.
  ENV["KATA_DIR"] ||= Dir.mktmpdir
  RUN_KATA = File.expand_path("../run_kata.rb", __dir__)
  RUNNER   = File.expand_path("../runner", __dir__)
  SOURCE   = "class Calc\n  def self.add(a, b)\n    a + b\n  end\nend\n"

  module_function

  # Runs in a subprocess (like katas_spec) so the runner's RSpec.reset cannot
  # disturb the RSpec suite driving this spec.
  def call(spec)
    input = JSON.generate("source" => SOURCE, "spec" => spec, "subject" => "Calc.add")
    out, err, status = Open3.capture3("bundle", "exec", "ruby", RUN_KATA, stdin_data: input)
    raise "run_kata failed:\n#{err}" unless status.success?
    JSON.parse(out[/\{.*\}/m])
  end
end

RSpec.describe "Runner memory use" do
  # Building RSpec's option parser allocates ~10 MB that the wasm heap never returns, and
  # the suite runs once per mutation — so one options object has to serve the whole run,
  # or a handful of Run clicks exhausts the browser VM.
  it "builds RSpec's options once for the whole run, not once per suite run" do
    code = <<~RUBY
      require_relative #{RedRun::RUNNER.inspect}
      built = 0
      RSpec::Core::ConfigurationOptions.prepend(Module.new do
        define_method(:initialize) { |*args| built += 1; super(*args) }
      end)
      result = Runner.call(source: #{RedRun::SOURCE.inspect}, spec: #{<<~SPEC.inspect}, subject: "Calc.add")
        RSpec.describe Calc, '.add' do
          it('adds') { expect(Calc.add(2, 2)).to eq(4) }
        end
      SPEC
      puts [built, JSON.parse(result).fetch("total")].join(",")
    RUBY

    out, err, status = Open3.capture3("bundle", "exec", "ruby", "-e", code)
    raise "probe failed:\n#{err}" unless status.success?
    built, mutations = out.lines.last.split(",").map(&:to_i)

    # The suite runs once for the baseline plus once per mutation, but only two option
    # sets get built: mutant's own during bootstrap, and the one run_spec reuses.
    expect(mutations).to be > 3
    expect(built).to eq(2)
  end

  # Bootstrapping mutant allocates ~11 MB the wasm heap never returns (it builds RSpec's
  # option parser through mutant's rspec integration), and mutations depend only on the
  # source and the subject — which most katas keep locked.
  def bootstrap_calls(sources)
    code = <<~RUBY
      require_relative #{RedRun::RUNNER.inspect}
      calls = 0
      Mutant::Bootstrap.singleton_class.prepend(Module.new do
        define_method(:call) { |*args| calls += 1; super(*args) }
      end)
      spec = <<~SPEC
        RSpec.describe Calc, '.add' do
          it('adds') { expect(Calc.add(2, 2)).to eq(4) }
        end
      SPEC
      #{sources.inspect}.each { |src| Runner.call(source: src, spec: spec, subject: "Calc.add") }
      puts calls
    RUBY

    out, err, status = Open3.capture3("bundle", "exec", "ruby", "-e", code)
    raise "probe failed:\n#{err}" unless status.success?
    out.lines.last.to_i
  end

  # Two katas can share a subject (050-slug-format and 055-slug-format-regexp both use
  # Slug#to_s with different sources), and 085-code-regex lets the learner edit the source
  # itself. If the mutation cache keyed on the subject alone, the second source would be
  # scored against the first one's mutations: fewer mutations, none of them alive, and the
  # learner is congratulated for solving a kata that still has a survivor. However the
  # cache is keyed, a source's result must never depend on what ran before it.
  def results_for(sources, spec)
    code = <<~RUBY
      require_relative #{RedRun::RUNNER.inspect}
      puts JSON.generate(#{sources.inspect}.map { |src|
        JSON.parse(Runner.call(source: src, spec: #{spec.inspect}, subject: "Calc.add"))
      })
    RUBY

    out, err, status = Open3.capture3("bundle", "exec", "ruby", "-e", code)
    raise "probe failed:\n#{err}" unless status.success?
    JSON.parse(out.lines.last)
  end

  it "scores a source against its own mutations, whatever ran before it" do
    guarded = <<~RUBY
      class Calc
        def self.add(a, b)
          return 0 if a.negative?
          a + b
        end
      end
    RUBY
    spec = <<~SPEC
      RSpec.describe Calc, '.add' do
        it('adds') { expect(Calc.add(2, 2)).to eq(4) }
      end
    SPEC

    plain_alone    = results_for([RedRun::SOURCE], spec).first
    guarded_alone  = results_for([guarded], spec).first
    guarded_after  = results_for([RedRun::SOURCE, guarded], spec).last

    # The two sources really do mutate differently, so a stale cache is detectable.
    expect(guarded_alone["total"]).to be > plain_alone["total"]
    expect(guarded_alone["alive"]).not_to be_empty

    expect(guarded_after.slice("status", "total", "killed")).to eq(guarded_alone.slice("status", "total", "killed"))
    expect(guarded_after["alive"].length).to eq(guarded_alone["alive"].length)
  end

  it "generates mutations once when the source is unchanged" do
    expect(bootstrap_calls([RedRun::SOURCE, RedRun::SOURCE, RedRun::SOURCE])).to eq(1)
  end

  it "regenerates mutations when the source changes" do
    edited = RedRun::SOURCE.sub("a + b", "b + a")
    expect(bootstrap_calls([RedRun::SOURCE, edited, RedRun::SOURCE])).to eq(3)
  end
end

RSpec.describe "Runner red output" do
  it "reports the expectation message and the line the expectation failed on" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'adds' do
          expect(Calc.add(2, 2)).to eq(5)
        end
      end
    SPEC

    expect(result["status"]).to eq("red")
    expect(result["failures"].length).to eq(1)
    failure = result["failures"].first
    expect(failure["description"]).to eq("Calc.add adds")
    expect(failure["location"]).to eq("spec.rb:3") # the expect, not the `it` on line 2
    expect(failure["message"]).to include("expected: 5").and(include("got: 4"))
  end

  # The example's own location is no help once an example has any length to it: the
  # learner needs the line to look at, not the line the example opens on.
  it "points at the failing line when the example holds several" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'adds several ways' do
          sum = Calc.add(2, 2)
          expect(sum).to eq(4)
          expect(sum).to be_positive
          expect(sum).to eq(5)
        end
      end
    SPEC

    expect(result["failures"].first["location"]).to eq("spec.rb:6")
  end

  it "points at the aggregation block, with each inner failure's line in the message" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'aggregates' do
          aggregate_failures do
            expect(Calc.add(1, 1)).to eq(3)
            expect(Calc.add(2, 2)).to eq(5)
          end
        end
      end
    SPEC

    failure = result["failures"].first
    expect(failure["location"]).to eq("spec.rb:3")
    expect(failure["message"]).to include("spec.rb:4").and(include("spec.rb:5"))
  end

  it "points at the line that raised when the failure is not an expectation" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'blows up' do
          Calc.add(1, 1)
          raise ArgumentError, 'boom'
        end
      end
    SPEC

    expect(result["failures"].first["location"]).to eq("spec.rb:4")
  end

  it "keeps RSpec's diff for a failed comparison" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'adds up a hash' do
          expect({ sum: Calc.add(1, 1) }).to eq({ sum: 3 })
        end
      end
    SPEC

    expect(result["failures"].first["message"]).to include("Diff:")
  end

  it "names the exception class when the failure is not an unmet expectation" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it 'blows up' do
          raise ArgumentError, 'boom'
        end
      end
    SPEC

    expect(result["failures"].first["message"]).to eq("ArgumentError: boom")
  end

  it "reports every failing example" do
    result = RedRun.call(<<~SPEC)
      RSpec.describe Calc, '.add' do
        it('one') { expect(Calc.add(1, 1)).to eq(3) }
        it('two') { expect(Calc.add(2, 2)).to eq(5) }
      end
    SPEC

    expect(result["failures"].map { |f| f["description"] })
      .to eq(["Calc.add one", "Calc.add two"])
  end
end
