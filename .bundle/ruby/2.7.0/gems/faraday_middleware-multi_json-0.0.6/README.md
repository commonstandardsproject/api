# FaradayMiddleware::MultiJson

Simple Faraday middleware that uses MultiJson to unobtrusively encode JSON requests and parse JSON responses.

## Installation

Add this line to your application's Gemfile:

    gem 'faraday_middleware-multi_json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_middleware-multi_json

## Usage

The same as FaradayMiddleware::ParseJson:

```ruby
require 'faraday_middleware/multi_json'

connection = Faraday.new do |conn|
  conn.request :multi_json
  conn.response :multi_json
  conn.adapter  Faraday.default_adapter
end

connection.get('http://example.com/example.json')

resp = connection.post 'http://example.com/example.json' do |req|
  req.body = {:hello => 'world'}
end
```

### Passing parser options

```ruby
conn.response :multi_json, symbolize_keys: true
```

### Upgrading to 0.0.5+

The class name for the middleware changed, so if you had this before:

```ruby
connection = Faraday.new do |conn|
  conn.use FaradayMiddleware::MultiJson
end
```
Change to:
```ruby
connection = Faraday.new do |conn|
  conn.response :multi_json
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
