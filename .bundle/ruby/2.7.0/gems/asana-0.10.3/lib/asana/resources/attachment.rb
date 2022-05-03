require_relative 'gen/attachments_base'

module Asana
  module Resources
    # An _attachment_ object represents any file attached to a task in Asana,
    # whether it's an uploaded file or one associated via a third-party service
    # such as Dropbox or Google Drive.
    class Attachment < AttachmentsBase


      attr_reader :gid

      attr_reader :resource_type

      attr_reader :created_at

      attr_reader :download_url

      attr_reader :host

      attr_reader :name

      attr_reader :parent

      attr_reader :view_url

      class << self
        # Returns the plural name of the resource.
        def plural_name
          'attachments'
        end

        # Returns the full record for a single attachment.
        #
        # id - [Gid] Globally unique identifier for the attachment.
        #
        # options - [Hash] the request I/O options.
        def find_by_id(client, id, options: {})

          self.new(parse(client.get("/attachments/#{id}", options: options)).first, client: client)
        end

        # Returns the compact records for all attachments on the task.
        #
        # task - [Gid] Globally unique identifier for the task.
        #
        # per_page - [Integer] the number of records to fetch per page.
        # options - [Hash] the request I/O options.
        def find_by_task(client, task: required("task"), per_page: 20, options: {})
          params = { limit: per_page }.reject { |_,v| v.nil? || Array(v).empty? }
          Collection.new(parse(client.get("/tasks/#{task}/attachments", params: params, options: options)), type: self, client: client)
        end
      end

    end
  end
end
