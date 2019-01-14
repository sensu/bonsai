require 'active_support/concern'

module HasArchiveMetadata
  extend ActiveSupport::Concern

  def metadata
    {}.tap { |results|
      with_files do |finder|
        readme_file = finder.find(file_path: /\/readme/i)
        version     = blob.attachments.first&.record
        config      = version ?
                        CompileHostedExtensionVersionConfig.call(version: version, file_finder: finder).data_hash.to_h :
                        {}

        results[:readme]           = readme_file&.read.presence
        results[:readme_extension] = File.extname(readme_file&.path.to_s).to_s.sub(/\A\./, '').presence # strip off any leading '.'
        results[:config]           = config
      end
    }.compact
  end
end
