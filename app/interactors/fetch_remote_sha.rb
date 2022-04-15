# Given the URL of a remote SHA content file, and the name of a target asset file,
# this service class will look up (in the remote file) the SHA digest value corresponding
# to the target file.
class FetchRemoteSha
  include Interactor
  include ExtractsShas
  include ReadsGithubFiles

  # The required context attributes:
  delegate :asset_filename,          to: :context
  delegate :sha_download_url,        to: :context
  delegate :sha_download_auth_token, to: :context

  def call
    sha_file_content = read_github_file(sha_download_url, sha_download_auth_token)
    sha              = extract_sha_for_binary(asset_filename, sha_file_content)

    context.sha = sha
  end
end
