class RenameGithubColumns < ActiveRecord::Migration[5.2]
  def change
  	rename_column :release_assets, :github_asset_sha, :source_asset_sha
  	rename_column :release_assets, :github_asset_url, :source_asset_url
  	rename_column :release_assets, :github_sha_filename, :source_sha_filename
  	rename_column :release_assets, :github_base_filename, :source_base_filename
  	rename_column :release_assets, :github_asset_filename, :source_asset_filename
  	add_column :release_assets, :annotations, :text
  end
end
