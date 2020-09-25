class SetupCompileGithubExtensionWorker < ApplicationWorker
  
  def perform(extension_id, compatible_platforms=[])

    extension = Extension.find(extension_id)

    CompileExtensionStatus.call(
      extension: extension,
      task: 'Extract Parent Extension',
    )
    parent_context = ExtractExtensionParent.call(extension: extension)
    sync_repo_context = SyncExtensionRepo.call(extension: extension, compatible_platforms: compatible_platforms)
  end

end