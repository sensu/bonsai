
Airbrake.configure do |c|
  c.project_id = ENV["AIRBRAKE_PROJECT_ID"]
  c.project_key = ENV["AIRBRAKE_API_KEY"]
  c.environment = Rails.env
  c.ignore_environments = %w(development test)
end