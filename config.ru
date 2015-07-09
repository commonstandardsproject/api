#\ -s puma
require 'sinatra'
require 'bundler/setup'
require 'rubygems'
require 'algoliasearch'
require_relative "api/api"
require 'rack/cors'
require_relative 'main'


use Rack::Deflater
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:post, :get]
  end
end


# run API::API

run Rack::Cascade.new [API::API, Main]
