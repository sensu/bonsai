class ExtensionCollection < ApplicationRecord

	belongs_to :extension
	belongs_to :collection
	belongs_to :user, optional: true
	
end
