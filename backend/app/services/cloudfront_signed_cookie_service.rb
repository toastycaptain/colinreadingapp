require "base64"
require "openssl"

class CloudfrontSignedCookieService
  def initialize(cloudfront_domain:, key_pair_id:, private_key_pem:)
    @cloudfront_domain = cloudfront_domain
    @key_pair_id = key_pair_id
    @private_key = OpenSSL::PKey::RSA.new(private_key_pem)
  end

  def generate_for_book(book_id:, expires_at:)
    resource = "https://#{@cloudfront_domain}/books/#{book_id}/*"
    policy_hash = {
      Statement: [
        {
          Resource: resource,
          Condition: {
            DateLessThan: {
              "AWS:EpochTime": expires_at.to_i,
            },
          },
        },
      ],
    }

    policy = policy_hash.to_json
    signature = @private_key.sign(OpenSSL::Digest::SHA1.new, policy)

    {
      policy: policy,
      cookies: [
        cookie_payload("CloudFront-Policy", encode(policy), expires_at),
        cookie_payload("CloudFront-Signature", encode(signature), expires_at),
        cookie_payload("CloudFront-Key-Pair-Id", @key_pair_id, expires_at),
      ],
    }
  end

  private

  def cookie_payload(name, value, expires_at)
    {
      name: name,
      value: value,
      domain: cookie_domain,
      path: "/",
      expires: expires_at.iso8601,
      secure: true,
      http_only: false,
    }
  end

  def cookie_domain
    @cloudfront_domain.start_with?(".") ? @cloudfront_domain : ".#{@cloudfront_domain}"
  end

  def encode(data)
    Base64.strict_encode64(data).tr("+=/", "-_~")
  end
end
