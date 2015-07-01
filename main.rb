require 'logger'

class Main < Sinatra::Base

  # set :public_folder, File.dirname(__FILE__) + '/public'

  configure do
    $db = Mongo::Client.new([ '127.0.0.1:27017' ], {:database => "standards"})
    set :db, $db
  end


  get '/' do
    "Hello World"
  end


end
