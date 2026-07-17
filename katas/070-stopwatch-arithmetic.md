---
title: "Arithmetic operators"
subject: "Stopwatch#elapsed"
editable: [spec]
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

## spec

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

Starting from `0` hides the operator: `@end - @start` and `@end + @start` both give `10` when the start is `0`, so mutant's `- → +` mutation survives. A start time that isn't zero (and differs from the result) distinguishes subtraction from the other operators and from swapping the operands.
