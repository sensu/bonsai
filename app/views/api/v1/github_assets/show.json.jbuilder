json.type        "Asset"
json.api_version "core/v2"

json.metadata do
  json.name        @github_asset.extension_name
  json.namespace   'default'
  json.labels      @github_asset.labels.to_h
  json.annotations @github_asset.annotations.to_h
end

json.spec do
  json.url     @github_asset.asset_url
  json.sha512  @github_asset.asset_sha
  json.filters Array.wrap(@github_asset.filter)
end
