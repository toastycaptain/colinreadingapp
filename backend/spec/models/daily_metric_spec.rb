require "rails_helper"

RSpec.describe DailyMetric, type: :model do
  it { is_expected.to belong_to(:publisher).optional }
  it { is_expected.to belong_to(:book).optional }
  it { is_expected.to validate_presence_of(:metric_date) }
end
