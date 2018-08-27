class ExtensionFollower < ApplicationRecord
  # Associations
  # --------------------
  belongs_to :extension, counter_cache: true, required: false
  belongs_to :user, required: false

  # Validations
  # --------------------
  validates :extension, presence: true
  validates :user, presence: true
  validates :extension_id, uniqueness: { scope: :user_id }
end
