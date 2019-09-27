class ExtensionMailer < ApplicationMailer
  add_template_helper(ExtensionVersionsHelper)

  #
  # Creates an email to a user that is an extension follower
  # that notifies them a new extension version has been published
  #
  # @param extension_version [ExtensionVersion] the extension version that was
  # published
  # @param user [User] the user to notify
  #
  def follower_notification_email(extension_version, user)
    @extension_version = extension_version
    @email_preference = user.email_preference_for('New extension version')
    @to = user.email

    mail(to: @to, subject: "A new version of #{@extension_version.owner_name}: #{@extension_version.name} #{I18n.t('nouns.extension')} has been released") unless @to.blank?
  end

  #
  # Create notification email to an extension's collaborators and followers
  # explaining that the extension has been deleted
  #
  # @param name [String] the name of the extension
  # @param user [User] the user to notify
  #
  def extension_deleted_email(extension, user)
    @extension = extension
    @email_preference = user.email_preference_for('Extension deleted')
    @to = user.email

    mail(to: @to, subject: "#{@extension.owner_name}/#{@extension.name} #{I18n.t('nouns.extension')} has been deleted") unless @to.blank?
  end

#
  # Create notification email to an extension's owner, collaborators and followers
  # explaining that the extension has been disabled
  #
  # @param extension [String] the name of the extension
  # @param user [User] the user to notify
  #
  def extension_disabled_email(extension, user)
    @extension = extension
    @email_preference = user.email_preference_for('Extension disabled')
    @to = user.email

    mail(to: @to, subject: "The #{@extension.owner_name}/#{@extension.name} #{I18n.t('nouns.extension')} has been disabled") unless @to.blank?
  end

  #
  # Sends notification email to an extension's collaborators and followers
  # explaining that the extension has been deprecated in favor of another
  # extension
  #
  # @param extension [Extension] the extension
  # @param replacement_extension [Extension] the replacement extension
  # @param user [User] the user to notify
  #
  def extension_deprecated_email(extension, replacement_extension, user)
    @extension = extension
    @replacement_extension = replacement_extension
    @email_preference = user.email_preference_for('Extension deprecated')
    @to = user.email

    subject = %(
      #{@extension.owner_name}/#{@extension.name} #{I18n.t('nouns.extension')} has been deprecated in favor
      of #{@replacement_extension.owner_name}/#{@replacement_extension.name} #{I18n.t('nouns.extension')}
    ).squish

    mail(to: @to, subject: subject) unless @to.blank?
  end

  #
  # Sends email to the recipient of an OwnershipTransferRequest, asking if they
  # want to become the new owner of an Extension. This is generated when
  # an Extension owner initiates a transfer of ownership to someone that's not
  # currently a Collaborator on the Extension.
  #
  # @param transfer_request [OwnershipTransferRequest]
  #
  def transfer_ownership_email(transfer_request)
    @transfer_request = transfer_request
    @sender = transfer_request.sender.name
    @extension = transfer_request.extension

    subject = %(
      #{@sender} wants to transfer ownership of the #{@extension.owner_name}/#{@extension.name} #{I18n.t('nouns.extension')} to
      you.
    ).squish

    mail(to: transfer_request.recipient.email, subject: subject)
  end

  #
  # Sends an email to the given moderator notifying them that an extension has
  # just been added.
  #
  # @param extension_id (Fixnum)
  # @param user_id (Fixnum)
  #
  def notify_moderator_of_new(extension_id, user_id)
    @extension = Extension.find(extension_id)
    @moderator = User.find(user_id)

    @subject = %(A New #{I18n.t('nouns.extension')} "#{@extension.owner_name}/#{@extension.name}" has been added to the Bonsai Asset Index)

    mail(to: @moderator.email, subject: @subject) unless @moderator.email.blank?
  end

  #
  # Sends an email to the given moderator notifying them that an extension has
  # just been reported.
  #
  # @param extension_id (Fixnum)
  # @param user_id (Fixnum)
  #
  def notify_moderator_of_reported(extension_id, user_id, report_description, reported_by_id)
    @extension = Extension.find(extension_id)
    @moderator = User.find(user_id)
    @description = report_description
    @reported_by = User.where(id: reported_by_id).first

    @subject = %(#{I18n.t('nouns.extension').capitalize} "#{@extension.owner_name}/#{@extension.name}" reported)

    mail(to: @moderator.email, subject: @subject) unless @moderator.email.blank?
  end
end
