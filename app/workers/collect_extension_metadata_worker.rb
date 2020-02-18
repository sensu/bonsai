class CollectExtensionMetadataWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms = [])
  	extension = Extension.find(extension_id)
    
    ExtractExtensionBasicMetadata.call(extension: extension)
    ExtractExtensionParent.call(extension: extension)
    ExtractExtensionLicense.call(extension: extension)
    ExtractExtensionCollaborators.call(extension: xtension)
    ExtractExtensionStargazers.call(extension: extension)
    SyncExtensionRepo.call(extension: extension, compatible_platforms: compatible_platforms)
  end
end
