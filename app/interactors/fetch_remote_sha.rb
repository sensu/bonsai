# Given the URL of a remote SHA content file, and the name of a target asset file,
# this service class will look up (in the remote file) the SHA digest value corresponding
# to the target file.
class FetchRemoteSha
  include Interactor
  include ExtractsShas

  # The required context attributes:
  delegate :asset_filename,   to: :context
  delegate :sha_download_url, to: :context

  def call
    sha_file_content = read_remote_file(sha_download_url)
    sha              = extract_sha_for_binary(asset_filename, sha_file_content)

    context.sha = sha
  end

  private

  def read_remote_file(url)
    return nil unless url.present?

    resp = Faraday.new(url) { |f|
      f.use     FaradayMiddleware::FollowRedirects
      f.adapter :net_http
    }.get

    resp.success? ? resp.body : nil
  end
end
