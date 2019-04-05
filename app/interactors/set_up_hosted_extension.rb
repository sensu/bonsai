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
      extension.tmp_source_file.detach

      attachment = extension_version.source_file.attachment
      if attachment.analyzed?
        extension_version.after_attachment_analysis(attachment, attachment.metadata)
      else
        #:nocov:
        attachment.analyze_later
        #:nocov:
      end
    end
  end

end
