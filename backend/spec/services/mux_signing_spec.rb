require "rails_helper"

RSpec.describe MuxSigning do
  let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:exp) { 5.minutes.from_now }

  it "builds a signed playback token" do
    token = described_class.new(
      signing_key_id: "key_123",
      private_key: rsa_key.to_pem,
    ).token_for("playback_abc", exp: exp)

    payload, = JWT.decode(token, nil, false)

    expect(payload["sub"]).to eq("playback_abc")
    expect(payload["aud"]).to eq("v")
    expect(payload["kid"]).to eq("key_123")
    expect(payload["exp"]).to be_within(5).of(exp.to_i)
  end

  it "accepts a base64-encoded private key" do
    encoded_key = Base64.strict_encode64(rsa_key.to_pem)

    token = described_class.new(
      signing_key_id: "key_123",
      private_key: encoded_key,
    ).token_for("playback_abc", exp: exp)

    expect(token).to be_present
  end
end
