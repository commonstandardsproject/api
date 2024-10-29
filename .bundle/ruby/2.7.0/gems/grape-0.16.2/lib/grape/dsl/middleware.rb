require 'active_support/concern'

module Grape
  module DSL
    module Middleware
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        # Apply a custom middleware to the API. Applies
        # to the current namespace and any children, but
        # not parents.
        #
        # @param middleware_class [Class] The class of the middleware you'd like
        #   to inject.
        def use(middleware_class, *args, &block)
          arr = [middleware_class, *args]
          arr << block if block_given?

          namespace_stackable(:middleware, arr)
        end

        # Retrieve an array of the middleware classes
        # and arguments that are currently applied to the
        # application.
        def middleware
          namespace_stackable(:middleware) || []
        end
      end
    end
  end
end
