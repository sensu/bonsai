class ExtensionDependency < ApplicationRecord
  include SeriousErrors

  # Associations
  # --------------------
  belongs_to :extension_version, required: false
  belongs_to :extension, required: false

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: { scope: [:version_constraint, :extension_version_id] }
  validates :extension_version, presence: true
end
