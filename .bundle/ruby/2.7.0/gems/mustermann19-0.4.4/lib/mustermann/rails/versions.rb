module Mustermann
  # Mixin that adds support for multiple versions of the same type.
  # @see Mustermann::Rails
  # @!visibility private
  module Versions
    # Checks if class has mulitple versions available and picks one that matches the version option.
    # @!visibility private
    def new(*args)
      options = args.last.kind_of?(Hash) ? args.pop : {}
      version = options.fetch(:version, nil)
      options.delete(:version)
      return super(*args, options) unless versions.any?
      self[version].new(*args, options)
    end

    # @return [Hash] version to subclass mapping.
    # @!visibility private
    def versions
      @versions ||= {}
    end

    # Defines a new version.
    # @!visibility private
    def version(*list, &block)
      options = list.last.kind_of?(Hash) ? args.pop : {}
      inherit_from = options.fetch(:inherit_from, nil)
      superclass = self[inherit_from] || self
      subclass   = Class.new(superclass, &block)
      list.each { |v| versions[v] = subclass }
    end

    # Resolve a subclass for a given version string.
    # @!visibility private
    def [](version)
      return versions.values.last unless version
      detected = versions.detect { |v,_| version.start_with?(v) }
      raise ArgumentError, 'unsupported version %p' % version unless detected
      detected.last
    end

    # @!visibility private
    def name
      super || superclass.name
    end

    # @!visibility private
    def inspect
      name
    end
  end
end
