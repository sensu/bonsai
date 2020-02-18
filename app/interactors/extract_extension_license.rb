class ExtractExtensionLicense 
	include Interactor 

	delegate :extension, to: :context

	def call

		begin
			repo = extension.octokit.repo(extension.github_repo, accept: "application/vnd.github.drax-preview+json")

			if repo[:license]
				begin
					license = extension.octokit.license(repo[:license][:key], accept: "application/vnd.github.drax-preview+json")
				rescue
					license = {
	          name: repo[:license][:name],
	          body: ""
	        }
      	end
				extension.update_columns(
		      license_name: license[:name],
	        license_text: license[:body]
		    )
		  end

		rescue Octokit::NotFound
			context.fail!
		end

	end

end