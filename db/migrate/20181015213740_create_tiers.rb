class CreateTiers < ActiveRecord::Migration[5.2]
  def change
    create_table :tiers do |t|
      t.string :name
      t.integer :rank
      t.string :icon_name

      t.timestamps
    end
    add_index :tiers, :rank
  end
end
