Apipie.configure do |config|
  config.app_name                = Rails.configuration.app_name
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/apidoc"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/**/*.rb"

  config.validate  = false
  config.translate = false
  config.markup    = Apipie::Markup::Markdown.new
end
