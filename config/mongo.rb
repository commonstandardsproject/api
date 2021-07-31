require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
connection_string = ENV["MONGODB_CONNECTION_STRING"] || [ '127.0.0.1:27017' ]
if ENV['RACK_ENV'] == "development"
  auth_mech = :scram
else
  auth_mech = :scram
end
$db = $db || Mongo::Client.new(connection_string, auth_mech: auth_mech, auth_source: 'admin', :database => ENV["MONGODB_DATABASE"], max_pool_size: 8, :direct_connection => true, :user => "admin", :password => "admin")
