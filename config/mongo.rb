require 'mongo'

Mongo::Logger.logger.level = Logger::WARN
connection_string = ENV["MONGODB_CONNECTION_STRING"] || [ '127.0.0.1:27017' ]
$db = $db || Mongo::Client.new(connection_string, :database => ENV["MONGODB_DATABASE"])
