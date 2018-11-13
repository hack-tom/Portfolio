# frozen_string_literal: true

# User mailer class
class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: user.email, subject: "AMRC - Welcome: #{user.givenname} #{user.sn}"
  end

  def booking_approved(bookings)
    @booking = bookings[0]
    @user = @booking.user
    @items = bookings.map(&:item)
    @manager = bookings[0].item.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Booking Confirmed'
  end

  # Updated CombinedBooking
  def booking_ongoing(booking)
    @booking = booking
    @user = booking.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Booking Started'
  end

  # Takes CombinedBooking - UPDATED
  def user_booking_requested(booking)
    @booking = booking
    @user = booking.user
    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Booking Recieved'
  end

  # Takes array of bookings - UPDATED
  def manager_booking_requested(bookings)
    @booking = bookings[0]
    @user = @booking.user
    @items = bookings.map(&:item)
    @manager = bookings[0].item.user
    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @manager.email, subject: 'AMRC - Booking Requested'
  end

  # Takes array of bookings - UPDATED
  def manager_asset_returned(bookings)
    @booking = bookings[0]
    @user = @booking.user
    @items = bookings.map(&:item)
    @manager = bookings[0].item.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @manager.email, subject: 'AMRC - Item Returned'
  end

  def manager_asset_issue(user, item)
    @user = user
    @item = item
    @manager = @item.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @manager.email, subject: "AMRC - Item Issue: #{@item.name}"
  end

  # Update list bookings
  def manager_booking_cancelled(bookings)
    @booking = bookings[0]
    @user = @booking.user
    @items = bookings.map(&:item)
    @manager = bookings[0].item.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @manager.email, subject: 'AMRC - Booking Cancelled'
  end

  def booking_rejected(bookings)
    @booking = bookings[0]
    @user = @booking.user
    @items = bookings.map(&:item)
    @manager = bookings[0].item.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Booking Rejected'
  end

  # Updated to take combined_booking
  def asset_due(booking)
    @booking = booking
    @user = booking.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Return Due Soon'
  end

  # Updated to take combined_booking
  def asset_overdue(booking)
    @booking = booking
    @user = booking.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")

    mail to: @user.email, subject: 'AMRC - Late For Return'
  end


  def user_booking_cancelled(booking)
    @booking = booking
    @user = booking.user

    attachments.inline['amrc_main.png'] = File.read("#{Rails.root}/app/assets/images/amrc_main.png")
    mail to: @user.email, subject: 'AMRC - Asset Removed From System'
  end
end
