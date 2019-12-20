class AddParentHtmlUrlToExtension < ActiveRecord::Migration[5.2]
  def change
  	add_column :extensions, :parent_html_url, :string
  end
end
