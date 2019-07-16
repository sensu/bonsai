class ExtractExtensionCollaboratorWorker < ApplicationWorker

  def perform(extension_id, github_login)
    @extension = Extension.find(extension_id)
    @collaborator = octokit.user(github_login)

    unless @extension.collaborators.include?(@collaborator)
    	AddExtensionCollaborator.new(@extension, @collaborator).process!
    end
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
