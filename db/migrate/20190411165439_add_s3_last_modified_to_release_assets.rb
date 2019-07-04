class AddS3LastModifiedToReleaseAssets < ActiveRecord::Migration[5.2]
  def change
  	add_column :release_assets, :s3_last_modified, :datetime
  end
end
