class ReleaseAssetsController < ApplicationController
  def download
    extension      = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    version        = extension.extension_versions.find_by!(version: params[:version])
    @release_asset = version.release_assets.find { |ga| ga.platform == params[:platform] && ga.arch == params[:arch] }
    raise ActiveRecord::RecordNotFound unless @release_asset
    raise ActiveRecord::RecordNotFound unless @release_asset.viable?

    raise ActiveRecord::RecordNotFound if extension.hosted? && !params[:acknowledge]

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

  def asset_file
    send_file_content(:asset_filename)
  end

  def sha_file
    send_file_content(:sha_filename)
  end

  private

  def send_file_content(filename_method)
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    version   = extension.extension_versions.find_by!(version: params[:version])
    raise ActiveRecord::RecordNotFound unless version.source_file.attached?

    release_asset = version.release_assets.find { |ra| ra.platform == params[:platform] && ra.arch == params[:arch] }
    raise ActiveRecord::RecordNotFound unless release_asset

    file_path = version.interpolate_variables(release_asset.send(filename_method))

    result = FetchHostedFile.call(blob: version.source_file.blob, file_path: file_path)
    content = result.content
    raise ActiveRecord::RecordNotFound if content.nil?

    send_data content, filename: release_asset.base_filename
  end
end
