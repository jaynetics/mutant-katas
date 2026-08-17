---
title: "Side effects"
subject: "Outbox#deliver"
editable: spec
difficulty: 5
concepts: [side-effects, collaborators, multi-step]
---

# source

```ruby
class Outbox
  def initialize(sent)
    @sent = sent
  end

  def deliver(message)
    @sent << message
    :ok
  end
end
```

# spec

```ruby
RSpec.describe Outbox, '#deliver' do
  it "returns :ok" do
    expect(Outbox.new([]).deliver("hello")).to eq(:ok)
  end
end
```

# solution

```ruby
RSpec.describe Outbox, '#deliver' do
  it "records the message and returns :ok" do
    sent = []
    result = Outbox.new(sent).deliver("hello")

    expect(result).to eq(:ok)
    expect(sent).to eq(["hello"])
  end
end
```

# explanation

The `#deliver` method has two jobs: append the message and return `:ok`. Mutant can delete the append line entirely and the method still returns `:ok`, so a test that only checks the return value never notices the change. Assign an array to a variable, pass it to a new Outbox as a "spy" or "collaborator", perform the delivery, and then assert that the array contains the message. Test the side-effect, not just the return value.
