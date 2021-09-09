# OmniAuth configuration

# Set the full_host for OmniAuth
#
# If this is not set correctly, OmniAuth may not generate redirect_uri
# parameters in requests correctly.
#
# We do not need to do this in the test environment, since it's using mock_auth
# there.
#
# See http://www.kbedell.com/2011/03/08/overriding-omniauth-callback-url-for-twitter-or-facebook-oath-processing/
unless Rails.env.test?
  OmniAuth.config.full_host = BonsaiAssetIndex::Host.full_url
end

# Configure middleware used by OmniAuth
Rails.application.config.middleware.use(OmniAuth::Builder) do
  # Use an alternate URL for the Chef OAuth2 service if one is provided
  client_options = {
    ssl: {
      verify: ENV['OAUTH2_VERIFY_SSL'].present? &&
              ENV['OAUTH2_VERIFY_SSL'] != 'false'
    }
  }

  provider(
    :github,
    ENV['GITHUB_CLIENT_ID'],
    ENV['GITHUB_CLIENT_SECRET'],
    client_options: client_options,
    scope: BonsaiAssetIndex::Authentication::AUTH_SCOPE,
    provider_ignores_state: true
  ).inspect
end

# Use the Rails logger
OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [:post, :get]
