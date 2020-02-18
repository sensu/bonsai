# Call this service to force a compilation of the given extension.
# The compilation will be performed asynchronously.
# This service works with GitHub-based extensions and hosted extensions.

class CompileExtension
  include Interactor

  delegate :extension, to: :context

  def call

    extension.update_column(:compilation_error, '')
    
    CompileExtensionStatusClear.call(extension: extension)

    if extension.hosted?
      CompileExtensionStatus.call(
        extension: extension,
        task: 'Set Up Hosted Extension Compilation',
        worker: 'SetupCompileHostedExtension',
        job_id: SetupCompileHostedExtensionWorker.perform_async(extension.id)
      )
    else
      CompileExtensionStatus.call(
        extension: extension,
        task: 'Set Up Github Extension Compilation',
        worker: 'SetupCompileGithubExtension',
        job_id: SetupCompileGithubExtensionWorker.perform_async(extension.id)
      )
    end
  end

end
