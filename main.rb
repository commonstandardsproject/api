require 'logger'
# require "skylight/sinatra"

# Skylight.start!

class Main < Sinatra::Base
  use Rack::ShowExceptions
  configure do
    set :db, $db
  end


  # Renders the swagger api docs
  get '/' do
    File.read(File.join('public', 'index.html'))
  end


end
