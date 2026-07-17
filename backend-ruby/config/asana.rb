require 'asana'

AsanaClient = Asana::Client.new do |c|
  c.authentication :access_token, ENV["ASANA_PERSONAL_ACCESS_TOKEN"]
end
