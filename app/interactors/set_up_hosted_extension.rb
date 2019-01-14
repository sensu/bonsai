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

      metadata = extension_version.source_file
      extension_version.update_attributes(
        readme:           metadata[:readme].to_s,
        readme_extension: metadata[:readme_extension].to_s,
        config:           metadata[:config].to_h,
      )
    end
  end
end
