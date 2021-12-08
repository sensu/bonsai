json.type        "Asset"
json.api_version "core/v2"

json.metadata do
  json.name         @version.name
  # tags appear in the annotations section
  json.labels       nil
  json.annotations  common_annotations(@version.extension, @version)
end

json.spec do
	json.builds @version.release_assets do |asset|
	  json.url            asset.asset_url # url for base link to asset on bonsai
	  json.sha512         asset.source_asset_sha
	  json.filters        asset.filter
	end
end
