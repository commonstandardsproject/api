require 'mongo'

logger = Logger.new(STDOUT)
logger.level = ENV['MONGODB_LOGGING_LEVEL'] || Logger::INFO
Mongo::Logger.logger = logger
connection_string = ENV["MONGODB_CONNECTION_STRING"] || [ '127.0.0.1:27017' ]
$db = $db || Mongo::Client.new(connection_string, :database => 'common-standards-project')
