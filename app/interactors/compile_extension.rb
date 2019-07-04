# Call this service to force a compilation of the given extension.
# The compilation will be performed asynchronously.
# This service works with GitHub-based extensions and hosted extensions.

class CompileExtension
  include Interactor

  # The required context attributes:
  delegate :extension, to: :context

  def call
    if extension.hosted?
      compile_hosted_extension(extension)
    else
      SyncExtensionRepoWorker.perform_async(extension.id)
    end
  end

  private

  def compile_hosted_extension(extension)
    extension.extension_versions.each do |version|
      next unless version.source_file.attached?
      version.source_file.blob.analyze_later
    end
  end
end
