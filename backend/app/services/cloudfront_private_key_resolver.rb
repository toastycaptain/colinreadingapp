require "base64"
require "json"

class CloudfrontPrivateKeyResolver
  def self.call
    direct_pem = ENV["CLOUDFRONT_PRIVATE_KEY_PEM"]
    return direct_pem if direct_pem.present?

    secret_id = ENV["CLOUDFRONT_PRIVATE_KEY_SECRET_ARN"] || ENV["CLOUDFRONT_PRIVATE_KEY_SECRET_NAME"]
    raise "Missing CloudFront private key config" if secret_id.blank?

    client = Aws::SecretsManager::Client.new(region: ENV.fetch("AWS_REGION"))
    secret_value = client.get_secret_value(secret_id: secret_id)

    secret_string = secret_value.secret_string.presence
    secret_string ||= Base64.decode64(secret_value.secret_binary.to_s)
    raise "CloudFront private key secret is empty" if secret_string.blank?
    extract_private_key(secret_string)
  end

  def self.extract_private_key(secret_string)
    parsed = JSON.parse(secret_string)
    parsed["private_key"] || parsed["pem"] || secret_string
  rescue JSON::ParserError
    secret_string
  end

  private_class_method :extract_private_key
end
