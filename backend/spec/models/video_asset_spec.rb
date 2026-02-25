require "rails_helper"

RSpec.describe VideoAsset, type: :model do
  it { is_expected.to belong_to(:book) }

  it do
    is_expected.to define_enum_for(:processing_status).with_values(
      created: 0,
      uploading: 1,
      processing: 2,
      ready: 3,
      failed: 4,
    )
  end

  it do
    is_expected.to define_enum_for(:playback_policy).with_values(
      public: 0,
      signed: 1,
    ).with_prefix(:playback_policy)
  end

  it "requires mux_upload_id while uploading" do
    asset = build(:video_asset, processing_status: :uploading, mux_upload_id: nil)

    expect(asset).not_to be_valid
    expect(asset.errors[:mux_upload_id]).to include("can't be blank")
  end

  it "requires mux asset and playback ids when ready" do
    asset = build(:video_asset, processing_status: :ready, mux_asset_id: nil, mux_playback_id: nil)

    expect(asset).not_to be_valid
    expect(asset.errors[:mux_asset_id]).to include("can't be blank")
    expect(asset.errors[:mux_playback_id]).to include("can't be blank")
  end
end
