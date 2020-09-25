class ExtractExtensionCollaborators
	include Interactor

	delegate :extension, to: :context 

	def call

		begin
			1.step do |page|
				contributors = extension.octokit.contributors(extension.github_repo, nil, page: page)
				break if contributors.blank?
				process_contributors(contributors)
			end
		rescue Octokit::NotFound
			# context.fail!
		end

		begin
			1.step do |page|
				collaborators = extension.octokit.collaborators(extension.github_repo, page: page)
				break if collaborators.blank?
				process_contributors(collaborators)
			end
		rescue Octokit::NotFound
			# context.fail!
		end

	end

	private

	def process_contributors(contributors)
		contributors.each do |contributor|
			begin 
				collaborator = extension.octokit.user(contributor[:login])
				unless extension.collaborators.includes_user(collaborator[:login]).present?
	    		ActiveRecord::Base.transaction do
			   		context = EnsureGithubUserAndAccount.call(github_user: collaborator)
			      Collaborator.create(user: context.account.user, resourceable: extension)
			    end
			  end

			rescue Octokit::NotFound
				# context.fail!
    	end
		end
	end

end