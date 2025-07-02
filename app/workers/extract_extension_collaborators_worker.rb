class ExtractExtensionCollaboratorsWorker < ApplicationWorker
  
  def perform(extension_id, current_user_id=nil, page = 1, from_api = :contributors)
    @extension = Extension.find(extension_id)
    @current_user = User.find(current_user_id) if current_user_id.present?
    client = @current_user&.octokit || octokit()
    if from_api == :contributors
      @contributors = client.contributors(@extension.github_repo, nil, page: page)
    else
      @contributors = client.collaborators(@extension.github_repo, page: page)
    end

    if @contributors.any?
      process_contributors
      self.class.perform_async(extension_id, current_user_id, page + 1, from_api)
    elsif from_api == :contributors
      self.class.perform_async(extension_id, current_user_id, 1, :collaborators)
    end
  rescue
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end

  def process_contributors
    @contributors.each do |c|
      CompileExtensionStatus.call(
      extension: @extension, 
      worker: 'ExtractExtensionCollaboratorWorker', 
      job_id: ExtractExtensionCollaboratorWorker.perform_async(@extension.id, c[:login])
    )
    end
  end
end
