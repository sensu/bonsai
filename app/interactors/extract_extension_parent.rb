class ExtractExtensionParent 
	include Interactor

	delegate :extension, to: :context 

	def call 
		repo = extension.octokit.repo(extension.github_repo)

    repo_parent = repo[:parent]

    # if parent exists on github
    if repo_parent.present?
      parent_name = repo_parent[:name]
      parent_owner_name = repo_parent[:owner][:login]
      parent_html_url = repo_parent[:html_url]

      extension.update(
        parent_name: parent_name, 
        parent_owner_name: parent_owner_name,
        parent_html_url: parent_html_url
      )

      # if parent exists on bonsai
      parent = Extension.find_by(owner_name: parent_owner_name, lowercase_name: parent_name)
      extension.update(parent: parent) if parent.present?

    end
    
	end

end