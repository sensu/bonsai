require_relative 'boot'

require 'rails/all'
require "safe_yaml/load"

# Do not use dotenv on openshift
if ( File.exists?( File.expand_path('../../.env', __FILE__) ) ) && !( Rails.env.production? || Rails.env.staging? )
  require 'dotenv'
  Dotenv.overload('.env', ".env.#{Rails.env}").tap do |env|
    if env.empty?
      fail 'Cannot run Bonsai Asset Index without a .env file.'
    end
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BonsaiAssetIndex
  class Application < Rails::Application
    config.app_name = "Bonsai Asset Index"

    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.active_record.default_timezone = :utc

    # Skip locale validation.
    # Note: if the time comes to support locales, this will want to be set to
    # true.
    config.i18n.enforce_available_locales = false

    %W[
      lib
    ].each do |path|
      config.eager_load_paths << Rails.root.join(path)
    end

    config.active_job.queue_adapter = :sidekiq

    # Use a custom exception handling application
    config.exceptions_app = proc do |env|
      ExceptionsController.action(:show).call(env)
    end

    # Define the status codes for rescuing our custom exceptions
    config.action_dispatch.rescue_responses.merge!(
      'BonsaiAssetIndex::Authorization::NoAuthorizerError'  => :not_implemented,
      'BonsaiAssetIndex::Authorization::NotAuthorizedError' => :unauthorized
    )

    config.action_controller.default_url_options = {
      host: ENV['HOST'],
      port: ENV['APP_PORT'],
      protocol: ENV['PROTOCOL']
    }

    config.action_mailer.default_url_options = {
      host: ENV['HOST'],
      port: ENV['APP_PORT'],
      protocol: ENV['PROTOCOL']
    }

    # Because Bonsai has a RESTful resource named "asset",
    # and because Rails considers the "/assets" path to be reserved,
    # we must tell Rails to reserve a different path for the asset pipeline.
    config.assets.prefix = '/web-assets'

    require Rails.root.join('lib', 'active_storage_cache_store').to_s
    config.active_storage_cache = ActiveStorageCacheStore.new

    config.x.extension_emails = ActiveRecord::Type::Boolean.new.cast(ENV.fetch('EXTENSION_EMAILS',         true))
    config.x.s3_mirroring     = ActiveRecord::Type::Boolean.new.cast(ENV.fetch('AWS_S3_MIRRORING_ENABLED', true))
  end
end
