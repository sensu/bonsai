# Call this service to force a compilation of the given extension.
# The compilation will be performed asynchronously.
# This service works with GitHub-based extensions and hosted extensions.

class CompileExtension
  include Interactor

  delegate :extension, to: :context

  def call

    extension.update_column(:compilation_error, '')

    # test credentials before going to background job
    begin
      extension.octokit.user
    rescue Octokit::Unauthorized 
      message = "Octokit Error: Credentials are bad on this asset."
      extension.update_column(:compilation_error, message)
      context.fail!(error: message)
    end  

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
