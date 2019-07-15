json.type        "Asset"
json.api_version "core/v2"

json.metadata do
  json.name         @release_asset.extension_name
  json.labels       nil
  json.annotations  @annotations
end

json.spec do
  json.url            @release_asset.vanity_url
  json.sha512         @release_asset.source_asset_sha
  json.filters        @release_asset.filter
end
