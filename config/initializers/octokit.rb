Rails.application.config.octokit = Octokit::Client.new(
  access_token: ENV["GITHUB_ACCESS_TOKEN"]
)