module VirtusConvert
  class Object
    def initialize(object, options = {})
      if object.respond_to?(:attributes)
        @object = VirtusConvert.new(object.attributes, options)
      else
        @object = object
      end
    end

    def to_hash
      @object.respond_to?(:to_hash) ? @object.to_hash : @object
    end
  end
end
