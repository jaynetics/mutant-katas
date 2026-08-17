---
title: "Hash access"
subject: "Settings#timeout"
editable: spec
difficulty: 3
concepts: [hash-access, missing-key]
---

# source

```ruby
class Settings
  def initialize(values)
    @values = values
  end

  def timeout
    @values[:timeout]
  end
end
```

# spec

```ruby
RSpec.describe Settings, '#timeout' do
  it "returns the configured timeout" do
    expect(Settings.new(timeout: 30).timeout).to eq(30)
  end
end
```

# solution

```ruby
RSpec.describe Settings, '#timeout' do
  it "returns the configured timeout" do
    expect(Settings.new(timeout: 30).timeout).to eq(30)
  end

  it "returns nil when no timeout is configured" do
    expect(Settings.new({}).timeout).to be_nil
  end
end
```

# explanation

`@values[:timeout]` and `@values.fetch(:timeout)` return the same thing while the key is present, so a spec that always supplies it cannot tell them apart. They differ when the key is missing: `#[]` returns nil and `#fetch` raises `KeyError`. Add an example for the missing key.
