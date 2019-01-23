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
    config_hash           = fetch_bonsai_config(system_command_runner) || {}
    config_hash['builds'] = compile_builds(version, config_hash['builds'])

    context.data_hash = config_hash
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
    return nil unless path.present?

    body = cmd_runner.cmd("cat '#{path}'")
    config_hash = YAML.load(body.to_s) rescue {}

    return config_hash.is_a?(Hash) && config_hash
  end

  def compile_builds(version, build_configs)
    github_asset_data_hashes     = gather_github_release_asset_data_hashes(version)
    github_asset_data_hashes_lut = Array.wrap(github_asset_data_hashes)
                                     .group_by { |h| h[:name] }
                                     .transform_values(&:first)

    Array.wrap(build_configs).map { |build_config|
      Thread.new do
        compiled_config = compile_build_hash(build_config, github_asset_data_hashes_lut, version)
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

  def compile_build_hash(build_config, github_asset_data_hashes_lut, version)
    src_sha_filename   = build_config['sha_filename']
    src_asset_filename = build_config['asset_filename']

    compiled_sha_filename   = version.interpolate_variables(src_sha_filename)
    compiled_asset_filename = version.interpolate_variables(src_asset_filename)

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
    result.sha
  end

  def github_download_url(filename, github_asset_data_hashes_lut)
    asset_data = filename.present? && github_asset_data_hashes_lut.fetch(filename, {})
    asset_data.to_h[:browser_download_url]
  end
end
