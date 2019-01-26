require 'active_support/concern'

module HasArchiveMetadata
  extend ActiveSupport::Concern

  def metadata
    {}.tap { |results|
      with_file_finder do |finder|
        readme_file = finder.find(file_path: /(\A|\/)readme/i)
        results[:readme]           = readme_file&.read.presence
        results[:readme_extension] = File.extname(readme_file&.path.to_s).to_s.sub(/\A\./, '').presence # strip off any leading '.'

        version = blob.attachments
                    .map(&:record)
                    .find { |record| record.is_a?(ExtensionVersion) }
        if version
          compilation_result = CompileHostedExtensionVersionConfig.call(
            version:     version,
            file_finder: finder)
          if compilation_result.success?
            results[:config] = compilation_result.data_hash
          else
            results[:compilation_error] = compilation_result.error
          end
        end
      end
    }.compact.tap {|results|
      blob.attachments.each do |attachment|
        record = attachment.record
        if record.respond_to?(:after_attachment_analysis)
          record.after_attachment_analysis(attachment, results)
        end
      end
    }
  end
end
