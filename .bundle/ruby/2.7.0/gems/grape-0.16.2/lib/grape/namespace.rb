module Grape
  # A container for endpoints or other namespaces, which allows for both
  # logical grouping of endpoints as well as sharing commonconfiguration.
  # May also be referred to as group, segment, or resource.
  class Namespace
    attr_reader :space, :options

    # @param space [String] the name of this namespace
    # @param options [Hash] options hash
    # @option options :requirements [Hash] param-regex pairs, all of which must
    #   be met by a request's params for all endpoints in this namespace, or
    #   validation will fail and return a 422.
    def initialize(space, options = {})
      @space = space.to_s
      @options = options
    end

    # Retrieves the requirements from the options hash, if given.
    # @return [Hash]
    def requirements
      options[:requirements] || {}
    end

    # (see ::joined_space_path)
    def self.joined_space(settings)
      (settings || []).map(&:space).join('/')
    end

    # Join the namespaces from a list of settings to create a path prefix.
    # @param settings [Array] list of Grape::Util::InheritableSettings.
    def self.joined_space_path(settings)
      Grape::Router.normalize_path(joined_space(settings))
    end
  end
end
