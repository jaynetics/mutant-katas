---
title: "Default arguments"
subject: "Greeter.greet"
editable: [spec]
difficulty: 1
concepts: [default-arguments]
---

# source

```ruby
module Greeter
  def self.greet(name, greeting = "Hello")
    "#{greeting}, #{name}!"
  end
end
```

# spec

```ruby
RSpec.describe Greeter, '.greet' do
  it "uses the given greeting" do
    expect(Greeter.greet("Ada", "Hi")).to eq("Hi, Ada!")
  end
end
```

# solution

## spec

```ruby
RSpec.describe Greeter, '.greet' do
  it "uses the given greeting" do
    expect(Greeter.greet("Ada", "Hi")).to eq("Hi, Ada!")
  end

  it "defaults to a friendly hello" do
    expect(Greeter.greet("Ada")).to eq("Hello, Ada!")
  end
end
```

# explanation

The starting spec always passes an explicit greeting, so the `greeting = "Hello"` default is never exercised — mutant can change the default string (or drop it) and your test still passes. Calling `greet` with only a name covers the default path. Side note: this is similar to a branch coverage case, but Ruby's default coverage tools can't detect the uncovered code here.
