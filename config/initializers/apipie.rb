Apipie.configure do |config|
  config.app_name                = Rails.configuration.app_name
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/apidoc"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/**/*.rb"

  config.validate  = false
  config.translate = false
  config.markup    = Apipie::Markup::Markdown.new

  config.app_info =<<-EOAI
    API Overview
    ------------

    The #{Rails.configuration.app_name} application includes an application programming interface (API)
    for retrieving information about assets.

    ### Service Endpoint

    All API endpoints are rooted at the URL [https://#{ENV['HOST']}/api/v1/](/api/v1/).
    All requests to the host must use the secure HTTPS protocol.

    ### Authorization

    Currently, the #{Rails.configuration.app_name} application does not authenticate the caller
    making requests to the endpoints, and therefore does not authorize specific endpoints
    according to the caller's permission level.  In the future, this may change.

    ### JSON Payloads

    The responses returned by the API endpoints have JSON data payloads.  The JSON format is custom
    to the #{Rails.configuration.app_name} application and does not follow any of the latest standards.
    Please see the documentation for each endpoint for a detailed example of the endpoint's response payload.

    ### HTTP Status Codes

    Requests to the API endpoints may result in one of the following status codes:

    * `200` - Successful data retrieval
    * `404` - The requested item is not found
  EOAI
end
