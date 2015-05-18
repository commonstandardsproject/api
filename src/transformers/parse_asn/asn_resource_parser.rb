require_relative "../../key_matchers"

class ASNResourceParser

  def self.convert(path)
    hash = Oj.load(File.read(path))

    new_hash = hash.reduce({}) do |memo, tuple|
      new_key = tuple[0].match(/^http\:\/\/asn\.jesandco\.org\/resources\/(.*)/).to_a.last
      new_value = self.convert_hash(tuple[1])
      new_value["asnIdentifier"] = new_key
      memo[new_key] = new_value
      memo
    end

    File.write('output/converted_' + path.gsub('sources/', ''), Oj.dump(new_hash))
  end


  def self.convert_hash(hash)
    # Tuple has the form [key, value]
    new_hash = hash.reduce({}) do |memo, tuple|

      matcher = KEY_MATCHERS[tuple[0]]

      if !matcher.nil?
        matcher.call(tuple[0], tuple[1]).each do |ret_key,ret_value|
          memo[ret_key.to_s] = ret_value
        end
      else
        memo[tuple[0]] = tuple[1]
      end

      memo
    end

    return new_hash
  end


end
