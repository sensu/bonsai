# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

Rails.application.default_url_options = {
  host: ENV['HOST'],
  port: ENV['APP_PORT'],
  protocol: ENV['PROTOCOL']
}
