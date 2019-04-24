module Annotations 
	extend ActiveSupport::Concern

	def common_annotations(extension, version, asset)
    annotations = {
      'sensio.io.bonsai.url' => asset.vanity_url,
      'sensio.io.bonsai.tier' => extension.tier_name,
      'sensio.io.bonsai.version' => version.version,
      'sensio.io.bonsai.tags' => asset.labels,
    }
    if extension.hosted?
      annotations['sensio.io.bonsai.message'] = "This asset is for users with a valid Enterprise license"
    end
    annotations
  end 

end