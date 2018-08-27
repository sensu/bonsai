class ExtensionVersionPlatform < ApplicationRecord
  # Associations
  # --------------------
  belongs_to :extension_version, required: false
  belongs_to :supported_platform, required: false

  # Validations
  # --------------------
  validates :extension_version, presence: true
  validates :supported_platform, presence: true
end
