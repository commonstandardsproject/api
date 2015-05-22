#\ -s puma
require 'sinatra'
require 'bundler/setup'
require_relative "api/api"
require 'rack/cors'
require_relative 'api/main'


use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

# run API::API
run Rack::Cascade.new [API::API, Main]
