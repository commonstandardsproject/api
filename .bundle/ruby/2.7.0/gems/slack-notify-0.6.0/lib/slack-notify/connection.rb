module SlackNotify
  module Connection
    def send_payload(payload)
      conn = Faraday.new(@webhook_url) do |c|
        c.use(Faraday::Request::UrlEncoded)
        c.adapter(Faraday.default_adapter)
        c.options.timeout      = 5
        c.options.open_timeout = 5
      end

      response = conn.post do |req|
        req.body = JSON.dump(payload.to_hash)
      end

      handle_response(response)
    end

    def handle_response(response)
      unless response.success?
        if response.body.include?("\n")
          raise SlackNotify::Error
        else
          raise SlackNotify::Error.new(response.body)
        end
      end
    end
  end
end
