---
title: "Type checks"
subject: "Shelter.accepts?"
editable: spec
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

is_a? is also true for subclasses, while instance_of? is true only for the exact class. Mutant swaps is_a? for instance_of?, and an example that passes a plain Animal gives the same answer either way. Add an example with a Dog, so the spec makes clear which of the two checks the code needs. Mutation testing often enforces picking an API with the right level of "strictness".
