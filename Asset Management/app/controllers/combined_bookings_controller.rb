# frozen_string_literal: true

require 'irb'

# Combined booking controller
class CombinedBookingsController < ApplicationController
  load_and_authorize_resource

  # Set booking as accepted
  def set_booking_accepted
    @bookings = Booking.where(combined_booking_id: params[:id])
    rejected = false
    @bookings.each do |booking|
      next if booking.status != 1 || booking.item.user != current_user
      booking.status = 2
      if booking.save
        Notification.create(recipient: booking.user, action: 'accepted', notifiable: booking, context: 'AM')
      end

      # Rejects other bookings that have conflicts with the accepted booking
      item_id = booking.item.id
      item_bookings = Booking.where(item_id: item_id, status: 1)
      item_bookings.each do |b|
        unless booking_validation(item_id, b.start_datetime, b.end_datetime)
          b.status = 5
          b.save
          Notification.create(recipient: b.user, action: 'rejected', notifiable: b, context: 'U')
          UserMailer.booking_rejected([b]).deliver
          reject_combined_booking = CombinedBooking.find(b.combined_booking_id)
          if reject_combined_booking.bookings.where(status: %w[1 2 3 4 7]).blank?
            reject_combined_booking.status = 5
          end
          reject_combined_booking.save
          rejected = true
        end
      end
    end

    combined_booking = CombinedBooking.find(params[:id])

    if (@bookings.all?{|b| b.status == 2})
      combined_booking.status = 2
    end

    if combined_booking.save
      UserMailer.booking_approved(combined_booking.bookings).deliver
      if rejected
        # Change to yellow
        redirect_to requests_bookings_path, warning: 'Remaining bookings were successfully accepted,
          but another bookings has been rejected as a result due to time conflicts.'
      else
        redirect_to requests_bookings_path, notice: 'Remaining bookings were successfully accepted.'
      end
    end
  end

  # Set booking as rejected
  def set_booking_rejected
    @bookings = Booking.where(combined_booking_id: params[:id])
    @bookings.each do |booking|
      next if booking.status != 1 || booking.item.user != current_user
      booking.status = 5
      if booking.save
        Notification.create(recipient: booking.user, action: 'rejected', notifiable: booking, context: 'AM')
      end
    end

    combined_booking = CombinedBooking.find(params[:id])

    if (@bookings.all?{|b| b.status == 5})
      combined_booking.status = 5
    end

    if combined_booking.save
      UserMailer.booking_rejected(combined_booking.bookings).deliver
      redirect_to requests_bookings_path, notice: 'Remaining bookings were successfully rejected.'
    end
  end

  # Set booking as cancelled
  def set_booking_cancelled
    @bookings = Booking.where(combined_booking_id: params[:id])
    @bookings.each do |booking|
      booking.status = 6
      if booking.save
        Notification.create(recipient: booking.user, action: 'cancelled', notifiable: booking, context: 'AM')
      end
    end

    combined_booking = CombinedBooking.find(params[:id])
    combined_booking.status = 6
    if combined_booking.save
      combined_booking.sorted_bookings.each do |m|
        UserMailer.manager_booking_cancelled(m).deliver
      end
      redirect_to bookings_path, notice: 'Remaining bookings were successfully cancelled.'
    end
  end

  # PUT /bookings/1/set_booking_returned
  def set_booking_returned
    bookings = Booking.where(combined_booking_id: params[:id])

    bookings.each do |booking|
      next if booking.status != 3
      booking.status = 4
      if booking.save
        Notification.create(recipient: booking.user, action: 'returned', notifiable: booking, context: 'AM')
      end
    end

    combined_booking = CombinedBooking.find(params[:id])
    combined_booking.status = 4
    if combined_booking.save
      combined_booking.sorted_bookings.each do |m|
        UserMailer.manager_asset_returned(m).deliver
      end
      redirect_to bookings_path, notice: 'Remaining assets were successfully returned.'
    end
  end

  private

  def booking_validation(item_id, start_datetime, end_datetime)
    query = Booking.where(status: %w[2 3], item_id: item_id).where(
      "(start_datetime <= CAST ('#{start_datetime}' AS TIMESTAMP)
          AND end_datetime > CAST ('#{start_datetime}' AS TIMESTAMP))
        OR (start_datetime > CAST ('#{start_datetime}' AS TIMESTAMP)
            AND start_datetime < CAST ('#{end_datetime}' AS TIMESTAMP))
        OR (start_datetime = CAST ('#{start_datetime}' AS TIMESTAMP)
            AND end_datetime = CAST ('#{end_datetime}' AS TIMESTAMP))"
    ).first

    query.blank?
  end
end
