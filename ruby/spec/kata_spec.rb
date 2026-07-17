# frozen_string_literal: true

require_relative "../kata"

RSpec.describe Kata do
  let(:markdown) { <<~'MD' }
    ---
    title: "Boundary values"
    subject: "Person#adult?"
    editable: [spec]
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

    ## spec

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
      "editable" => ["spec"],
      "difficulty" => 1,
      "concepts" => %w[boundary-values equality-mutations]
    )
  end

  it "extracts the starting source and spec blocks" do
    expect(kata["source"]).to include("def adult?")
    expect(kata["spec"]).to include('it("17")')
  end

  it "builds full solution buffers, inheriting omitted files" do
    expect(kata["solution"]["spec"]).to include('it("18")')      # from ## spec
    expect(kata["solution"]["source"]).to eq(kata["source"])     # inherited (no ## source)
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
