begin
  require 'byebug'
rescue LoadError; end

require 'dry-logic'

SPEC_ROOT = Pathname(__dir__)

Dir[SPEC_ROOT.join('shared/**/*.rb')].each(&method(:require))
Dir[SPEC_ROOT.join('support/**/*.rb')].each(&method(:require))

include Dry::Logic

RSpec.configure do |config|
  config.disable_monkey_patching!
end
