class ExtractExtensionStargazers
	include Interactor

	delegate :extension, to: :context 

	def call

		begin
			1.step do |page|
				stargazers = extension.octokit.stargazers(extension.github_repo, page: page, per_page: 100)
				break if stargazers.blank?
				process_stargazers(stargazers)
			end
		rescue Octokit::NotFound
			# context.fail!
		end

	end

	private

	def process_stargazers(stargazers)
		stargazers.each do |stargazer|
			begin 
				github_stargazer = extension.octokit.user(stargazer[:login])
				unless extension.extension_followers.includes_user(github_stargazer[:login]).present?
	    		ActiveRecord::Base.transaction do
			      context = EnsureGithubUserAndAccount.call(github_user: github_stargazer)
			      extension.extension_followers.create(user: context.account.user)
			    end
			  end

			rescue Octokit::NotFound
				# context.fail!
    	end
		end
	end

end