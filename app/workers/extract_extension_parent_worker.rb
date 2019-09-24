class ExtractExtensionParentWorker < ApplicationWorker

  def perform(extension_id)
    @extension = Extension.find(extension_id)
    repo = octokit.repo(@extension.github_repo)

    repo_parent = repo[:parent]
    if repo_parent.present?
      parent_name = repo_parent[:name]
      parent_owner_name = repo_parent[:owner][:login]
      parent = Extension.with_owner_and_lowercase_name(owner_name: parent_owner_name, lowercase_name: parent_name)
      @extension.update_attributes(
        parent: parent, 
        parent_name: parent_name, 
        parent_owner_name: parent_owner_name
      )
    end
    
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end