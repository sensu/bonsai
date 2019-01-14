# Call this service after creating a Sensu-hosted extension.
# This service sets up all of the version configure, etc
# for the new extension.

class SetUpHostedExtension
  include Interactor

  # The required context attributes:
  delegate :extension,    to: :context
  delegate :version_name, to: :context

  def call
    owner_name = extension.owner.username
    extension.update_attributes(
      owner_name: owner_name
    )

    extension_version = extension.extension_versions.create!(version: version_name)

    if extension.tmp_source_file.attached?
      # Transfer the temporarily-staged attachment to the extension_version.
      extension_version.source_file.attach(extension.tmp_source_file.blob)
      extension.tmp_source_file.detach

      extension_version.with_files do |file_finder|
        compilation_result = CompileHostedExtensionVersionConfig.call(version: extension_version, file_finder: file_finder)
        if compilation_result.success?
          extension_version.update_column(:config, compilation_result.data_hash)
        end
      end
    end
  end
end
