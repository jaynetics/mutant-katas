---
title: "Arithmetic operators"
subject: "Stopwatch#elapsed"
editable: spec
difficulty: 3
concepts: [arithmetic-operators, operands]
---

# source

```ruby
class Stopwatch
  def initialize(start_time, end_time)
    @start = start_time
    @end = end_time
  end

  def elapsed
    @end - @start
  end
end
```

# spec

```ruby
RSpec.describe Stopwatch, '#elapsed' do
  it "measures the time from start to end" do
    expect(Stopwatch.new(0, 10).elapsed).to eq(10)
  end
end
```

# solution

```ruby
RSpec.describe Stopwatch, '#elapsed' do
  it "measures the time from start to end" do
    expect(Stopwatch.new(0, 10).elapsed).to eq(10)
  end

  it "subtracts a non-zero start time" do
    expect(Stopwatch.new(3, 10).elapsed).to eq(7)
  end
end
```

# explanation

With a start of 0, `@end - @start` gives the same answer as `@end + @start` as well as `@end` on its own, so both of those mutations survive. Use a start that is not zero.
