json.name         [extension.owner_name, extension.lowercase_name].join('/')
json.description  extension.description
json.url          api_v1_extension_url(extension, username: extension.owner_name)
json.github_url   extension.github_url
json.download_url download_extension_url(extension, username: extension.owner_name)
json.deprecated		extension.deprecated
if extension.deprecated
	json.replacement do 
		json.name			[extension.replacement.owner_name, extension.replacement.lowercase_name].join('/')
		json.url 			extension_url(extension.replacement, username: extension.replacement.owner_name)
		json.api_url 	api_v1_extension_url(extension.replacement, username: extension.replacement.owner_name)
	end
end

json.versions extension.extension_versions,
            partial: 'extension_version',
            as:      :version