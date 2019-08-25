class Api::V1::ReleaseAssetsController < Api::V1Controller

  include Annotations

  api! <<~EOD
    Retrieve #{I18n.t('indefinite_articles.extension')} #{I18n.t('nouns.extension')}'s multi-build details, suitable for consumption by the sensu tool.
  EOD
  param :username, String, required: true, desc: "Bonsai Asset Index user name of the asset owner"
  param :id,       String, required: true, desc: "Bonsai Asset Index asset name"
  param :version,  String, required: true, desc: "asset version"
  example "GET https://#{ENV['HOST']}/api/v1/assets/sensu/sensu-email-handler/0.2.0/release_asset_builds"
  def index
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    @version = extension.extension_versions.find_by!(version: params[:version])
    @annotations = common_annotations(extension, @version)
  end
  
  api! <<~EOD
    Retrieve #{I18n.t('indefinite_articles.extension')} #{I18n.t('nouns.extension')}'s build-specific details, suitable for consumption by the sensu tool.
  EOD
  param :username, String, required: true, desc: "Bonsai Asset Index user name of the asset owner"
  param :id,       String, required: true, desc: "Bonsai Asset Index asset name"
  param :version,  String, required: true, desc: "asset version"
  param :platform, String, required: true, desc: "target platform"
  param :arch,     String, required: true, desc: "target architecture"
  example "GET https://#{ENV['HOST']}/api/v1/assets/demillir/sensu-asset-playground/0.1.1-20181030/linux/aarch64/release_asset"
  
  def show
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    version = extension.extension_versions.find_by!(version: params[:version])
    @release_asset = version.release_assets.find_by(platform: params[:platform], arch: params[:arch])
    raise ActiveRecord::RecordNotFound unless @release_asset
    @annotations = common_annotations(extension, version, @release_asset)
  end

end
