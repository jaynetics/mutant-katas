---
title: "Hello World"
subject: "HelloWorld.call"
editable: spec
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

```ruby
RSpec.describe HelloWorld, '.call' do
  it 'returns "hello world!"' do
    expect(HelloWorld.call).to eq('hello world!')
  end
end
```

# explanation

The only expectation in the spec is commented out, so nothing checks what the method returns. Mutant can replace the string with `""` or `nil`, or delete the line altogether, and the spec still passes. Uncomment the expectation.
