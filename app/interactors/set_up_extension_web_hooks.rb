class SetUpExtensionWebHooks
	include Interactor

	delegate :extension, to: :context

	def call
		begin
      extension.octokit.create_hook(
        extension.github_repo, 
        "web",
        {
          url: Rails.application.routes.url_helpers.webhook_extension_url(extension, username: extension.owner_name),
          content_type: "json"
        },
        {
          events: ["release", "watch", "member"],
          active: true
        }
      )
    rescue Octokit::UnprocessableEntity
      # Do nothing and continue if the hook already exists
    end

	end

end