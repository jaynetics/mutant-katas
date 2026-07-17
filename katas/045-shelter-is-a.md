---
title: "Type checks"
subject: "Shelter.accepts?"
editable: [spec]
difficulty: 4
concepts: [type-checks, subclasses, strict-apis]
---

# source

```ruby
class Animal
end

class Dog < Animal
end

module Shelter
  def self.accepts?(candidate)
    candidate.is_a?(Animal)
  end
end
```

# spec

```ruby
RSpec.describe Shelter, '.accepts?' do
  it "accepts an animal" do
    expect(Shelter.accepts?(Animal.new)).to be(true)
  end

  it "rejects a non-animal" do
    expect(Shelter.accepts?(Object.new)).to be(false)
  end
end
```

# solution

## spec

```ruby
RSpec.describe Shelter, '.accepts?' do
  it "accepts an animal" do
    expect(Shelter.accepts?(Animal.new)).to be(true)
  end

  it "accepts a subclass of animal" do
    expect(Shelter.accepts?(Dog.new)).to be(true)
  end

  it "rejects a non-animal" do
    expect(Shelter.accepts?(Object.new)).to be(false)
  end
end
```

# explanation

`is_a?` returns true for subclasses; `instance_of?` only for the exact class. Mutant swaps `is_a?` for `instance_of?`, and a spec that only tests a direct `Animal` still passes. Testing a `Dog` (a subclass) makes `is_a?` the required method. Strong tests make sure that the APIs used in the code have the right level of strictness.
