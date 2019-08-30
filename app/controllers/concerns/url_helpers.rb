module UrlHelpers
	extend ActiveSupport::Concern

	protected

  def owner_scoped_extension_url(extension)
    if extension.hosted?
      extension_url(extension, username: "#{ENV['HOST_ORGANIZATION']}")
    else
      extension_url(extension, username: extension.owner_name)
    end
  end

  def owner_scoped_api_v1_extension_url(extension)
    if extension.hosted?
      api_v1_extension_url(username: "#{ENV['HOST_ORGANIZATION']}", id: extension.lowercase_name)
    else
      api_v1_extension_url(username: extension.owner_name, id: extension.lowercase_name)
    end
  end 

  def owner_scoped_release_asset_builds_api_v1_url(extension, version)
    if extension.hosted?
      api_v1_release_asset_builds_url(username: "#{ENV['HOST_ORGANIZATION']}", id: extension.lowercase_name, version: version.version)
    else
      api_v1_release_asset_builds_url(username: extension.owner_name, id: extension.lowercase_name, version: version.version)
    end
  end 

end