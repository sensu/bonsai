class CreateCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :collections do |t|
    	t.references :user
    	t.integer :row_order
    	t.string :title
    	t.string :slug
    	t.text :description
      t.timestamps
    end
  end
end
