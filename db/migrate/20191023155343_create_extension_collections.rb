class CreateExtensionCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :extension_collections do |t|
    	t.references :extension 
    	t.references :collection
    	t.references :user
      t.timestamps
    end
  end
end
