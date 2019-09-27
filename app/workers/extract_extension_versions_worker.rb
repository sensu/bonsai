class ExtractExtensionVersionsWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms)
    @extension = Extension.find(extension_id)

    octokit.tags(@extension.github_repo).each do |tag|
      ExtractExtensionVersionWorker.perform_async(@extension.id, tag[:name], compatible_platforms)
    end
    # no longer create a version for master
    # ExtractExtensionVersionWorker.perform_async(@extension.id, "master", compatible_platforms)
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
