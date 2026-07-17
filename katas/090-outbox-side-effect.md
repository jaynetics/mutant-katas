---
title: "Side effects"
subject: "Outbox#deliver"
editable: [spec]
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

## spec

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

The method has two jobs: append the message and return `:ok`. Mutant can delete the append line entirely and the method still returns `:ok`, so a test that only checks the return value never notices. Catching it takes a multi-step assertion: pass in a "spy" or "collaborator" (the `sent` array), perform the action, then inspect the collaborator's state afterwards. Assert the effect, not just the return value.
