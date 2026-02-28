require "rails_helper"

RSpec.describe PublisherUser, type: :model do
  it { is_expected.to belong_to(:publisher) }

  it do
    is_expected.to define_enum_for(:role).with_values(
      owner: 0,
      finance: 1,
      analytics: 2,
      read_only: 3,
    )
  end
end
