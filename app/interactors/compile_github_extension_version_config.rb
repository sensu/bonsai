# Compiles an +ExtensionVersion+'s raw configuration by interpolating strings and
# fetching GitHub asset information.
#
# For example, if the raw source configuration looks like:
#
#   {"description" => "Test Asset",
#    "builds"      =>
#      [{"arch"           => "x86_64",
#        "filter"         =>
#          ["System.OS == linux",
#           "(System.Arch == x86_64) || (System.Arch == amd64)"],
#        "platform"       => "linux",
#        "sha_filename"   => "test_asset-\#{version}-linux-x86_64.sha512.txt",
#        "asset_filename" => "test_asset-\#{version}-linux-x86_64.tar.gz"}]}
#
# The compiled configuration might look like:
#
#   {"description"=>"Test Asset",
#    "builds"=>
#      [{"arch"=>"x86_64",
#        "filter"=>
#          ["System.OS == linux",
#           "(System.Arch == x86_64) || (System.Arch == amd64)"],
#        "platform"=>"linux",
#        "sha_filename"=>"test_asset-\#{version}-linux-x86_64.sha512.txt",
#        "asset_filename"=>"test_asset-\#{version}-linux-x86_64.tar.gz",
#        "asset_url"=>
#          "https://github.com/some-user/some-repo/releases/download/v0.1-20181115/test_asset-v0.1-20181115-linux-x86_64.tar.gz",
#        "asset_sha"=>
#          "6f2121a6c8690f229e9cb962d8d71f60851684284755d4cdba4e77ef7ba20c03283795c4fccb9d6ac8308b248f2538bf7497d6467de0cf9e9f0814625b4c6f91"}]}
#
# The compilation is lossless because none of the source configuration is changed,
# only new configuration items are added.  Therefore, the compilation is idempotent
# and can be re-run multiple times.

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

    file_download_url = github_download_url(compiled_asset_filename, github_asset_data_hashes_lut)
    sha_download_url  = github_download_url(compiled_sha_filename, github_asset_data_hashes_lut)

    result = FetchRemoteSha.call(
      sha_download_url: sha_download_url,
      asset_filename:   File.basename(compiled_asset_filename)
    )

    return {
      'viable'        => file_download_url.present?,
      'asset_url'     => file_download_url,
      'base_filename' => File.basename(compiled_asset_filename),
      'asset_sha'     => result.sha
    }
  end

  def github_download_url(filename, github_asset_data_hashes_lut)
    asset_data = filename.present? && github_asset_data_hashes_lut.fetch(filename, {})
    asset_data[:browser_download_url]
  end
end
