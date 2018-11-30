json.type "Asset"
json.spec do
  json.name      @github_asset.extension_name
  json.url       @github_asset.asset_url
  json.sha512    @github_asset.asset_sha
  json.namespace @github_asset.extension_namespace
end
