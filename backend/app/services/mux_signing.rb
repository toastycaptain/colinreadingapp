require "base64"
require "openssl"

class MuxSigning
  ALGORITHM = "RS256".freeze
  AUDIENCE = "v".freeze

  def initialize(
    signing_key_id: ENV["MUX_SIGNING_KEY_ID"],
    private_key: ENV["MUX_SIGNING_KEY_PRIVATE_KEY"]
  )
    @signing_key_id = signing_key_id
    @private_key = private_key
  end

  def token_for(playback_id, exp:)
    if @signing_key_id.blank? || @private_key.blank?
      raise "Mux signing key configuration is missing"
    end

    expires_at = exp.is_a?(Time) ? exp : Time.zone.parse(exp.to_s)

    payload = {
      sub: playback_id,
      aud: AUDIENCE,
      exp: expires_at.to_i,
      kid: @signing_key_id,
    }

    JWT.encode(payload, parsed_private_key, ALGORITHM)
  end

  private

  def parsed_private_key
    @parsed_private_key ||= OpenSSL::PKey::RSA.new(private_key_pem)
  end

  def private_key_pem
    raw = @private_key.to_s.gsub("\\n", "\n")
    return raw if raw.include?("BEGIN")

    Base64.decode64(raw)
  end
end
