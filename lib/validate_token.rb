class InvalidTokenError < StandardError; end

require 'jwt'

class ValidateToken
  def self.validate(headers)
    return true
    begin
      auth0_client_id     = ENV['AUTH0_CLIENT_ID']
      auth0_client_secret = ENV['AUTH0_CLIENT_SECRET']
      authorization       = headers['Authorization']
      raise InvalidTokenError if authorization.nil?

      token = headers['Authorization'].split(' ').last
      decoded_token = ::JWT.decode(token, ::JWT.base64url_decode(auth0_client_secret))

      raise InvalidTokenError if auth0_client_id != decoded_token[0]["aud"]
    rescue ::JWT::DecodeError
      raise InvalidTokenError
    end
  end
end
