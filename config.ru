#\ -s puma
require 'sinatra'
require 'bundler/setup'
require 'rubygems'
require 'grape'
require 'rack/cors'
require 'newrelic_rpm'
require_relative "config/reform"
require_relative "api/api"
require_relative 'main'

use Skylight::Middleware
use Rack::Deflater
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:post, :get]
  end
end


# run API::API

run Rack::Cascade.new [API::API, Main]
