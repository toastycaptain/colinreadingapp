require "openssl"

class MuxWebhookVerifier
  DEFAULT_TOLERANCE_SECONDS = 300

  def initialize(
    signing_secret: ENV["MUX_WEBHOOK_SIGNING_SECRET"],
    tolerance_seconds: DEFAULT_TOLERANCE_SECONDS
  )
    @signing_secret = signing_secret
    @tolerance_seconds = tolerance_seconds
  end

  def valid?(signature_header:, raw_body:, now: Time.current)
    return false if @signing_secret.blank?
    return false if signature_header.blank? || raw_body.blank?

    parsed = parse_signature_header(signature_header)
    timestamp = parsed[:timestamp]
    signatures = parsed[:v1]

    return false if timestamp.nil? || signatures.empty?
    return false if stale_timestamp?(timestamp, now)

    expected = OpenSSL::HMAC.hexdigest("SHA256", @signing_secret, "#{timestamp}.#{raw_body}")
    signatures.any? { |signature| secure_compare(signature, expected) }
  end

  private

  def parse_signature_header(header)
    timestamp = nil
    signatures = []

    header.to_s.split(",").each do |part|
      key, value = part.split("=", 2)
      case key&.strip
      when "t"
        timestamp = value.to_i if value.present?
      when "v1"
        signatures << value.to_s.strip if value.present?
      end
    end

    { timestamp: timestamp, v1: signatures }
  end

  def stale_timestamp?(timestamp, now)
    (now.to_i - timestamp).abs > @tolerance_seconds
  end

  def secure_compare(left, right)
    return false if left.blank? || right.blank? || left.bytesize != right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end
end
