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
    file      = fetch_readme_from_blob
    content   = file&.read
    extension = File.extname(file&.path.to_s).to_s.sub(/\A\./, '').presence # strip off any leading '.'

    {
      readme:           content.presence,
      readme_extension: extension,
    }.compact
  end

  def fetch_file_content(file_path:)
    download_blob_to_tempfile do |file|
      Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |files|
        file = find_file(file_path:   file_path,
                         files:       files,
                         path_method: :full_name,
                         file_reader: self.method(:tarred_file_reader))
        return file&.read
      end
    end
  rescue
    #:nocov:
    return nil
    #:nocov:
  end

  private

  def fetch_readme_from_blob
    download_blob_to_tempfile do |file|
      Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |files|
        return find_file(file_path:   /\/readme/i,
                         files:       files,
                         path_method: :full_name,
                         file_reader: self.method(:tarred_file_reader))
      end
    end
  rescue
    #:nocov:
    return nil
    #:nocov:
  end

  def tarred_file_reader(files, file_path)
    files.rewind
    files.seek(file_path) { |file| file.read }
  end
end
