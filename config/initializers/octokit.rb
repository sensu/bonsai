Rails.application.config.octokit = Octokit::Client.new(
  access_token: ENV["GITHUB_ACCESS_TOKEN"],
  client_id: ENV["GITHUB_CLIENT_ID"],
  client_secret: ENV["GITHUB_CLIENT_SECRET"]
)