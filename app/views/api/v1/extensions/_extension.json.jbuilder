json.name         [extension.owner_name, extension.lowercase_name].join('/')
json.description  extension.description
json.url          api_v1_extension_url(extension, username: extension.owner_name)
json.github_url   extension.github_url
json.download_url download_extension_url(extension, username: extension.owner_name)

json.builds extension.extension_versions.flat_map(&:github_assets),
            partial: 'github_asset',
            as:      :github_asset
