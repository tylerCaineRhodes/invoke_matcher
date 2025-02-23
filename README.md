# InvokeMatcher

This is adapted from: https://github.com/rspec/rspec-expectations/issues/934

It allows us to write expectations in a more declarative way, by checking if a
method was called on a class or instance.

Old way:

```ruby
allow(foo).to receive(:method).and_return('value')
subject
expect(foo).to have_received(:method)
```

Or:

```ruby
expect(foo).to receive(:method).and_return('value')
subject
```

New way:

```ruby
expect { subject }.to invoke(:method).on(foo).with('bar')
```

## Installation

Add this to your test gems:

```ruby
group :test do
  gem 'invoke_matcher'
end
```

Make sure to require it in your `spec_helper.rb` or `rails_helper.rb`:

```ruby
require 'invoke_matcher'

RSpec.configure do |config|
  config.include InvokeMatcher
end
```

## Usage

```ruby
expect { foo }.to invoke(:method).on(Class).and_call_original

expect { foo }.to change{ bar }.and not_invoke(:method).on(Class)

expect { foo }.to invoke(:method).on(Class).at_least(3).times

expect { foo }.to invoke(:method).and_expect_return('bar')
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
