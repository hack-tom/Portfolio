# frozen_string_literal: true

# Errors controller
class ErrorsController < ApplicationController
  skip_before_action :ie_warning
  skip_before_action :verify_authenticity_token, only: [:error_422]

  # Shows error page when user is forbidden from accessing a page
  def error_403
    render 'errors/error_403'
  end

  # Page not found error
  def error_404
    render 'errors/error_404'
  end

  # Display template for bad request error.
  def error_422
    render 'errors/error_422'
  end

  # Display template for internal server error.
  def error_500
    render 'errors/error_500'
  end

  def ie_warning; end

  # Show warning for js
  def javascript_warning
    render layout: false
  end
end
