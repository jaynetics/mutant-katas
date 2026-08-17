---
title: "Orthogonal methods"
subject: "Readings#peak"
editable: spec
difficulty: 3
concepts: [orthogonal-methods, ordering]
---

# source

```ruby
class Readings
  def initialize(values)
    @values = values
  end

  def peak
    @values.max
  end
end
```

# spec

```ruby
RSpec.describe Readings, '#peak' do
  it "returns the only reading" do
    expect(Readings.new([42]).peak).to eq(42)
  end
end
```

# solution

```ruby
RSpec.describe Readings, '#peak' do
  it "returns the largest reading, wherever it sits" do
    expect(Readings.new([3, 9, 5]).peak).to eq(9)
  end
end
```

# explanation

Mutant replaces `max` with `min`, `first`, and `last`. With a single reading all of those return the same value, so the example passes either way. Use several readings and put the largest one in the middle, so it is neither the first nor the last element.
