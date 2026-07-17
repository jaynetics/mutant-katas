---
title: "Boolean logic"
subject: "LoginPolicy#allow?"
editable: [spec]
difficulty: 2
concepts: [boolean-operators, truth-table]
---

# source

```ruby
class LoginPolicy
  def initialize(active:, verified:)
    @active = active
    @verified = verified
  end

  def allow? = @active && @verified
end
```

# spec

```ruby
RSpec.describe LoginPolicy, '#allow?' do
  it { expect(LoginPolicy.new(active: true, verified: true).allow?).to be(true) }
  it { expect(LoginPolicy.new(active: false, verified: false).allow?).to be(false) }
end
```

# solution

## spec

```ruby
RSpec.describe LoginPolicy, '#allow?' do
  it { expect(LoginPolicy.new(active: true, verified: true).allow?).to be(true) }
  it { expect(LoginPolicy.new(active: true, verified: false).allow?).to be(false) }
  it { expect(LoginPolicy.new(active: false, verified: true).allow?).to be(false) }
  it { expect(LoginPolicy.new(active: false, verified: false).allow?).to be(false) }
end
```

# explanation

The starting spec only checks the two cases where both inputs agree (`true/true` and `false/false`). For those, `&&` and `||` behave identically — and dropping either operand also passes. Mutant keeps the `@active`, `@verified`, and `@active || @verified` mutations alive. Only by testing the mixed cases (`true/false` and `false/true`), where the operator actually matters, do you cover the behavior of `&&` precisely.
