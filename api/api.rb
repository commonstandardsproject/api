require 'pp'
require 'grape'
require 'grape-swagger'
require 'grape_logging'
require 'jwt'
require 'nokogiri'
require_relative "../config/mongo"
require_relative 'entities/jurisdiction'
require_relative 'entities/jurisdiction_summary'
require_relative 'entities/standard_set'
require_relative "users"
require_relative "jurisdictions"
require_relative "standard_documents"
require_relative "standard_sets"
require_relative "standard_set_import"
require_relative "pull_requests"

module API
  class API < Grape::API

    self.logger.level = Logger::DEBUG

    logger.formatter = ::GrapeLogging::Formatters::Default.new
    use ::GrapeLogging::Middleware::RequestLogger, { logger: logger, log_level: 'debug' }

    rescue_from :all do |e|
      ::API::API.logger.error(e)
      #do here whatever you originally planned to do :)
    end

    format :json
    prefix :api
    version 'v1', using: :path


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
          return if ENV["ENVIRONMENT"] == "test" && authorization == "TEST"
          if authorization.nil?
            error!("No Authorization Token", 401)
          end

          token = headers['Authorization'].split(' ').last
          decoded_token = ::JWT.decode(token, ::JWT::Base64.url_decode(auth0_client_secret))

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

      if request.path.include?("swagger_doc") || request.path.include?("/api/v1/sitemap.xml")
        next
      end

      @user = $db[:users].find({apiKey: key}).find_one_and_update({
        "$inc" => {requestCount: 1}
      })

      if @user.nil?
        error!('Unauthorized: Not a valid auth key. Sign up at commonstandardsproject.com', 401)
      end

      check_origin = env["ENVIRONMENT"] != "development" &&
                     env["HTTP_ORIGIN"] &&
                     env["HTTP_ORIGIN"] != "http://commonstandardsproject.com" &&
                     env["HTTP_ORIGIN"] != "http://www.commonstandardsproject.com" &&
                     env["HTTP_ORIGIN"] != "https://commonstandardsproject.com" &&
                     env["HTTP_ORIGIN"] != "https://www.commonstandardsproject.com"

      if check_origin && @user[:allowedOrigins].include?(env["HTTP_ORIGIN"]) == false
        error!("Unauthorized: Origin isn't an allowed origin.", 401)
      end

      @user["id"] = @user["_id"]
      @user
    end

    # =============
    # API Endpoints
    # =============
    # To make the API a bit easier to read, I broke up the Endpoints
    # into their own files.

    mount ::API::Users
    mount ::API::Jurisdictions
    mount ::API::StandardDocuments
    mount ::API::StandardSets
    mount ::API::PullRequests


    # This really shouldn't be in the API. However, due to how the frontend
    # is currently set up (as an Ember-CLI app), we don't have access to the node server
    # that's running underneath. I could fork Ember-CLI or fork the buildpack I'm using
    # on heroku, but that's not worth the effort at the moment.

    get '/sitemap.xml', hidden: true do
      p $db
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset("xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9") {
          $db[:standard_sets].find().projection({_id: 1}).batch_size(1000).map{|doc|
            xml.url{
              xml.loc "http://commonstandardsproject.com/search?ids=%5B\"#{doc["_id"]}\"%5D"
            }
          }
        }
      end

      content_type "text/xml"
      env['api.format'] = "xml"
      builder.to_xml
    end


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
