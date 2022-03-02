# Given the URL of a remote SHA content file, and the name of a target asset file,
# this service class will look up (in the remote file) the SHA digest value corresponding
# to the target file.
class FetchRemoteSha
  include Interactor
  include ExtractsShas

  # The required context attributes:
  delegate :asset_filename,          to: :context
  delegate :sha_download_url,        to: :context
  delegate :sha_download_auth_token, to: :context

  def call
    sha_file_content = read_remote_file(sha_download_url, sha_download_auth_token)
    sha              = extract_sha_for_binary(asset_filename, sha_file_content)

    context.sha = sha
  end

  private

  def read_remote_file(url, auth_token)
    return nil unless url.present?

    faraday = Faraday.new { |f| 
      f.use FaradayMiddleware::FollowRedirects
      f.adapter :net_http
      f.basic_auth('x-oauth-basic', auth_token) if auth_token.present?
    }

    response = faraday.get(url)

    response.success? ? response.body : nil
  end
end
