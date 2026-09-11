# Turns a Virtus model into a plain, mongo-ready hash.
#
# This replaces VirtusConvert, which wrapped every value in the tree in a
# converter object and kept the whole wrapper tree alive until `to_hash`
# finished. For a standard set with 20k standards that was ~1.2M objects and
# ~80MB of RSS for a single conversion; doing it directly is ~320k objects and
# ~20MB for the same (identical) result.
module DeepAttributes

  def self.to_hash(value)
    case value
    when ::Hash
      value.each_with_object({}){|(key, item), memo| memo[key] = self.to_hash(item) }
    when ::Array
      value.map{|item| self.to_hash(item) }
    else
      value.respond_to?(:attributes) ? self.to_hash(value.attributes) : value
    end
  end

end
