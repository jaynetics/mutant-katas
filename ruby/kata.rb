# frozen_string_literal: true

require "yaml"
require "kramdown"
require "kramdown-parser-gfm"

# Single source of truth for parsing a kata Markdown file (YAML frontmatter +
# `# source` / `# spec` / `# solution` / `# explanation` sections) into the shape
# the TS app and the validation harness both consume. The compiler
# (compile_katas.rb) emits these as JSON for the browser app; the harness uses
# them directly. Parsing is done with kramdown (GFM) so that, for example, a `#`
# comment inside a code block is never mistaken for a section heading.
module Kata
  EDITABLE = %w[source spec].freeze

  module_function

  # Parse a file into a kata hash; id is the filename stem.
  def load(path)
    parse(File.basename(path, ".md"), File.read(path))
  rescue StandardError => e
    raise "failed to parse #{path}: #{e.message}"
  end

  # Parse markdown into: { "id", "meta" => {title, subject, editable, difficulty,
  # concepts}, "source", "spec", "solution", "explanation" }.
  def parse(id, markdown)
    fm, body = split_frontmatter(markdown)
    meta = YAML.safe_load(fm)
    secs = sections(body)

    source = first_code(secs, "source")
    spec   = first_code(secs, "spec")

    {
      "id" => id,
      "meta" => {
        "title"      => meta.fetch("title"),
        "subject"    => meta.fetch("subject"),
        "editable"   => editable(meta),
        "difficulty" => meta.fetch("difficulty"),
        "concepts"   => meta.fetch("concepts")
      },
      "source" => source,
      "spec"   => spec,
      # The reference version of whichever buffer the learner edits.
      "solution" => first_code(secs, "solution"),
      "explanation" => elements_to_html(secs["explanation"])
    }
  end

  # A kata hands the learner one buffer to edit, so this names a single file.
  def editable(meta)
    value = meta.fetch("editable")
    return value if EDITABLE.include?(value)

    raise "editable must be #{EDITABLE.join(" or ")}, got #{value.inspect}"
  end

  # "---\n<yaml>\n---\n<body>"
  def split_frontmatter(markdown)
    m = markdown.match(/\A---\n(.*?)\n---\n(.*)\z/m) or raise "kata missing frontmatter"
    [m[1], m[2]]
  end

  # Group the body's block elements by their preceding level-1 heading.
  def sections(body)
    root = Kramdown::Document.new(body, input: "GFM").root
    out = {}
    current = nil
    root.children.each do |el|
      if header?(el, 1)
        current = heading_text(el)
        out[current] = []
      elsif current
        out[current] << el
      end
    end
    out
  end

  def header?(element, level)
    element.type == :header && element.options[:level] == level
  end

  def heading_text(element)
    (element.options[:raw_text] || "").strip
  end

  # The first code block within a named section's elements.
  def first_code(sections, name)
    code(sections.fetch(name)) or raise "section '#{name}' has no code block"
  rescue KeyError
    raise "missing '# #{name}' section"
  end

  def code(elements)
    elements.find { |e| e.type == :codeblock }&.value&.chomp
  end

  # Render a section's elements to HTML (used for the explanation). Backtick code
  # spans become <code> and text is escaped — kramdown handles both.
  def elements_to_html(elements)
    return "" if elements.nil? || elements.empty?

    doc = Kramdown::Document.new("")
    doc.root.children.replace(elements)
    doc.to_html.strip
  end
end
