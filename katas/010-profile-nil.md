---
title: "Nil handling"
subject: "Profile#display_name"
editable: [spec]
difficulty: 1
concepts: [nil-handling, or-default]
---

# source

```ruby
class Profile
  def initialize(nickname)
    @nickname = nickname
  end

  def display_name
    @nickname || "Anonymous"
  end
end
```

# spec

```ruby
RSpec.describe Profile, '#display_name' do
  it "shows the nickname when present" do
    expect(Profile.new("ada").display_name).to eq("ada")
  end
end
```

# solution

## spec

```ruby
RSpec.describe Profile, '#display_name' do
  it "shows the nickname when present" do
    expect(Profile.new("ada").display_name).to eq("ada")
  end

  it "falls back to Anonymous when the nickname is nil" do
    expect(Profile.new(nil).display_name).to eq("Anonymous")
  end
end
```

# explanation

With a nickname always present, the right-hand side of `@nickname || "Anonymous"` never runs. This is a simple branch coverage example. Test the `nil` case.
