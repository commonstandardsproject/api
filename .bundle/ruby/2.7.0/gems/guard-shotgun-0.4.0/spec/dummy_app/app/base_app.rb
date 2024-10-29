class BaseApp < Sinatra::Base
  #raise "Failing app"

  get '/' do
    "Hello world, naturally!"
  end
end
