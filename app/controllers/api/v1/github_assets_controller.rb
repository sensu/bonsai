class Api::V1::GithubAssetsController < Api::V1Controller
  def show
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    version = extension.extension_versions.find_by!(version: params[:version])
    @github_asset = version.github_assets.find {|ga| ga.platform == params[:platform] && ga.arch == params[:arch]}
    raise ActiveRecord::RecordNotFound unless @github_asset
  end
end
