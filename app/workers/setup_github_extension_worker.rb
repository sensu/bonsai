class SetupGithubExtensionWorker < ApplicationWorker

# Sequence of Interactors
  # ExtractExtensionLicense
	# ExtractExtensionCollaborators,
	# ExtractExtensionStargazers,
	# SyncExtensionRepo
  ## SyncExtensionContentsAtVersions
  ### FetchReadmeAtVersion
  ### EnsureUpdatedVersion
  ### ScanVersionFiles 
  ### CompileGithubOverrides
  ### PersistAssets
  # SetupExtensionWebHooks,
  # NotifyModeratorsOfNewExtension

  def perform(extension_id, compatible_platforms = [])
  	extension = Extension.find(extension_id)

    # TODO: Extend error trapping to include failing interactor context.
    basic_metadata_context  = ExtractExtensionBasicMetadata.call(extension: extension)
    license_context         = ExtractExtensionLicense.call(extension: extension)
    collaborators_context   = ExtractExtensionCollaborators.call(extension: extension)
    stargazers_context      = ExtractExtensionStargazers.call(extension: extension)
    repo_context            = SyncExtensionRepo.call(extension: extension, compatible_platforms: compatible_platforms)
    webhook_context         = SetUpExtensionWebHooks.call(extension: extension)
    notify_context          = NotifyModeratorsOfNewExtension.call(extension: extension)

  end

end
