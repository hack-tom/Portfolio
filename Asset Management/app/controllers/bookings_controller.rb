# frozen_string_literal: true

require 'irb'

# Handles the booking system
class BookingsController < ApplicationController
  before_action :set_booking, only: %i[show edit update destroy]
  load_and_authorize_resource

  # Booking status {1: Pending, 2: Accepted, 3: Ongoing, 4: Completed,
  # 5: Rejected, 6: Cancelled, 7: Late}

  # GET /bookings
  def index
    @combined_bookings = CombinedBooking.find_by_user(current_user)
    @bookings = Booking.find_by_user(current_user)
  end

  # GET /bookings/requests
  def requests
    # Get bookings with items belonging to AM
    my_bookings = Booking.pending.item_owned_by(current_user).distinct.pluck(:combined_booking_id)

    # Get the parent combined bookings
    @combined_bookings = CombinedBooking.pending.where(id: my_bookings)
    combined_bookings_on_bookings = @combined_bookings.map{|cb| cb.bookings}.flatten

    # Get assets belonging to these combined bookings
    @bookings = Booking.where(id: combined_bookings_on_bookings)
  end

  # GET /bookings/accepted
  def accepted
    @combined_bookings = CombinedBooking.accepted.find_by_owner(current_user)
    @bookings = Booking.accepted.item_owned_by(current_user)
  end

  # GET /bookings/ongoing
  def ongoing
    @combined_bookings = CombinedBooking.ongoing.find_by_owner(current_user)
    @bookings = Booking.ongoing.item_owned_by(current_user)
  end

  # GET /bookings/completed
  def completed
    @combined_bookings = CombinedBooking.completed.find_by_owner(current_user)
    @bookings = Booking.completed.item_owned_by(current_user)
  end

  # GET /bookings/rejected
  def rejected
    @combined_bookings = CombinedBooking.rejected.find_by_owner(current_user)
    @bookings = Booking.rejected.item_owned_by(current_user)
  end

  # GET /bookings/late
  def late
    @combined_bookings = CombinedBooking.late.find_by_owner(current_user)
    @bookings = Booking.late.item_owned_by(current_user)
  end

  # GET /bookings/new
  def new
    @booking = Booking.new
    @item = Item.find_by_id(params[:item_id])

    @parents = @item.get_item_parents
    @peripherals = @item.get_item_peripherals

    # Disable the unavaliable dates for an asset
    gon.initial_disable_dates = [fully_booked_days_single, fully_booked_days_multi].reduce([], :concat)

    # Select the defaut date and time
    unless gon.initial_disable_dates.blank?
      gon.initial_disable_dates.sort!
      gon.initial_start_date = initial_start_date
    end
  end

  # GET /bookings/1/edit
  def edit
    @item = @booking.item
    @parents = @item.get_item_parents
    @peripherals = @item.get_item_peripherals

    # Show the peripherals booked with parent asset
    @booking.peripherals = @booking.peripherals.tr('[]"', '') unless @booking.peripherals.blank?
  end

  # POST /bookings
  def create
    @booking = Booking.new(booking_params)

    # Converting the format
    @booking.start_datetime = @booking.start_date.to_s + ' ' + @booking.start_time.to_s
    @booking.end_datetime = @booking.end_date.to_s + ' ' + @booking.end_time.to_s
    @booking.next_location = params[:booking][:next_location].titleize
    @booking.reason = 'None' if params[:booking][:reason].blank?

    # Creating a combined booking
    item = @booking.item

    if item.user == current_user
      @booking.status = 2
      combined_booking = CombinedBooking.create(status: 1, user_id: current_user.id, owner_id: item.user_id)
      combined_booking.save
    else
      @booking.status = 1
      combined_booking = CombinedBooking.create(status: 1, user_id: current_user.id, owner_id: item.user_id)
      combined_booking.save
    end

    @booking.combined_booking_id = combined_booking.id

    # Create bookings for the chosen peripherals
    peripherals = params[:booking][:peripherals]

    # Changing the peripherals array into a string to be saved
    if peripherals.blank?
      @booking.peripherals = nil
    else
      peripherals_string = ''
      peripherals.each do |peripheral|
        next if peripheral == ''
        peripherals_string += ',' + Item.find_by_id(peripheral).serial
      end
      @booking.peripherals = peripherals_string[1..-1]
    end

    # Server side validation
    query = booking_validation(@booking.item_id, @booking.start_datetime, @booking.end_datetime)
    unless peripherals.blank?
      peripherals.each do |peripheral|
        next if peripheral == ''
        query &&= booking_validation(peripheral, @booking.start_datetime, @booking.end_datetime)
      end
    end

    if query && @booking.save
      # Making a booking for any peripheral selected
      unless peripherals.blank?
        peripherals.each do |peripheral|
          next if peripheral == ''
          booking = Booking.new(booking_params)

          booking.item_id = peripheral
          booking.start_datetime = @booking.start_datetime
          booking.end_datetime = @booking.end_datetime
          booking.next_location = params[:booking][:next_location].titleize
          booking.reason = 'None' if params[:booking][:reason].blank?
          booking.peripherals = nil
          booking.combined_booking_id = combined_booking.id
          booking.status = booking.item.user == current_user ? 2 : 1
          booking.save
        end
      end

      if combined_booking.bookings.blank?
        combined_booking.destroy
        redirect_to bookings_path, alert: 'Error occurred in the booking process. Please try again.'
      else
        # Check if all items on booking are the current user.
        if (combined_booking.bookings.all? { |b| b.status == 2})
          combined_booking.status = 2
          combined_booking.save
        end

        # Create notifications and send out the required emails
        Notification.create(recipient: item.user, action: 'requested', notifiable: @booking, context: 'AM')
        UserMailer.user_booking_requested(combined_booking).deliver

        combined_booking.sorted_bookings.each do |m|
          UserMailer.manager_booking_requested(m).deliver
        end

        redirect_to bookings_path, notice: 'Booking was successfully created.'
      end
    else
      redirect_to new_item_booking_path(item_id: @booking.item_id), alert: 'Chosen timeslot conflicts with other bookings.'
    end
  end

  # PATCH/PUT /bookings/1
  def update
    @booking.update(params.require(:booking).permit(:next_location, :reason, :item_id, :user_id))
    redirect_to bookings_path, notice: 'Booking was successfully updated.'
  end

  def set_booking_accepted
    booking = Booking.find(params[:id])
    booking.status = 2
    if booking.save
      # Create notifications and send our emails
      Notification.create(recipient: @booking.user, action: 'approved', notifiable: @booking, context: 'U')
      UserMailer.booking_approved([@booking]).deliver

      combined_booking = CombinedBooking.find(@booking.combined_booking_id)
      if combined_booking.bookings.where(status: %w[1 3 7]).blank?
        combined_booking.status = 2
      end
      combined_booking.save
    end

    # Rejects other bookings that have conflicts with the accepted booking
    item_id = booking.item.id
    item_bookings = Booking.where(item_id: item_id, status: 1)
    rejected = false
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

    if rejected
      redirect_to requests_bookings_path, warning: 'Booking was successfully accepted,
        but another booking has been rejected as a result due to time conflicts.'
    else
      redirect_to requests_bookings_path, notice: 'Booking was successfully accepted.'
    end
  end

  def set_booking_rejected
    booking = Booking.find(params[:id])
    booking.status = 5
    if booking.save
      Notification.create(recipient: @booking.user, action: 'rejected', notifiable: @booking, context: 'U')
      UserMailer.booking_rejected([@booking]).deliver

      combined_booking = CombinedBooking.find(@booking.combined_booking_id)
      if combined_booking.bookings.where(status: %w[1 2 3 4 7]).blank?
        combined_booking.status = 5
      end
      combined_booking.save
    end

    redirect_to requests_bookings_path, notice: 'Booking was successfully rejected.'
  end

  # Set booking as cancelled
  def set_booking_cancelled
    @booking = Booking.find(params[:id])
    @booking.status = 6
    if @booking.save
      combined_booking = CombinedBooking.find(@booking.combined_booking_id)
      if combined_booking.bookings.where(status: %w[1 2 3 4 5 7]).blank?
        combined_booking.status = 6
        combined_booking.save
      end
      Notification.create(recipient: @booking.user, action: 'cancelled', notifiable: @booking, context: 'AM')
      UserMailer.manager_booking_cancelled([@booking]).deliver
      redirect_to bookings_path, notice: 'Booking was successfully cancelled.'
    end
  end

  # GET /bookings/1/booking_returned
  def booking_returned
    @item = @booking.item
  end

  # PUT /bookings/1/set_booking_returned
  def set_booking_returned
    booking = Booking.find(params[:id])
    booking.status = 4

    if booking.save
      combined_booking = CombinedBooking.find(booking.combined_booking_id)
      if combined_booking.bookings.where(status: %w[3 7]).blank?
        combined_booking.status = 4
        combined_booking.save
      end

      Notification.create(recipient: booking.user, action: 'returned', notifiable: booking, context: 'AM')
      UserMailer.manager_asset_returned([@booking]).deliver

      item = booking.item
      item.condition = params[:item][:condition]
      item.condition_info = params[:item][:condition_info]

      if (item.condition == 'Missing') || (item.condition == 'Damaged')
        Notification.create(recipient: item.user, action: 'reported', notifiable: item, context: 'AM')
        UserMailer.manager_asset_issue(booking.user, item).deliver
      end

      item.save

      if item.user == current_user
        redirect_to bookings_path, notice: 'Thank you. Your item has been returned'
      elsif %w[Damaged Missing].include? item.condition.to_s
        redirect_to bookings_path, notice: 'We have logged the issue and your item has been returned'
      else
        redirect_to bookings_path, notice: 'Thank you. Your item has been returned'
      end
    end
  end

  # Start date ajax call from /bookings/new
  def start_date
    data = {
      disable_start_time: disable_start_time(params[:start_date])
    }

    render json: data
  end

  # End date ajax call from /bookings/new
  def end_date
    if params[:end_date].blank?
      data = {
        max_end_date: max_end_date(params[:start_date], params[:start_time])
      }
    else
      data = {
        max_end_date: max_end_date(params[:start_date], params[:start_time]),
        max_end_time: max_end_time(params[:start_date], params[:end_date], params[:start_time])
      }
    end

    render json: data
  end

  # Peripherals list ajax call from /bookings/new
  def peripherals
    @item = Item.find_by_id(params[:item_id])

    @peripherals = get_allowed_peripherals(params[:start_datetime], params[:end_datetime], params[:item_id])

    respond_to do |format|
      format.json do
        render json: @peripherals
      end
    end
  end

  private

  def get_allowed_peripherals(start_datetime, end_datetime, item_id)
    item = Item.find_by_id(item_id)
    peripherals = item.get_item_peripherals

    allowed_peripherals = []
    peripherals.each do |peripheral|
      if booking_validation(peripheral.id, start_datetime, end_datetime)
        allowed_peripherals.append(peripheral)
      end
    end

    allowed_peripherals
  end

  # Server-side validation for booking time slot
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

  # Fully booked days in a single booking
  def fully_booked_days_single
    date_to_disable = []
    bookings = Booking.where(status: %w[2 3], item_id: params[:item_id]).where(
      "start_date <> end_date
      AND ((start_time = '2000-01-01 00:00:00 UTC'
          AND end_time = '2000-01-01 00:00:00 UTC'
          AND DATE_PART('day', to_char(end_datetime, 'YYYY-MM-DD HH24:MI:SS')::timestamp - to_char(start_datetime, 'YYYY-MM-DD HH24:MI:SS')::timestamp) = 1)
        OR
          (DATE_PART('day', to_char(end_datetime, 'YYYY-MM-DD HH24:MI:SS')::timestamp - to_char(start_datetime, 'YYYY-MM-DD HH24:MI:SS')::timestamp) > 1)
        OR
          (DATE_PART('day', to_char(end_date, 'YYYY-MM-DD HH24:MI:SS')::timestamp - to_char(start_date, 'YYYY-MM-DD HH24:MI:SS')::timestamp) > 1))"
    )

    bookings.each do |booking|
      start_date = Date.parse(booking.start_date.to_s)
      end_date = Date.parse(booking.end_date.to_s)
      start_time = DateTime.parse(booking.start_datetime.to_s)

      date_array = (start_date...end_date).map(&:to_s)

      # Single booking multiple days
      if date_array.length > 1
        # Include the start date if start time is 12:00 AM
        if (start_time.hour.eql? 0) || (DateTime.now > booking.start_datetime)
          date_array = date_array[0..-1]
        else
          date_array = date_array[1..-1]
        end
      end

      # Split into [year, month, day]
      date_array = date_array.map { |n| n.split('-') }

      # Datepicker month format is jan = 0, feb = 1, mar = 2...
      date_array = date_array.map { |n| n[0] = n[0], n[1] = n[1].to_i - 1, n[2] = n[2] }

      date_to_disable.concat(date_array)
    end

    date_to_disable
  end

  # Fully booked days in a multiple booking
  def fully_booked_days_multi
    date_to_disable = []

    bookings = Booking.find_by_sql [
      "WITH RECURSIVE linked_bookings AS (
          SELECT A.start_date AS start_date,
          A.start_datetime AS start_datetime,
          B.end_date AS end_date,
          B.end_datetime AS end_datetime
          FROM bookings A, bookings B
          WHERE (A.status = 2 OR A.status = 3)
          AND A.item_id = ?
          AND A.end_datetime = B.start_datetime
          AND A.id <> B.id
        UNION ALL
          SELECT p.start_date, p.start_datetime, pr.end_date, pr.end_datetime
          FROM bookings p, linked_bookings pr
          WHERE p.end_datetime = pr.start_datetime
      )
      SELECT start_date, start_datetime, end_date, end_datetime FROM linked_bookings", params[:item_id]
    ]

    bookings.each do |booking|
      start_date = Date.parse(booking.start_date.to_s)
      end_date = Date.parse(booking.end_date.to_s)
      start_time = DateTime.parse(booking.start_datetime.to_s)

      # Multiple booking across many days or Multiple bookings on single day
      next unless (end_date - start_date).to_i > 1 || (start_time.hour.eql? 0)
      date_array = (start_date...end_date).map(&:to_s)

      if date_array.length > 1
        # Include the start date if start time is 12:00 AM
        date_array = if (start_time.hour.eql? 0) || (DateTime.now.hour + 1.hour >= start_time.hour)
                       date_array[0..-1]
                     else
                       date_array[1..-1]
                     end
      end

      # Split into [year, month, day]
      date_array = date_array.map { |n| n.split('-') }

      # Datepicker month format is jan = 0, feb = 1, mar = 2...
      date_array = date_array.map { |n| n[0] = n[0], n[1] = n[1].to_i - 1, n[2] = n[2] }

      date_to_disable.concat(date_array)
    end

    date_to_disable
  end

  # Maximum selectable end date
  def max_end_date(start_date, start_time)
    date_array = []

    start_date = Date.parse(start_date)
    start_time = DateTime.parse(start_time).strftime('%H:%M')

    booking = Booking.where(status: %w[2 3], item_id: params[:item_id]).where(
      "(start_date >= CAST('#{start_date}' AS DATE)
        AND start_time > CAST('#{start_time}' AS TIME))
      OR (start_date > CAST('#{start_date}' AS DATE))", params[:item_id]
    ).minimum(:start_date)

    unless booking.blank?
      # Split into [year, month, day]
      booking = booking.strftime('%Y-%m-%d').split('-')

      # Datepicker month format is jan = 0, feb = 1, mar = 2...
      booking[1] = booking[1].to_i - 1

      date_array.concat(booking)
    end

    date_array
  end

  # Disable unavailable start time
  def disable_start_time(start_date)
    time_to_disable = []

    start_date = Date.parse(start_date)

    bookings = Booking.where(status: %w[2 3], item_id: params[:item_id]).where(
      "(start_date = CAST('#{start_date}' AS DATE))
      OR (end_date = CAST('#{start_date}' AS DATE))"
    ).select(:start_datetime, :end_datetime)

    bookings.each do |booking|
      start_time = DateTime.parse(booking.start_datetime.to_s)
      end_time = DateTime.parse(booking.end_datetime.to_s) - 1.hour

      # Selected start date is booked as start date
      if start_time.strftime('%Y-%m-%d').eql? start_date.to_s
        # Start date not equal to end date
        if (end_time.day - start_time.day).positive?
          time_to_disable.append(from: [start_time.hour.to_s, start_time.min.to_s], to: [23, 00])
        else
          # Start and end on the same day
          time_to_disable.append(
            from: [start_time.hour.to_s, start_time.min.to_s], to: [end_time.hour.to_s, end_time.min.to_s]
          )
        end
      elsif (end_time.day - start_time.day).abs.positive?
        # Selected start date is booked as end date
        time_to_disable.append(from: [0, 0], to: [end_time.hour.to_s, end_time.min.to_s])
      end
    end

    time_to_disable
  end

  # Maximum selectable end time
  def max_end_time(start_date, end_date, start_time)
    time_array = []

    start_time = DateTime.parse(start_time).strftime('%H:%M')
    start_date = Date.parse(start_date)
    end_date = Date.parse(end_date)

    # If the user selected a different start and end date
    if start_date < end_date
      booking = Booking.where(status: %w[2 3], item_id: params[:item_id]).where(
        "start_date = CAST('#{end_date}' AS DATE)"
      ).minimum(:start_time)

      # The maximum selectable end_time should be the earliest booking on the selected end_date
      time_array = [booking.hour, booking.min] unless booking.blank?
    else
      # The user selected a same start and end date
      booking = Booking.where(status: %w[2 3], item_id: params[:item_id]).where(
        "start_date = CAST('#{start_date}' AS DATE)
        AND start_time > CAST('#{start_time}' AS TIME)"
      ).minimum(:start_time)

      # The maximum selectable end time should be the earliest booking on the selected start_date
      time_array = [booking.hour, booking.min] if booking.present? && start_time < booking.strftime('%H:%M')
    end

    time_array
  end

  # Select the initial start date
  def initial_start_date
    date_start = Date.parse(
      gon.initial_disable_dates[0][0].to_s + '-' +
      gon.initial_disable_dates[0][1].to_s + '-' +
      gon.initial_disable_dates[0][2].to_s
    )

    date_end = Date.parse(
      gon.initial_disable_dates[-1][0].to_s + '-' +
      gon.initial_disable_dates[-1][1].to_s + '-' +
      gon.initial_disable_dates[-1][2].to_s
    )

    # Range of disabled dates
    date_array = (date_start..date_end).map(&:to_s)

    # List of disabled dates
    initial_disable_dates = gon.initial_disable_dates.map { |n| Date.parse(n[0].to_s + '-' + n[1].to_s + '-' + n[2].to_s).to_s }

    available_dates = date_array - initial_disable_dates

    # Get the set difference between the range and list, the first date is the initial start date
    if available_dates.blank?
      available_dates
    elsif DateTime.now.hour >= 23 && Date.parse(available_dates[0]) == Date.today - 1.month
      Date.parse(available_dates[1]) + 1.month
    else
      Date.parse(available_dates[0]) + 1.month
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_booking
    @booking = Booking.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def booking_params
    params.require(:booking).permit!
  end
end
