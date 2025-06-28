class ExtractExtensionParentWorker < ApplicationWorker
  
  def perform(extension_id, current_user_id=nil)
    @current_user = User.find(current_user_id) if current_user_id.present?
    @extension = Extension.find(extension_id)

    repo = @current_user ? @current_user.octokit.repo(@extension.github_repo) : octokit.repo(@extension.github_repo)

    repo_parent = repo[:parent]
    if repo_parent.present?
      parent_name = repo_parent[:name]
      parent_owner_name = repo_parent[:owner][:login]
      parent_html_url = repo_parent[:html_url]

      @extension.update(
        parent_name: parent_name, 
        parent_owner_name: parent_owner_name,
        parent_html_url: parent_html_url
      )

      parent = Extension.find_by(owner_name: parent_owner_name, lowercase_name: parent_name)
      @extension.update(parent: parent) if parent.present?

    end
    
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end