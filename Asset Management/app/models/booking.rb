# frozen_string_literal: true

# == Schema Information
#
# Table name: bookings
#
#  id                  :integer          not null, primary key
#  start_date          :date
#  start_time          :time
#  end_date            :date
#  end_time            :time
#  start_datetime      :datetime
#  end_datetime        :datetime
#  reason              :string
#  next_location       :string
#  status              :integer
#  peripherals         :string
#  item_id             :integer
#  combined_booking_id :integer
#  user_id             :integer
#
# Indexes
#
#  index_bookings_on_combined_booking_id  (combined_booking_id)
#  index_bookings_on_item_id              (item_id)
#  index_bookings_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (combined_booking_id => combined_bookings.id)
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (user_id => users.id)
#

# Booking model
class Booking < ApplicationRecord
  belongs_to :item, dependent: :destroy
  belongs_to :user
  belongs_to :combined_booking
  before_destroy :send_email_to_user
  after_destroy :destroy_combined_booking

  validates :start_date, :start_time,
            :end_date, :end_time,
            :next_location,
            :item, :user, :combined_booking, presence: true

  scope :find_by_user, ->(user) { where user: user }
  scope :item_owned_by, ->(user) { joins(:item).where(items: { user: user }) }
  scope :pending, -> { where status: 1 }
  scope :accepted, -> { where status: 2 }
  scope :ongoing, -> { where status: 3 }
  scope :completed, -> { where status: %w[4 6] }
  scope :rejected, -> { where status: 5 }
  scope :cancelled, -> { where status: 6 }
  scope :late, -> { where status: 7 }

  private

  def send_email_to_user
    UserMailer.user_booking_cancelled(self).deliver
    Notification.create(recipient: self.user, action: 'itemdeleted', notifiable: self, context: 'U')
  end

  def destroy_combined_booking
    combined_booking.destroy if combined_booking.bookings.blank?
  end
end
