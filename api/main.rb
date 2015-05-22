class Main < Sinatra::Base

  configure do

    $db = Mongo::Client.new([ '127.0.0.1:27017' ], {:database => "standards"})
    set :db, $db

  end


  get '/' do
    "Hello World"
  end


end
