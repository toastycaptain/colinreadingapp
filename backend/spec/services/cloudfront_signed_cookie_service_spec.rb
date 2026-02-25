require "rails_helper"

RSpec.describe CloudfrontSignedCookieService do
  describe "#generate_for_book" do
    it "returns CloudFront policy/signature/key-pair cookies" do
      private_key = OpenSSL::PKey::RSA.generate(1024)

      service = described_class.new(
        cloudfront_domain: "d111111abcdef8.cloudfront.net",
        key_pair_id: "K2JCJMDEHXQW5F",
        private_key_pem: private_key.to_pem,
      )

      result = service.generate_for_book(book_id: 123, expires_at: 5.minutes.from_now)
      cookie_names = result[:cookies].map { |cookie| cookie[:name] }

      expect(result[:policy]).to include("https://d111111abcdef8.cloudfront.net/books/123/*")
      expect(cookie_names).to contain_exactly(
        "CloudFront-Policy",
        "CloudFront-Signature",
        "CloudFront-Key-Pair-Id",
      )
    end
  end
end
