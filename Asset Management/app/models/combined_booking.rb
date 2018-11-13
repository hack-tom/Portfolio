# frozen_string_literal: true

# == Schema Information
#
# Table name: combined_bookings
#
#  id       :integer          not null, primary key
#  status   :integer
#  owner_id :integer
#  user_id  :integer
#
# Indexes
#
#  index_combined_bookings_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

# Combined booking model
class CombinedBooking < ApplicationRecord
  belongs_to :user
  has_many :bookings
  has_many :items, through: :bookings

  validates :user, presence: true

  scope :find_by_owner, ->(user) { where owner_id: user.id }
  scope :find_by_user, ->(user) { where user_id: user.id }
  scope :item_owned_by, ->(user) { joins(:item).where(items: {user: user}) }
  scope :pending, -> { where status: 1 }
  scope :accepted, -> { where status: 2 }
  scope :ongoing, -> { where status: 3 }
  scope :completed, -> { where status: %w[4 6] }
  scope :rejected, -> { where status: 5 }
  scope :cancelled, -> { where status: 6 }
  scope :late, -> { where status: 7 }

  def sorted_bookings
    managers = bookings.map { |b| b.item.user }.uniq
    managers.map { |m| Booking.joins(:item).where('items.user_id = ? AND combined_booking_id = ?', m.id, id) }
  end
end
