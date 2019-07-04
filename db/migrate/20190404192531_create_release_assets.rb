class CreateReleaseAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :release_assets do |t|
    	t.references :extension_version
    	t.string :platform
    	t.string :arch
    	t.boolean :viable
    	t.string :commit_sha
    	t.datetime :commit_at
        t.string :github_asset_sha
        t.string :github_asset_url
        t.string :github_sha_filename
        t.string :github_base_filename
        t.string :github_asset_filename
        t.string :s3_url
    	t.timestamps
    end
    add_index :release_assets, :platform
    add_index :release_assets, :arch
    add_index :release_assets, :commit_sha
  end
end
