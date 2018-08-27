Rails.application.config.octokit = Octokit::Client.new(
  access_token: ENV["GITHUB_ACCESS_TOKEN"],
  client_id: ENV["GITHUB_KEY"],
  client_secret: ENV["GITHUB_SECRET"]
)