module Grape
  module Formatter
    module SerializableHash
      class << self
        def call(object, _env)
          return object if object.is_a?(String)
          return MultiJson.dump(serialize(object)) if serializable?(object)
          return object.to_json if object.respond_to?(:to_json)
          MultiJson.dump(object)
        end

        private

        def serializable?(object)
          object.respond_to?(:serializable_hash) || object.is_a?(Array) && !object.map { |o| o.respond_to? :serializable_hash }.include?(false) || object.is_a?(Hash)
        end

        def serialize(object)
          if object.respond_to? :serializable_hash
            object.serializable_hash
          elsif object.is_a?(Array) && !object.map { |o| o.respond_to? :serializable_hash }.include?(false)
            object.map(&:serializable_hash)
          elsif object.is_a?(Hash)
            h = {}
            object.each_pair do |k, v|
              h[k] = serialize(v)
            end
            h
          else
            object
          end
        end
      end
    end
  end
end
