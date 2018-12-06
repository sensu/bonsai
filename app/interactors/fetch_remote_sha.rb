# Given the URL of a remote SHA content file, and the name of a target asset file,
# this service class will look up (in the remote file) the SHA digest value corresponding
# to the target file.
class FetchRemoteSha
  include Interactor

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

  # Support two formats of file content:
  # 1. A one-line file containing a single SHA digest, e.g.
  #      06c6c2926c7179993b7099a04780ab172ce4b8205c9e045be149bc538e0898adf72aade60ce7a3a132fcee1a37786cff6695de0c128eb60609b5d219e8fc4840
  #
  # 2. A file containing multiple SHA digests, each on its own line, with the name of the digested file following the SHA digest, e.g.
  #      b05fca0917280ac4e8378cae6e45175601e1ebb4a8a15e85d816a63cf2e6b816fd8d1b0b7ffff3994b4b931037ff56dac3936095953906fe4fe7c938eec3ea66  ./sensu-slack-handler_0.1.4_freebsd_amd64.tar.gz
  #      3293fe0bffcf1f8460a06c05459981cd672a7f5a50be9041b0c9f4213ec7d79b640698a4089e2cc11cec4c5aaaa3f42804903d1b9b7d8bc49d2ebcfec2ac2770  ./sensu-slack-handler_0.1.4_linux_386.tar.gz
  #      31d9bcc2bfee0e98bf49c16a91f6193108d155eb84810021c720cbcebc66c865cb1554a3dcc1f3732adb0023fb6c542d4d838b6f1ee7b085a72998b32b00c082  ./sensu-slack-handler_0.1.4_linux_amd64.tar.gz
  #
  # For good measure, ignore any line beginning with a non-hexadecimal character.
  def extract_sha_for_binary(asset_filename, sha_file_content)
    lines_of_interest = sha_file_content
                          .to_s
                          .split("\n")
                          .map(&:squish)
                          .grep /\A\h/

    matching_line = if lines_of_interest.many?
                      # Multiple SHA scenario
                      asset_filename.presence &&
                        lines_of_interest.find { |line|
                          extract_filename_from_line(line) == asset_filename
                        }
                    else
                      # Single SHA scenario (or no SHA!)
                      lines_of_interest.first
                    end

    # The SHA is the first word in the first line.  If there was no matching line, return nil.
    return matching_line
             .to_s
             .split(/\s/)
             .first
  end

  def extract_filename_from_line(line)
    # The filename will be in the second word, if there is a second word.
    second_word = line
                    .to_s
                    .split(/\s+/)
                    .second

    # Return nil if the given line has no filename in the second word.
    return File.basename(second_word.to_s).presence
  end
end
