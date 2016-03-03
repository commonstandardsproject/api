require 'postmark'
PostmarkClient = Postmark::ApiClient.new(ENV["POSTMARK_API_TOKEN"])
