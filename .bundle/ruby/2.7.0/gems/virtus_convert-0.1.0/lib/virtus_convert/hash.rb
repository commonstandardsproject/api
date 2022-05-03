module VirtusConvert
  class Hash
    def initialize(hash = {}, options = {})
      hash.reject!{|k, v| v.nil?} if options[:reject_nils]
      @hash = hash.inject({}){|h,(k,v)| h[k] = VirtusConvert.new(v, options); h}
    end

    def to_hash
      @hash.inject({}) do |hash,(k, v)|
        hash[k] = (v.respond_to?(:to_hash) ? v.to_hash : v)
        hash
      end
    end
  end

end

