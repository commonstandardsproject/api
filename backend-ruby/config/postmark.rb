require 'postmark'
PostmarkClient = Postmark::ApiClient.new(ENV["POSTMARK_API_TOKEN"], http_ssl_version: :TLSv1_2)
