---
title: "Regex features"
subject: "ProductCode.valid?"
editable: source
difficulty: 5
concepts: [regex, character-classes, quantifiers]
---

# source

```ruby
# note: you'll have to edit the source in this case
module ProductCode
  def self.valid?(string)
    string.match?(/^(?:FOO)+(BAR|QUX)$/)
  end
end
```

# spec

```ruby
RSpec.describe ProductCode, '.valid?' do
  it "accepts a well-formed code" do
    expect(ProductCode.valid?("FOOBAR")).to be(true)
    expect(ProductCode.valid?("FOOQUX")).to be(true)
    expect(ProductCode.valid?("FOOFOOFOOBAR")).to be(true)
    expect(ProductCode.valid?("FOOFOOFOO")).to be(false)
    expect(ProductCode.valid?("xFOOBAR")).to be(false)
    expect(ProductCode.valid?("FOOxBAR")).to be(false)
    expect(ProductCode.valid?("FOOFOOxBAR")).to be(false)
  end
end
```

# solution

```ruby
module ProductCode
  def self.valid?(string)
    string.match?(/\A(?:FOO)+(?:BAR|QUX)\z/)
  end
end
```

# explanation

`^` and `$` anchor the regexp to the start and end of a line, not the start and end of the string. This would allow e.g. `\nFOO` to match. Use `\A` and `\z` to anchor to the start and end of the string instead. Also, `(...)` is a capturing group, but capturing is not needed (or tested) here. Use a non-capturing group `(?:...)` instead. Side note 1: Sometimes mutant simply points to code changes you want to make. Side note 2: even short regular expressions can result in a considerable number of mutations, which goes to show how "logically dense" they are.


`^` and `$` match the start and end of a line in Ruby, not of the whole string, so `"\nFOOBAR"` matches too. Use `\A` and `\z` instead. `(BAR|QUX)` captures the matched text, and nothing here uses this capture, so write `(?:...)`. All three surviving mutations are changes worth making in the source, which happens sometimes: mutant points at the code rather than the spec. Note also how many mutations one short regexp can produce.
