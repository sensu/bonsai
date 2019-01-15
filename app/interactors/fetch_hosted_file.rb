# Given a pathname to a content file, this service class will return the content of the target file.
class FetchHostedFile
  include Interactor

  # The required context attributes:
  delegate :blob,      to: :context
  delegate :file_path, to: :context

  def call
    key = self.class.cache_key(blob: blob, file_path: file_path)
    context.content = self.class.cache.fetch(key) do
      file = do_fetch(blob, file_path)
      file&.read
    end
  end

  private

  def self.cache
    Rails.env.test? ? Rails.cache : Rails.configuration.active_storage_cache
  end

  def self.cache_key(blob:, file_path:)
    "FetchHostedFile: #{blob.id}/#{file_path}"
  end

  def do_fetch(blob, file_path)
    analyzer = ExtensionVersion.pick_blob_analyzer(blob)
    return nil unless analyzer

    analyzer.fetch_file(file_path: file_path)
  end
end
