require 'pp'
require 'grape'
require 'grape-swagger'
require 'grape_logging'
require 'jwt'
require 'skylight'
require 'grape-skylight'
require_relative "../config/mongo"
require_relative 'entities/jurisdiction'
require_relative 'entities/jurisdiction_summary'
require_relative 'entities/standard_set'
require_relative "users"
require_relative "commits"
require_relative "jurisdictions"
require_relative "standard_documents"
require_relative "standard_sets"
require_relative "standard_set_import"

module API
  class API < Grape::API

    logger.formatter = ::GrapeLogging::Formatters::Default.new
    use ::GrapeLogging::Middleware::RequestLogger, { logger: logger }

    format :json
    prefix :api


    # ==================
    # JWT Authentication
    # ==================
    # We use this authentication for POST requests.

    helpers do
      def validate_token
        begin
          auth0_client_id     = ENV['AUTH0_CLIENT_ID']
          auth0_client_secret = ENV['AUTH0_CLIENT_SECRET']
          authorization       = headers['Authorization']
          if authorization.nil?
            error!("No Authorization Token", 401)
          end

          token = headers['Authorization'].split(' ').last
          decoded_token = ::JWT.decode(token, ::JWT.base64url_decode(auth0_client_secret))

          if auth0_client_id != decoded_token[0]["aud"]
            error!("Invalid Token", 401)
          end
        rescue ::JWT::DecodeError
          error!("Invalid Token", 401)
        end
      end
    end

    # ======================
    # Api Key Authentication
    # ======================
    # Make sure each request has an auth token and originates from
    # an origin specified in the user's document
    before do
      key = headers["Api-Key"] || params["api-key"]

      if request.path.include? "/api/swagger_doc"
        next
      end

      @user = $db[:users].find({apiKey: key}).find_one_and_update({
        "$inc" => {requestCount: 1}
      })

      if @user.nil?
        error!('Unauthorized: Not a valid auth key. Sign up at commonstandardsproject.com', 401)
      end

      if env["HTTP_ORIGIN"] && @user[:allowedOrigins].include?(env["HTTP_ORIGIN"]) == false
        error!("Unauthorized: Origin isn't an allowed origin.", 401)
      end

    end

    # =============
    # API Endpoints
    # =============
    # To make the API a bit easier to read, I broke up the Endpoints
    # into their own files.

    mount ::API::Users
    mount ::API::Commits
    mount ::API::Jurisdictions
    mount ::API::StandardDocuments
    mount ::API::StandardSets


    # =====================
    # Swagger Documentation
    # =====================
    # Sweet little gem creates the documentation for us

    add_swagger_documentation api_version: "v1",
                              hide_format: true,
                              hide_documentation_path: true,
                              models: [Entities::Jurisdiction, Entities::StandardSetSummary, Entities::StandardSet]

  end
end
