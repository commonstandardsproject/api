# encoding: utf-8
module Grape
  module Exceptions
    class MethodNotAllowed < Base
      def initialize(headers)
        super(message: '405 Not Allowed', status: 405, headers: headers)
      end
    end
  end
end
