require 'logger'

class Main < Sinatra::Base

  configure do
    set :db, $db
  end


  # Renders the swagger api docs
  get '/' do
    File.read(File.join('public', 'index.html'))
  end


end
