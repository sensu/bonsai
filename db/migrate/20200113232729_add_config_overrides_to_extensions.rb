class AddConfigOverridesToExtensions < ActiveRecord::Migration[5.2]
  def change
  	add_column :extensions, :config_overrides, :text
  end
end
