class ReleaseAssetsController < ApplicationController
  def download
    extension      = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    version        = extension.extension_versions.find_by!(version: params[:version])
    @release_asset = version.release_assets.find { |ga| ga.platform == params[:platform] && ga.arch == params[:arch] }
    raise ActiveRecord::RecordNotFound unless @release_asset
    raise ActiveRecord::RecordNotFound unless @release_asset.viable?

    filename = [
      extension.namespace,
      extension.lowercase_name,
      version.version,
      @release_asset.platform,
      @release_asset.arch,
    ].join('-')

    json = render_to_string template: 'api/v1/release_assets/show.json.jbuilder'

    send_data json, filename: "#{filename}.json"
  end
end
