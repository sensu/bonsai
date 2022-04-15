require 'active_support/concern'

module ReadsGithubFiles
  extend ActiveSupport::Concern

  private

  def read_github_file(url, auth_token)
    return nil unless url.present?

    faraday = Faraday.new { |f|
      f.use FaradayMiddleware::FollowRedirects
      f.adapter :net_http
      f.basic_auth('x-oauth-basic', auth_token) if auth_token.present?
      f.headers['Accept'] = 'application/octet-stream'
    }

    response = faraday.get(url)

    response.success? ? response.body : nil
  end
end
