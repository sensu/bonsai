class ExtractExtensionBasicMetadata  
	include Interactor 

	delegate :extension, to: :context

	def call
		begin
			repo = extension.octokit.repo(extension.github_repo)
			extension.update_columns(
	      name: repo[:full_name],
	      issues_url: "https://github.com/#{extension.github_repo}/issues"
	    )
		rescue Octokit::NotFound
			context.fail!
		end
	end

end