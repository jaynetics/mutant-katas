# frozen_string_literal: true

require_relative "../kata"

RSpec.describe Kata do
  let(:markdown) { <<~'MD' }
    ---
    title: "Boundary values"
    subject: "Person#adult?"
    editable: spec
    difficulty: 1
    concepts: [boundary-values, equality-mutations]
    ---

    # source

    ```ruby
    class Person
      def adult? = @age >= 18
    end
    ```

    # spec

    ```ruby
    RSpec.describe(Person) { it("17") { } }
    ```

    # solution

    ```ruby
    RSpec.describe(Person) { it("18") { } }
    ```

    # explanation

    The `@age >= 18` mutation survives when 18 is untested.
  MD

  subject(:kata) { described_class.parse("010-person-adult", markdown) }

  it "keeps the id" do
    expect(kata["id"]).to eq("010-person-adult")
  end

  it "parses frontmatter into meta with native types" do
    expect(kata["meta"]).to eq(
      "title" => "Boundary values",
      "subject" => "Person#adult?",
      "editable" => "spec",
      "difficulty" => 1,
      "concepts" => %w[boundary-values equality-mutations]
    )
  end

  it "extracts the starting source and spec blocks" do
    expect(kata["source"]).to include("def adult?")
    expect(kata["spec"]).to include('it("17")')
  end

  it "extracts the solution for the editable buffer" do
    expect(kata["solution"]).to include('it("18")')
  end

  # A kata edits one buffer, so a stale `editable: [spec]` has to fail at compile time
  # rather than leave the app with a pane nobody can type in.
  it "rejects an editable entry that is not source or spec" do
    %w([spec] specs "" nil).each do |value|
      broken = markdown.sub("editable: spec", "editable: #{value}")
      expect { described_class.parse("x", broken) }.to raise_error(/editable/)
    end
  end

  it "renders the explanation as HTML: backticks -> <code>, and escapes it" do
    expect(kata["explanation"]).to eq(
      "<p>The <code>@age &gt;= 18</code> mutation survives when 18 is untested.</p>"
    )
  end

  it "loads a real kata file from disk" do
    path = File.expand_path("../../katas/000-hello-world.md", __dir__)
    loaded = described_class.load(path)
    expect(loaded["id"]).to eq("000-hello-world")
    expect(loaded["meta"]["subject"]).to eq("HelloWorld.call")
  end
end
