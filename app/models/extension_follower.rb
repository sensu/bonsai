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

  class << self 

  	#
    # returns records for user
    #
    def includes_user(username)
      user_ids = Account.for_provider.with_username(username).pluck(:user_id)
      where(user_id: user_ids)
    end
    
  end # class << self
end
