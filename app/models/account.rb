class Account < ApplicationRecord
  # Associations
  # --------------------
  belongs_to :user

  # Validations
  # --------------------
  # validates :user, presence: true
  # validates :uid, presence: true
  validates :provider, presence: true
  validates :oauth_token, presence: true
  validate :unique_username_and_provider, on: :create

  # Scope
  # --------------------
  scope :for, ->(id) { where(provider: id) }
  scope :for_provider, ->{ where(provider: ENV['OAUTH_ACCOUNT_PROVIDER']) }
  scope :with_username, ->(username) { where(username: username) }

  def revoke_application_authorization
    user.octokit.revoke_application_authorization(oauth_token)
  end

  private

  #
  # If an account already exists with the same username and provider
  # then add a helpful error message to the records base errors.
  #
  def unique_username_and_provider
    if Account.exists?(provider: provider, username: username)
      errors.add(:base,
                 I18n.t(
                   'account.already_connected',
                   provider: provider.titleize,
                   username: username
                 ))
    end
  end
end
