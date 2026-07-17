---
title: "String methods"
subject: "Slug#to_s"
editable: [spec]
difficulty: 2
concepts: [string-methods, gsub-vs-sub]
---

# source

```ruby
class Slug
  def initialize(title)
    @title = title
  end

  def to_s
    @title.downcase.gsub(" ", "-")
  end
end
```

# spec

```ruby
RSpec.describe Slug, '#to_s' do
  it "lowercases and dashes a simple title" do
    expect(Slug.new("Hello World").to_s).to eq("hello-world")
  end
end
```

# solution

## spec

```ruby
RSpec.describe Slug, '#to_s' do
  it "lowercases and dashes a simple title" do
    expect(Slug.new("Hello World X").to_s).to eq("hello-world-x")
  end
end
```

# explanation

A one-space title can't tell `gsub` (replace all) from `sub` (replace first), so mutant's `gsub → sub` mutation survives. It also survives dropping `downcase` if your input is already lowercase. Use a title with several spaces to pin `gsub`, and an uppercase input to pin `downcase`.
