---
title: "Off-by-one ranges"
subject: "Raffle#winner?"
editable: spec
difficulty: 3
concepts: [ranges, off-by-one, boundaries]
---

# source

```ruby
class Raffle
  def initialize(highest_winning)
    @highest_winning = highest_winning
  end

  def winner?(number)
    (1..@highest_winning).include?(number)
  end
end
```

# spec

```ruby
RSpec.describe Raffle, '#winner?' do
  it "is true for a number in the range" do
    expect(Raffle.new(10).winner?(5)).to be(true)
    expect(Raffle.new(10).winner?(20)).to be(false)
  end
end
```

# solution

```ruby
RSpec.describe Raffle, '#winner?' do
  it "is true for a number in the range" do
    expect(Raffle.new(10).winner?(-1)).to be(false)
    expect(Raffle.new(10).winner?(0)).to be(false)
    expect(Raffle.new(10).winner?(1)).to be(true)
    expect(Raffle.new(10).winner?(5)).to be(true)
    expect(Raffle.new(10).winner?(10)).to be(true)
    expect(Raffle.new(10).winner?(11)).to be(false)
    expect(Raffle.new(10).winner?(20)).to be(false)
  end
end
```

# explanation

`(1..10)` includes both ends. The spec checks a number in the middle and one far outside, so nothing pins the ends down. Mutant moves the lower bound to 0 or 2, and changes .. to ..., which drops the highest winner. Add examples for the lowest and highest winning numbers, and for the numbers just below and just above them.
