require 'logger'
# require "skylight/sinatra"

# Skylight.start!

class Main < Sinatra::Base
  use Rack::ShowExceptions
  configure do
    p "CONFIG"
    set :db, $db
  end


  # Renders the swagger api docs
  get '/' do
    p "MAIN"
    File.read(File.join('public', 'index.html'))
  end


end
