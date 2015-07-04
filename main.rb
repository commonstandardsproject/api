require 'logger'

class Main < Sinatra::Base

  configure do
    set :db, $db
  end


  get '/' do
    "Hello World"
  end


end
