---
title: "Boundary values"
subject: "Person#adult?"
editable: spec
difficulty: 2
concepts: [boundary-values, equality-mutations]
---

# source

```ruby
class Person
  def initialize(age:)
    @age = age
  end

  def adult?
    @age >= 18
  end
end
```

# spec

```ruby
RSpec.describe Person, '#adult?' do
  it 'returns true for age 19' do
    expect(Person.new(age: 19).adult?).to be(true)
  end

  it 'returns false for age 17' do
    expect(Person.new(age: 17).adult?).to be(false)
  end
end
```

# solution

```ruby
RSpec.describe Person, '#adult?' do
  it 'returns true for age 19' do
    expect(Person.new(age: 19).adult?).to be(true)
  end

  it 'returns true for age 18' do
    expect(Person.new(age: 18).adult?).to be(true)
  end

  it 'returns false for age 17' do
    expect(Person.new(age: 17).adult?).to be(false)
  end
end
```

# explanation

While the examples verify that the `#adult?` method behaves correctly for ages 19 and 17, they do not specify the behavior for the value 18. This may seem innocuous, but in a real codebase that is constantly being changed, a refactoring or "cleanup" of such code may silently change the behavior for an uncovered value without breaking the tests.
