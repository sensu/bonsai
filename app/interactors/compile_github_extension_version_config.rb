# Compiles an +ExtensionVersion+'s raw configuration by interpolating strings and
# fetching GitHub asset information.
#
# See the example in ./compile_hosted_extension_version_config.rb.

require 'fetch_remote_sha'

class CompileGithubExtensionVersionConfig
  include Interactor

  # The required context attributes:
  delegate :version,               to: :context
  delegate :system_command_runner, to: :context

  def call
    config_hash = fetch_bonsai_config(system_command_runner)
    context.fail!(error: "Bonsai configuration has no 'builds' section") unless config_hash['builds'].present?

    config_hash['builds'] = compile_builds(version, config_hash['builds'])

    context.data_hash = config_hash
  rescue => boom
    raise if Interactor::Failure === boom   # Don't trap context.fail! calls
    context.fail!(error: "could not compile the Bonsai configuration file: #{boom}")
  end

  private

  def fetch_bonsai_config(cmd_runner)
    name_switches = Extension::CONFIG_FILE_NAMES
                      .map {|name| "-name '#{name}'"}
                      .join(" -o ")
    find_command = "find . -maxdepth 1 #{name_switches}"
    path = cmd_runner
             .cmd(find_command)
             .split("\n")
             .first
    context.fail!(error: 'cannot find a Bonsai configuration file') unless path.present?

    body = cmd_runner.cmd("cat '#{path}'")
    begin
      config_hash = YAML.load(body.to_s)
    rescue => boom
      context.fail!(error: "cannot parse the Bonsai configuration file: #{boom.message}")
    end

    context.fail!(error: "Bonsai configuration is invalid") unless config_hash.is_a?(Hash)
    config_hash
  end

  def compile_builds(version, build_configs)
    github_asset_data_hashes     = gather_github_release_asset_data_hashes(version)
    github_asset_data_hashes_lut = Array.wrap(github_asset_data_hashes)
                                     .group_by { |h| h[:name] }
                                     .transform_values(&:first)

    Array.wrap(build_configs).each_with_index.map { |build_config, idx|
      Thread.new do
        compiled_config = compile_build_hash(build_config, idx+1, github_asset_data_hashes_lut, version)
        build_config.merge compiled_config
      end
    }.map(&:value)
  end

  def gather_github_release_asset_data_hashes(version)
    releases_data = version.octokit
                      .releases(version.github_repo)
                      .find { |h| h[:tag_name] == version.version }
                      .to_h
    Array.wrap(releases_data[:assets])
  end

  def compile_build_hash(build_config, num, github_asset_data_hashes_lut, version)
    context.fail!(error: "build ##{num} is malformed (perhaps missing indentation)") unless build_config.is_a?(Hash)

    src_sha_filename = build_config['sha_filename']
    context.fail!(error: "build ##{num} is missing a 'sha_filename' value") unless src_sha_filename.present?

    src_asset_filename = build_config['asset_filename']
    context.fail!(error: "build ##{num} is missing an 'asset_filename' value") unless src_asset_filename.present?

    compiled_sha_filename = version.interpolate_variables(src_sha_filename)
    context.fail!(error: "build ##{num} 'sha_filename' value could not be interpolated") unless compiled_sha_filename.present?

    compiled_asset_filename = version.interpolate_variables(src_asset_filename)
    context.fail!(error: "build ##{num} 'asset_filename' value could not be interpolated") unless compiled_asset_filename.present?

    asset_filename    = File.basename(compiled_asset_filename)
    file_download_url = github_download_url(compiled_asset_filename, github_asset_data_hashes_lut)

    sha = read_sha_file(compiled_sha_filename, asset_filename, github_asset_data_hashes_lut)

    return {
      'viable'        => file_download_url.present?,
      'asset_url'     => file_download_url,
      'base_filename' => asset_filename,
      'asset_sha'     => sha
    }
  end

  def read_sha_file(compiled_sha_filename, asset_filename, github_asset_data_hashes_lut)

    sha_download_url = github_download_url(compiled_sha_filename, github_asset_data_hashes_lut)
    result           = FetchRemoteSha.call(
      sha_download_url: sha_download_url,
      asset_filename:   asset_filename
    )
    result.sha.tap do |sha_result|
      context.fail!(error: "cannot extract the SHA for #{asset_filename}") unless sha_result.present?
    end
  end

  def github_download_url(filename, github_asset_data_hashes_lut)
    # relying on the filename to equal the key in the github hash is failing
    # convert keys to an array of strings
    lut_array = github_asset_data_hashes_lut.keys
    # get the index of the filename
    data_index = lut_array.index(filename)
    # retreive the data based on the index
    unless data_index.nil?
      asset_data = github_asset_data_hashes_lut.values[data_index]
      unless asset_data.nil? || !asset_data.is_a?(Hash)
        return asset_data[:browser_download_url]
      end
    end
    context.fail!(error: "missing GitHub release asset for #{filename}")
    return ''
  end
end
