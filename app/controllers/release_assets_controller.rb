class ReleaseAssetsController < ApplicationController

  include Annotations

  def download
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    version = extension.extension_versions.find_by!(version: params[:version])
    @release_asset = version.release_assets.find_by(platform: params[:platform], arch: params[:arch])

    if !@release_asset || !@release_asset.viable?
      raise ActiveRecord::RecordNotFound 
    end

    raise ActiveRecord::RecordNotFound if extension.hosted? && !params[:acknowledge]

    @release_asset.annotations.merge!( common_annotations(extension, version, @release_asset) )

    filename = [
      extension.namespace,
      extension.lowercase_name,
      version.version,
      @release_asset.platform,
      @release_asset.arch,
    ].join('-')

    json = render_to_string template: 'api/v1/release_assets/show.json.jbuilder'
    yaml = YAML.dump(JSON.parse(json))

    # uncomment to revert to json format
    # send_data json, filename: "#{filename}.json"
    send_data yaml, filename: "#{filename}.yml"
  end

  def asset_file
    send_file_content(:source_asset_filename)
  end

  def sha_file
    send_file_content(:source_sha_filename)
  end

  private

  def send_file_content(filename_method)
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    version   = extension.extension_versions.find_by!(version: params[:version])
    raise ActiveRecord::RecordNotFound unless version.source_file.attached?

    release_asset = version.release_assets.find_by(platform: params[:platform], arch: params[:arch])
    raise ActiveRecord::RecordNotFound unless release_asset

    file_path = version.interpolate_variables(release_asset.send(filename_method))

    result = FetchHostedFile.call(blob: version.source_file.blob, file_path: file_path)
    content = result.content
    raise ActiveRecord::RecordNotFound if content.nil?

    send_data content, filename: release_asset.source_base_filename
  end
end
