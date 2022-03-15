json.platform    		release_asset.platform
json.arch        		release_asset.arch
json.filter  				release_asset.filter
json.annotations		common_annotations(release_asset.extension_version.extension, release_asset.extension_version, release_asset)
json.asset_sha   		release_asset.source_asset_sha
json.asset_url			release_asset.asset_url
json.last_modified 	release_asset.last_modified
json.details_url 		api_v1_release_asset_url(username: release_asset.owner_name, id: release_asset.extension_lowercase_name, version: release_asset.version, platform: release_asset.platform, arch: release_asset.arch)
