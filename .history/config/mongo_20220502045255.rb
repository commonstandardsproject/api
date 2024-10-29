require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
connection_string = ENV["MONGODB_CONNECTION_STRING"] || [ '127.0.0.1:27017' ]
if ENV['RACK_ENV'] == "development"
  $db = $db || Mongo::Client.new(connection_string, auth_mech: :scram, auth_source: 'admin', :database => ENV["MONGODB_DATABASE"], max_pool_size: 8, :direct_connection => true, :user => "schrater", :password => "mar2ia")
else
  $db = $db || Mongo::Client.new(connection_string, auth_mech: :scram, auth_source: 'admin', :database => ENV["MONGODB_DATABASE"], max_pool_size: 8)
end
