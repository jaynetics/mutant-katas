---
title: "Boolean logic"
subject: "LoginPolicy#allow?"
editable: spec
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

```ruby
RSpec.describe LoginPolicy, '#allow?' do
  it { expect(LoginPolicy.new(active: true, verified: true).allow?).to be(true) }
  it { expect(LoginPolicy.new(active: true, verified: false).allow?).to be(false) }
  it { expect(LoginPolicy.new(active: false, verified: true).allow?).to be(false) }
  it { expect(LoginPolicy.new(active: false, verified: false).allow?).to be(false) }
end
```

# explanation

The spec only covers the two cases where both flags agree, true/true and false/false. For those, &&, ||, @active on its own and @verified on its own all give the same answers, allowing for three mutations. Cover the mixed cases, true/false and false/true, where the choice of boolean operator does affect the result.
