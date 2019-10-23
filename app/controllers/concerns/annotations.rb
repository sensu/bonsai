include UrlHelpers

module Annotations 
	extend ActiveSupport::Concern

  included do 
    helper_method :common_annotations
  end

	def common_annotations(extension, version, asset=nil)
    tags = if asset.present? && asset.labels.present? 
      asset.labels.join(', ')
    else
      version.release_assets.map{|a| a.labels}.flatten.reject(&:blank?).uniq.sort.join(', ')
    end
    tags ||= nil
    owner_name = extension.hosted? ? ENV['HOST_ORGANIZATION'] : extension.owner_name

    annotations = {
      'io.sensu.bonsai.url' => owner_scoped_extension_url(extension),
      'io.sensu.bonsai.api_url' => owner_scoped_api_v1_extension_url(extension),
      'io.sensu.bonsai.tier' => extension.tier_name,
      'io.sensu.bonsai.version' => version.version,
      'io.sensu.bonsai.namespace' => owner_name,
      'io.sensu.bonsai.name' => extension.lowercase_name,
      'io.sensu.bonsai.tags' => tags,
    }

    if extension.hosted?
      annotations['io.sensu.bonsai.message'] = "This asset is for users with a valid Enterprise license"
    end
    
    annotations.merge(version.annotations)
  end 

end