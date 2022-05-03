ENV["RACK_ENV"] ||= "development"

require File.join(File.dirname(__FILE__), 'config/boot')
require File.join(File.dirname(__FILE__), 'app/base_app')

run BaseApp