# An ActiveStorage analyzer that extracts any README content from the .zip file.
# See the documentation for the base +ActiveStorage::Analyzer+ class.

require 'zip'

class ZipFileAnalyzer < ActiveStorage::Analyzer
  include ExtractsFiles

  MIME_TYPES = %w[
    application/zip
  ]

  def self.accept?(blob)
    MIME_TYPES.include? blob.content_type.to_s
  end

  def metadata
    content, extension = fetch_readme_from_blob

    {
      readme:           content,
      readme_extension: extension,
    }.compact
  end

  def fetch_file_content(file_path:)
    download_blob_to_tempfile do |file|
      Zip::File.open(file.path.to_s) do |files|
        extract_file(file_path: file_path, files: files, path_method: :name, file_reader: self.method(:zipped_file_reader))
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
      Zip::File.open(file.path.to_s) do |files|
        return extract_readme(files: files, path_method: :name, file_reader: self.method(:zipped_file_reader))
      end
    end
  rescue
    #:nocov:
    return [nil, nil]
    #:nocov:
  end

  def zipped_file_reader(files, file_path)
    entry = files.find_entry(file_path)
    entry.get_input_stream.read
  end
end
