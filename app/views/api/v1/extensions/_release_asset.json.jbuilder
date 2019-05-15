json.platform    		release_asset.platform
json.arch        		release_asset.arch
json.filter  				release_asset.filter
json.annotations		release_asset.extension_version.annotations
json.asset_sha   		release_asset.source_asset_sha
json.asset_url			release_asset.vanity_url
json.last_modified 	release_asset.last_modified
json.details_url 		api_v1_release_asset_url(@extension, username: release_asset.owner_name, version: release_asset.version, platform: release_asset.platform, arch: release_asset.arch)
