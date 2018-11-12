require 'cgi'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
  c.filter_sensitive_data('<TOKEN>') do
    ENV['GITHUB_ACCESS_TOKEN']
  end
  c.filter_sensitive_data('<PUBSUBHUBBUB_SECRET>') do
    CGI.escape(ENV['PUBSUBHUBBUB_SECRET'])
  end
  c.filter_sensitive_data('<PUBSUBHUBBUB_SECRET>') do
    ENV['PUBSUBHUBBUB_SECRET']
  end
  c.filter_sensitive_data('<PUBSUBHUBBUB_CALLBACK>') do
    CGI.escape(ENV['PUBSUBHUBBUB_CALLBACK_URL'])
  end
  c.filter_sensitive_data('<PUBSUBHUBBUB_CALLBACK>') do
    ENV['PUBSUBHUBBUB_CALLBACK_URL']
  end
  c.filter_sensitive_data('<VALID_OCID_OAUTH_TOKEN>') do
    ENV['VALID_OCID_OAUTH_TOKEN']
  end
  c.filter_sensitive_data('<VALID_OCID_REFRESH_TOKEN>') do
    ENV['VALID_OCID_REFRESH_TOKEN']
  end

  c.default_cassette_options = {
    match_requests_on: [:method, :uri, :body]
  }
end
