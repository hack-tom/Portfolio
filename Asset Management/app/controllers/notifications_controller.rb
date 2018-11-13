# frozen_string_literal: true

require 'irb'
require 'json'

# Notifications controller
class NotificationsController < ApplicationController
  # Method for ajax request which returns notifications for current user.
  def index
    # Get Notification context. Asset manager or user.
    @context = current_user.user? ? 'U' : 'AM'

    # Get notifications belonging to current recipient
    @notifications = Notification.where(recipient: current_user, context: @context).last(5).reverse
  end

  # Method called when user views their notifications
  def mark_as_read
    # Get all user's unread notifications
    @notifications = Notification.where(recipient: current_user).unread

    # Set read time as now
    @notifications.update_all(read_at: DateTime.now.strftime('%d %B %Y %I:%M %p'))

    # Return success
    render json: { success: true }
  end
end
