# Call this service to force a compilation of the given extension.
# The compilation will be performed asynchronously.

class CompileExtension
  include Interactor

  # The required context attributes:
  delegate :extension, to: :context

  def call
      SyncExtensionRepoWorker.perform_async(extension.id)
  end
end
