# Given a pathname to a content file, this service class will return the content of the target file.
class FetchHostedFile
  include Interactor

  # The required context attributes:
  delegate :blob,      to: :context
  delegate :file_path, to: :context

  def call
    context.content = do_fetch(blob, file_path)
  end

  private

  def do_fetch(blob, file_path)
    case
    when TarBallAnalyzer.accept?(blob)
      TarBallAnalyzer.new(blob).fetch_file_content(file_path: file_path)
    when ZipFileAnalyzer.accept?(blob)
      ZipFileAnalyzer.new(blob).fetch_file_content(file_path: file_path)
    else
      nil
    end
  end
end
