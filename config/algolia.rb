require 'algoliasearch'

application_id = ENV["ALGOLIA_APPLICATION_ID"] || ''
api_key        = ENV["ALGOLIA_API_KEY"] || ''
begin
  Algolia.init :application_id => application_id, :api_key => api_key
rescue
end
