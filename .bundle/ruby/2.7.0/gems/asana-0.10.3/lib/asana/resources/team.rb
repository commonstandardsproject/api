require_relative 'gen/teams_base'

module Asana
  module Resources
    # A _team_ is used to group related projects and people together within an
    # organization. Each project in an organization is associated with a team.
    class Team < TeamsBase


      attr_reader :gid

      attr_reader :resource_type

      attr_reader :name

      attr_reader :description

      attr_reader :html_description

      attr_reader :organization

      class << self
        # Returns the plural name of the resource.
        def plural_name
          'teams'
        end

        # Returns the full record for a single team.
        #
        # id - [Id] Globally unique identifier for the team.
        #
        # options - [Hash] the request I/O options.
        def find_by_id(client, id, options: {})

          self.new(parse(client.get("/teams/#{id}", options: options)).first, client: client)
        end

        # Returns the compact records for all teams in the organization visible to
        # the authorized user.
        #
        # organization - [Id] Globally unique identifier for the workspace or organization.
        #
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_organization(client, organization: required("organization"), per_page: 20, options: {})
          params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/organizations/#{organization}/teams", params: params, options: options)), type: self, client: client)
        end

        # Returns the compact records for all teams to which user is assigned.
        #
        # user - [String] An identifier for the user. Can be one of an email address,
        # the globally unique identifier for the user, or the keyword `me`
        # to indicate the current user making the request.
        #
        # organization - [Id] The workspace or organization to filter teams on.
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_user(client, user: required("user"), organization: nil, per_page: 20, options: {})
          params = { organization: organization, limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/users/#{user}/teams", params: params, options: options)), type: self, client: client)
        end
      end

      # Returns the compact records for all users that are members of the team.
      #
      # per_page - [Integer] the number of records to fetch per page.
      # options - [Hash] the request I/O options.
      def users(per_page: 20, options: {})
        params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
        Collection.new(parse(client.get("/teams/#{gid}/users", params: params, options: options)), type: User, client: client)
      end

      # The user making this call must be a member of the team in order to add others.
      # The user to add must exist in the same organization as the team in order to be added.
      # The user to add can be referenced by their globally unique user ID or their email address.
      # Returns the full user record for the added user.
      #
      # user - [String] An identifier for the user. Can be one of an email address,
      # the globally unique identifier for the user, or the keyword `me`
      # to indicate the current user making the request.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def add_user(user: required("user"), options: {}, **data)
        with_params = data.merge(user: user).reject { |_,v| v.nil? || Array(v).empty? }
        User.new(parse(client.post("/teams/#{gid}/addUser", body: with_params, options: options)).first, client: client)
      end

      # The user to remove can be referenced by their globally unique user ID or their email address.
      # Removes the user from the specified team. Returns an empty data record.
      #
      # user - [String] An identifier for the user. Can be one of an email address,
      # the globally unique identifier for the user, or the keyword `me`
      # to indicate the current user making the request.
      #
      # options - [Hash] the request I/O options.
      # data - [Hash] the attributes to post.
      def remove_user(user: required("user"), options: {}, **data)
        with_params = data.merge(user: user).reject { |_,v| v.nil? || Array(v).empty? }
        client.post("/teams/#{gid}/removeUser", body: with_params, options: options) && true
      end

    end
  end
end
