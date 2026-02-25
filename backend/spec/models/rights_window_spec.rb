require "rails_helper"

RSpec.describe RightsWindow, type: :model do
  it { is_expected.to belong_to(:publisher) }
  it { is_expected.to belong_to(:book) }
  it { is_expected.to validate_presence_of(:start_at) }
  it { is_expected.to validate_presence_of(:end_at) }

  describe ".active_at" do
    it "returns only windows active at the given time" do
      active = create(:rights_window, start_at: 2.hours.ago, end_at: 2.hours.from_now)
      create(:rights_window, :expired)

      expect(described_class.active_at(Time.current)).to contain_exactly(active)
    end
  end
end
