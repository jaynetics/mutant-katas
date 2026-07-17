---
title: "Hash access"
subject: "Settings#timeout"
editable: [spec]
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

## spec

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

`@values[:timeout]` and `@values.fetch(:timeout)` behave identically when the key is present, so a spec that supplies the key can't tell them apart. They differ only on a missing key: `[]` returns `nil`, `fetch` raises `KeyError`. Adding a test for the absent-key case pins `[]` as lookup method.
