require "rails_helper"

RSpec.describe VideoAsset, type: :model do
  it { is_expected.to belong_to(:book) }
  it { is_expected.to validate_presence_of(:master_s3_key) }
  it { is_expected.to define_enum_for(:processing_status).with_values(uploaded: 0, processing: 1, ready: 2, failed: 3) }
end
