class CollectExtensionMetadataWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms = [], current_user_id=nil)
  	extension = Extension.find(extension_id)
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'ExtractExtensionBasicMetadataWorker',
      job_id: ExtractExtensionBasicMetadataWorker.perform_async(extension.id)
    )
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'ExtractExtensionParentWorker',
      job_id: ExtractExtensionParentWorker.perform_async(extension.id)
    )
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'ExtractExtensionLicenseWorker',
      job_id: ExtractExtensionLicenseWorker.perform_async(extension.id)
    )
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'ExtractExtensionCollaboratorsWorker',
      job_id: ExtractExtensionCollaboratorsWorker.perform_async(extension.id)
    )
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'ExtractExtensionStargazersWorker',
      job_id: ExtractExtensionStargazersWorker.perform_async(extension.id)
    )
    CompileExtensionStatus.call(
      extension: extension,
      worker: 'SyncExtensionRepoWorker',
      job_id: SyncExtensionRepoWorker.perform_async(extension.id, compatible_platforms, current_user_id)
    )
  end
end
