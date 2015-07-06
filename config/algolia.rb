require 'algoliasearch'

Algolia.init :application_id => ENV["ALGOLIA_APPLICATION_ID"], :api_key => ENV["ALGOLIA_API_KEY"]
