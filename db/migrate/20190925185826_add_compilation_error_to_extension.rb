class AddCompilationErrorToExtension < ActiveRecord::Migration[5.2]
  def change
  	add_column :extensions, :compilation_error, :string
  end
end
