# frozen_string_literal: true

# Default mailer, do not change
class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@sheffield.ac.uk'
  layout 'mailer'
end
