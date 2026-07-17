---
title: "String methods"
subject: "Slug#to_s"
editable: [spec]
difficulty: 3
concepts: [string-methods, gsub-vs-sub]
---

# source

```ruby
class Slug
  def initialize(title)
    @title = title
  end

  def to_s
    @title.downcase.gsub(/ +/, "-")
  end
end
```

# spec

```ruby
RSpec.describe Slug, '#to_s' do
  it "lowercases and dashes a simple title" do
    expect(Slug.new("Hello World X").to_s).to eq("hello-world-x")
  end
end
```

# solution

## spec

```ruby
RSpec.describe Slug, '#to_s' do
  it "lowercases and dashes a simple title" do
    expect(Slug.new("Hello  World X").to_s).to eq("hello-world-x")
  end
end
```

# explanation

Testing with a title with single spaces does not cover the case where the quantifier (`+`) in the regexp is exercised. Use a title with multiple spaces to pin this behavior.
