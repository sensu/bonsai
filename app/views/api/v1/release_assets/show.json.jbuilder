json.type        "Asset"
json.api_version "core/v2"

json.metadata do
  json.name         @release_asset.extension_name
  json.namespace    @release_asset.extension_namespace
  json.labels       @release_asset.labels
  json.version      @release_asset.version
  json.annotations  @release_asset.annotations
end

json.spec do
  json.url     				@release_asset.source_asset_url
  json.sha512  				@release_asset.source_asset_sha
  json.asset_url  		@release_asset.vanity_url
  json.last_modified  @release_asset.last_modified
  json.filters        @release_asset.filter
end
