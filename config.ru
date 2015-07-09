#\ -s puma
require 'sinatra'
require 'bundler/setup'
require 'rubygems'
require 'grape'
require 'traceview'
require_relative "api/api"
require 'rack/cors'
require_relative 'main'

TraceView::Config[:tracing_mode] = 'through'


use Rack::Deflater
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:post, :get]
  end
end


# run API::API

run Rack::Cascade.new [API::API, Main]
