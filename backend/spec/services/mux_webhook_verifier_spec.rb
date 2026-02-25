require "rails_helper"

RSpec.describe MuxWebhookVerifier do
  let(:secret) { "whsec_test_secret" }
  let(:body) { '{"type":"video.asset.ready"}' }
  let(:timestamp) { Time.current.to_i }

  def signature_for(ts, payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret, "#{ts}.#{payload}")
  end

  it "accepts a valid signature" do
    header = "t=#{timestamp},v1=#{signature_for(timestamp, body)}"

    verifier = described_class.new(signing_secret: secret)

    expect(verifier.valid?(signature_header: header, raw_body: body, now: Time.at(timestamp))).to be(true)
  end

  it "rejects stale timestamps" do
    stale_timestamp = 20.minutes.ago.to_i
    header = "t=#{stale_timestamp},v1=#{signature_for(stale_timestamp, body)}"

    verifier = described_class.new(signing_secret: secret)

    expect(verifier.valid?(signature_header: header, raw_body: body, now: Time.current)).to be(false)
  end

  it "rejects invalid signatures" do
    header = "t=#{timestamp},v1=deadbeef"

    verifier = described_class.new(signing_secret: secret)

    expect(verifier.valid?(signature_header: header, raw_body: body, now: Time.at(timestamp))).to be(false)
  end
end
