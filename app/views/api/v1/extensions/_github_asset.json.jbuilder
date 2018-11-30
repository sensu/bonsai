extension = github_asset.extension
tag       = github_asset.version_name
platform  = github_asset.platform
arch      = github_asset.arch

json.platform    platform
json.arch        arch
json.version     tag
json.asset_url   github_asset.asset_url
json.asset_sha   github_asset.asset_sha
json.details_url api_v1_github_asset_url(extension, username: github_asset.owner_name, version: tag, platform: platform, arch: arch)
