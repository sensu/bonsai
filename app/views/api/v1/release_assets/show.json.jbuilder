json.type        "Asset"
json.api_version "core/v2"

json.metadata do
  json.name        @release_asset.extension_name
  json.namespace   'default'
  json.labels      @release_asset.labels.to_h
  json.annotations @release_asset.annotations.to_h
end

json.spec do
  json.url     @release_asset.asset_uri
  json.sha512  @release_asset.asset_sha
  json.filters Array.wrap(@release_asset.filter)
end
