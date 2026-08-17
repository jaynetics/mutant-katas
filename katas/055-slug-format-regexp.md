---
title: "String methods"
subject: "Slug#to_s"
editable: spec
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

```ruby
RSpec.describe Slug, '#to_s' do
  it "lowercases and dashes a simple title" do
    expect(Slug.new("Hello  World X").to_s).to eq("hello-world-x")
  end
end
```

# explanation

With single spaces, / +/ and / / match the same thing, so removing the + changes nothing. Use a title with several spaces in a row.
