# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Require gems used by epi_cas
require 'devise'
require 'devise_cas_authenticatable'
require 'devise_ldap_authenticatable'
require 'sheffield_ldap_lookup'
module Project
  class Application < Rails::Application
    # Send queued jobs to delayed_job
    config.active_job.queue_adapter = :delayed_job

    # This points to our own routes middleware to handle exceptions
    config.exceptions_app = routes
    config.action_view.automatically_disable_submit_tag = false

    I18n.enforce_available_locales = false
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.fixture_replacement    :factory_girl, dir: 'spec/factories'
      g.test_framework :rspec, fixture:  true,
                               helper_specs:  true,
                               routing_specs:  false,
                               controller_specs:  false,
                               view_specs:  false,
                               integration_tool:  false
    end

    config.to_prepare do
      # Configure single controller layout
      Devise::SessionsController.layout false

      # Or to configure mailer layout
      Devise::Mailer.layout 'email' # email.haml or email.erb
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
