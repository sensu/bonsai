module Annotations 
	extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

	def common_annotations(extension, version, asset=nil)
    tags = if asset.present? && asset.labels.present? 
      asset.labels.join(', ')
    else
      version.release_assets.map{|a| a.labels}.flatten.reject(&:blank?).uniq.sort.join(', ')
    end
    tags ||= nil
    annotations = {
      'io.sensio.bonsai.url' => owner_scoped_extension_url(extension),
      'io.sensio.bonsai.api_url' => owner_scoped_release_asset_builds_api_v1_url(extension, version),
      'io.sensio.bonsai.tier' => extension.tier_name,
      'io.sensio.bonsai.version' => version.version,
      'io.sensio.bonsai.tags' => tags,
    }
    if extension.hosted?
      annotations['io.sensio.bonsai.message'] = "This asset is for users with a valid Enterprise license"
    end
    annotations
  end 

end