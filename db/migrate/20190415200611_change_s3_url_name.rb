class ChangeS3UrlName < ActiveRecord::Migration[5.2]
  def change
  	rename_column :release_assets, :s3_url, :vanity_url
  	rename_column :release_assets, :s3_last_modified, :last_modified
  	add_column :release_assets, :filter, :text
  end
end
