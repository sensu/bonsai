#
# Lets those who follow and/or collaborate on an extension know when the extension
# has been deprecated.
#
class ExtensionDisabledNotifier < ApplicationWorker

  #
  # Queues an email to each follower and/or collaborator of the extension
  #
  # @param extension_id [Fixnum] Identifies a +Extension+
  #
  def perform(extension_id)
    extension = Extension.find_by(id: extension_id)
    return if extension.blank?
    users_to_email(extension).each do |user|
      ExtensionMailer.extension_disabled_email(extension, user).deliver
    end
  end

  private

  def users_to_email(extension)
    users_to_email = []
    disabled_extension = SystemEmail.find_by(name: 'Extension disabled')
    if disabled_extension.present?
      subscribed_user_ids = disabled_extension.subscribed_users.pluck(:id)
      users_to_email << extension.followers.where(id: subscribed_user_ids)
    end
    users_to_email << extension.owner
    users_to_email << extension.collaborator_users #.where(id: subscribed_user_ids)
    users_to_email.flatten.uniq
  end
end