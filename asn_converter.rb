class ASNConverter

  def self.convert(path)
    hash = Oj.load(File.read(path))

    new_hash = hash.reduce({}) do |memo, tuple|
      new_key = tuple[0].match(/^http\:\/\/asn\.jesandco\.org\/resources\/(.*)/).to_a.last
      new_value = ResourceConverter.convert(tuple[1])
      memo[new_key] = new_value
      memo
    end

    File.write('converted_' + path, Oj.dump(new_hash))
  end

end
