class ChildProfile < ApplicationRecord
  belongs_to :user

  has_many :library_items, dependent: :destroy
  has_many :books, through: :library_items
  has_many :playback_sessions, dependent: :destroy
  has_many :usage_events, dependent: :destroy

  validates :name, presence: true
end
