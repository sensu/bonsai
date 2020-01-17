# Call this service after creating a Sensu-hosted extension.
# This service sets up all of the version configure, etc
# for the new extension.

class SetUpHostedExtension
  include Interactor

  # The required context attributes:
  delegate :extension,    to: :context
  delegate :version_name, to: :context

  def call
    extension_version = extension.extension_versions.create!(version: version_name)

    if extension.tmp_source_file.attached?
      # Transfer the temporarily-staged attachment to the extension_version.
      extension_version.source_file.attach(extension.tmp_source_file.blob)
      

      # ActiveStorage blob checksum is a base64-encoded MD5 digest of the blob’s data
      # and is unique.  A new blob is created when a file is updated.
      last_commit_sha = extension_version.source_file.blob.checksum
      extension_version.update_columns(last_commit_sha:  last_commit_sha, last_commit_at: DateTime.now)

      extension.tmp_source_file.detach

      attachment = extension_version.source_file.attachment
      if attachment.analyzed?
        extension_version.after_attachment_analysis(attachment, attachment.metadata)
      else
        #:nocov:
        CompileExtensionStatus.call(
          extension: extension, 
          worker: 'ActiveStorageAnalyzeBlob', 
          job_id: attachment.analyze_later
        )
        
        #:nocov:
      end
    end
  end

end
