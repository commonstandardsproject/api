# VirtusConvert

VirtusConvert allows you to convert a deeply nested tree of Virtus\* or other objects that respond
to attributes to nested tree of hashes and arrays


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'virtus_convert'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install virtus_convert

## Usage

```ruby
jack = Person.new(name:'Jack', address:'123 Fake Street' )
order = Order.new(customer: jack, total:1_000_000)

VirtusConvert.new(order).to_hash #=> {customer:{name:'Jack', address:'123 Fake Street'}, total: 1000000}
```

Look in the specs/ folder for more example use cases

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/virtus_convert/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
2. Write Tests!
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
