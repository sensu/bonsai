# An ActiveStorage analyzer that extracts any README content from gzipped tar file.
# See the documentation for the base +ActiveStorage::Analyzer+ class.

require 'rubygems/package'
require 'zlib'


class TarBallAnalyzer < ActiveStorage::Analyzer
  include ExtractsFiles

  MIME_TYPES = %w[
    application/gzip
    application/x-compressed-tar
  ]

  def self.accept?(blob)
    MIME_TYPES.include? blob.content_type.to_s
  end

  def metadata
    {}.tap { |results|
      with_files do |finder|
        readme_file                = finder.find(file_path: /\/readme/i)
        results[:readme]           = readme_file&.read.presence
        results[:readme_extension] = File.extname(readme_file&.path.to_s).to_s.sub(/\A\./, '').presence # strip off any leading '.'
      end
    }.compact
  end

  def fetch_file(file_path:)
    with_files do |finder|
      finder.find(file_path: file_path)
    end
  end

  def with_files(&block)
    download_blob_to_tempfile do |file|
      Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |files|
        finder = FileFinder.new(files:       files,
                                path_method: :full_name,
                                reader:      self.method(:tarred_file_reader))
        return yield(finder)
      end
    end
  rescue
    #:nocov:
    return nil
    #:nocov:
  end

  private

  def tarred_file_reader(files, file_path)
    files.rewind
    files.seek(file_path) { |file| file.read }
  end
end
