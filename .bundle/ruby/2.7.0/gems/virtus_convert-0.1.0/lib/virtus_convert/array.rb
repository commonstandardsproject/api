module VirtusConvert
  class Array
    def initialize(array = [], options = {})
      array.reject!{|item| item.nil?} if options[:reject_nils]
      @array = array.map{|item| VirtusConvert.new(item, options)}
    end

    def to_hash
      @array.map(&:to_hash)
    end

  end
end
