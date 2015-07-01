#\ -s puma
require 'sinatra'
require 'bundler/setup'
require 'rubygems'
require 'algoliasearch'
require_relative "api/api"
require 'rack/cors'
require_relative 'main'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:post, :get]
  end
end

Algolia.init :application_id => ENV["ALGOLIA_APPLICATION_ID"],
             :api_key => ENV["ALGOLIA_API_KEY"]



# run API::API
run Rack::Cascade.new [API::API, Main]
