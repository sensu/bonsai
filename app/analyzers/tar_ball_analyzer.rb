# An ActiveStorage analyzer that extracts any README content from gzipped tar file.
# See the documentation for the base +ActiveStorage::Analyzer+ class.

require 'rubygems/package'
require 'zlib'


class TarBallAnalyzer < ActiveStorage::Analyzer
  include HasArchiveMetadata
  include ExtractsFiles

  MIME_TYPES = %w[
    application/gzip
    application/x-gzip
    application/x-gzip-compressed
    application/x-compressed
    application/x-compressed-tar
    application/gzip-compressed
    application/gzipped
    application/x-gunzip
    gzip/document
  ]

  def self.accept?(blob)
    MIME_TYPES.include? blob.content_type.to_s
  end

  def with_file_finder(&block)
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
    files.seek(file_path) { |file| 
      file.read.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
    }
  end
end
