require 'active_support/concern'

module ReadsGithubFiles
  extend ActiveSupport::Concern

  private

  def gather_github_release_asset_data_hashes(version)
    releases_data = version.octokit
                           .releases(version.github_repo)
                           .find { |h| h[:tag_name] == version.version }
                           .to_h
    Array.wrap(releases_data[:assets])
  end

  def read_github_file(url)
    return nil unless url.present?

    faraday = Faraday.new { |f|
      f.use FaradayMiddleware::FollowRedirects
      f.adapter :net_http
      f.basic_auth(ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"])
      f.headers['Accept'] = 'application/octet-stream'
    }

    response = faraday.get(url)

    response.success? ? response.body : nil
  end
end
