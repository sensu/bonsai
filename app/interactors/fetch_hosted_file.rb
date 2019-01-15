# Given a pathname to a content file, this service class will return the content of the target file.
class FetchHostedFile
  include Interactor

  # The required context attributes:
  delegate :blob,      to: :context
  delegate :file_path, to: :context

  def call
    cache_key = "FetchHostedFile: #{blob.id}/#{file_path}"
    context.content = self.class.cache.fetch(cache_key) do
      file = do_fetch(blob, file_path)
      file&.read
    end
  end

  private

  def self.cache
    Rails.env.test? ? Rails.cache : Rails.configuration.active_storage_cache
  end

  def do_fetch(blob, file_path)
    analyzer = ExtensionVersion.pick_blob_analyzer(blob)
    return nil unless analyzer

    analyzer.fetch_file(file_path: file_path)
  end
end
