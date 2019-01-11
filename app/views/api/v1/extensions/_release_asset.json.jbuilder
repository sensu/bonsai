extension = release_asset.extension
tag       = release_asset.version_name
platform  = release_asset.platform
arch      = release_asset.arch

json.platform    platform
json.arch        arch
json.version     tag
json.asset_url   release_asset.asset_url
json.asset_sha   release_asset.asset_sha
json.details_url api_v1_release_asset_url(extension, username: release_asset.owner_name, version: tag, platform: platform, arch: arch)
