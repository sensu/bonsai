# Compiles an +ExtensionVersion+'s raw configuration by interpolating strings and
# fetching GitHub asset information.
#
# See the example in ./compile_hosted_extension_version_config.rb.

class CompileGithubExtensionVersionConfig
  include Interactor

  delegate :extension,    to: :context
  delegate :version,      to: :context
  delegate :command_run,  to: :context
  delegate :config_hash,  to: :context

  def call
    context.command_run = CmdAtPath.new(extension.repo_path)

    fetch_bonsai_config

    if config_hash['builds'].present?
      version.update_column(:config, config_hash)
    else
      context.fail!(error: "Bonsai configuration has no 'builds' section")
    end

    context.config_hash['builds'] = compile_builds(config_hash['builds'])

  rescue => error
    raise if Interactor::Failure === error   # Don't trap context.fail! calls
    context.fail!(error: "Could not compile the Bonsai configuration file: #{error}")
  end

  private

  def fetch_bonsai_config
    name_switches = Extension::CONFIG_FILE_NAMES
                      .map {|name| "-name '#{name}'"}
                      .join(" -o ")
    find_command = "find . -maxdepth 1 #{name_switches}"
    path = command_run.cmd(find_command).split("\n").first

    unless path.present?
      context.fail!(error: 'Cannot find a Bonsai configuration file')
    end

    body = command_run.cmd("cat '#{path}'").encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''})

    begin
      context.config_hash = YAML.load(body.to_s)
    rescue => error
      context.fail!(error: "Cannot parse the Bonsai configuration file: #{error.message}")
    end

    context.fail!(error: "Bonsai configuration is invalid") unless config_hash.is_a?(Hash)
  end

  def compile_builds(build_configs)
    github_asset_data_hashes     = gather_github_release_asset_data_hashes

    github_asset_data_hashes_lut = Array.wrap(github_asset_data_hashes)
                                     .group_by { |h| h[:name] }
                                     .transform_values(&:first)

    Array.wrap(build_configs).each_with_index.map { |build_config, idx|
      compiled_config = compile_build_hash(build_config, idx + 1, github_asset_data_hashes_lut)
      build_config.merge compiled_config
    }
  end

  def gather_github_release_asset_data_hashes
    releases_data = version.octokit
      .releases(version.github_repo)
      .find { |h| h[:tag_name] == version.version }
      .to_h
    Array.wrap(releases_data[:assets])
  end

  def compile_build_hash(build_config, num, github_asset_data_hashes_lut)

    context.fail!(error: "Build ##{num} is malformed (perhaps missing indentation)") unless build_config.is_a?(Hash)

    src_sha_filename = build_config['sha_filename']
    context.fail!(error: "build ##{num} is missing a 'sha_filename' value") unless src_sha_filename.present?

    src_asset_filename = build_config['asset_filename']
    context.fail!(error: "Build ##{num} is missing an 'asset_filename' value") unless src_asset_filename.present?

    compiled_sha_filename = version.interpolate_variables(src_sha_filename)
    context.fail!(error: "Build ##{num} 'sha_filename' value could not be interpolated") unless compiled_sha_filename.present?

    compiled_asset_filename = version.interpolate_variables(src_asset_filename)
    context.fail!(error: "Build ##{num} 'asset_filename' value could not be interpolated") unless compiled_asset_filename.present?

    asset_filename    = File.basename(compiled_asset_filename)
    file_download_url = github_download_url(compiled_asset_filename, github_asset_data_hashes_lut)

    sha_result = read_sha_file(compiled_sha_filename, asset_filename, github_asset_data_hashes_lut)
    
    return {
      'viable'        => file_download_url.present?,
      'asset_url'     => file_download_url,
      'base_filename' => asset_filename,
      'asset_sha'     => sha_result.sha
    }
  end

  def read_sha_file(compiled_sha_filename, asset_filename, github_asset_data_hashes_lut)

    sha_download_url = github_download_url(compiled_sha_filename, github_asset_data_hashes_lut)

    result = FetchRemoteSha.call(
      sha_download_url: sha_download_url,
      asset_filename:   asset_filename
    )

    result.tap do |sha_result|
      context.fail!(error: "Cannot extract the SHA for #{asset_filename}") unless sha_result.sha.present?
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
    context.fail!(error: "Missing GitHub release asset for #{filename}")
  end
end