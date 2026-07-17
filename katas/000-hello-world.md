---
title: "Hello World"
subject: "HelloWorld.call"
editable: [spec]
difficulty: 1
concepts: [coverage]
---

# source

```ruby
module HelloWorld
  def self.call
    'hello world!'
  end
end
```

# spec

```ruby
RSpec.describe HelloWorld, '.call' do
  it 'returns "hello world!"' do
    # expect(HelloWorld.call).to eq('hello world!')
  end
end
```

# solution

## spec

```ruby
RSpec.describe HelloWorld, '.call' do
  it 'returns "hello world!"' do
    expect(HelloWorld.call).to eq('hello world!')
  end
end
```

# explanation

The expectation is commented out. This leaves the method uncovered. No change to the code will break the tests. That is bad. Uncomment the expectation to cover the method.
