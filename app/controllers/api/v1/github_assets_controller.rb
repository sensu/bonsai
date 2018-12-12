class Api::V1::GithubAssetsController < Api::V1Controller
  api! <<~EOD
    Retrieve #{I18n.t('indefinite_articles.extension')} #{I18n.t('nouns.extension')}'s build-specific details, suitable for consumption by the sensuctl tool.
  EOD
  param :username, String, required: true, desc: "Bonsai Asset Index user name of the asset owner"
  param :id,       String, required: true, desc: "Bonsai Asset Index asset name"
  param :version,  String, required: true, desc: "asset version"
  param :platform, String, required: true, desc: "target platform"
  param :arch,     String, required: true, desc: "target architecture"
  example "GET https://#{ENV['HOST']}/api/v1/extensions/demillir/sensu-asset-playground/v0.1-20181030/linux/aarch64/release_asset"
  example <<-EOX
    {
        "type": "Asset",
        "spec": {
            "name": "sensu-asset-playground",
            "url": "https://github.com/jspaleta/sensu-asset-playground/releases/download/v0.1-20181030/test_asset-v0.1-20181030-linux-aarch64.tar.gz",
            "sha512": "45be27148ac7dc2872cfbaef78db98f73a2e0743efdceadc93883d2b68f0f6f7ed4085f1520cc8472dc4f8299a0d0f88ffb30411aec97a33c115bf2b8ccefc04",
            "namespace": "demillir"
        }
    }
  EOX
  def show
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    version = extension.extension_versions.find_by!(version: params[:version])
    @github_asset = version.github_assets.find {|ga| ga.platform == params[:platform] && ga.arch == params[:arch]}
    raise ActiveRecord::RecordNotFound unless @github_asset
  end
end
