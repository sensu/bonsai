class NotifyModeratorsOfNewExtension
	include Interactor

	delegate :extension, to: :context

	def call
		User.moderator.each do |user|
      ExtensionMailer.delay.notify_moderator_of_new(extension.id, user.id)
    end
	end

end