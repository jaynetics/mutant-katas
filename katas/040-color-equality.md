---
title: "Equality vs identity"
subject: "Color#=="
editable: [spec]
difficulty: 2
concepts: [equality, identity, value-objects]
---

# source

```ruby
class Color
  attr_reader :hex

  def initialize(hex)
    @hex = hex
  end

  def ==(other)
    @hex == other.hex
  end
end
```

# spec

```ruby
RSpec.describe Color, '#==' do
  it "a color equals itself" do
    color = Color.new("ff0000")
    expect(color == color).to be(true)
  end

  it "differs from a color with another hex" do
    expect(Color.new("ff0000") == Color.new("00ff00")).to be(false)
  end
end
```

# solution

## spec

```ruby
RSpec.describe Color, '#==' do
  it "a color equals itself" do
    color = Color.new("ff0000")
    expect(color == color).to be(true)
  end

  it "equals a different instance with the same hex" do
    expect(Color.new("ff0000") == Color.new("ff0000")).to be(true)
  end

  it "differs from a color with another hex" do
    expect(Color.new("ff0000") == Color.new("00ff00")).to be(false)
  end
end
```

# explanation

The starting spec only compares a color to *itself* and to a clearly different color. It does not actually prove that two distinct color instances with the same hex value are considered equal.
