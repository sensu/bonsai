# Compiles an +ExtensionVersion+'s raw configuration by interpolating strings and
# fetching build asset information.
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

class CompileHostedExtensionVersionConfig
  include Interactor
  include ExtractsShas

  # The required context attributes:
  delegate :version, to: :context

  def call
    version.with_files do |file_finder|
      config_hash           = fetch_bonsai_config(file_finder) || {}
      config_hash['builds'] = compile_builds(version, config_hash['builds'], file_finder)

      context.data_hash = config_hash
    end
  end

  private

  def fetch_bonsai_config(file_finder)
    files_regexp = "(#{Extension::CONFIG_FILE_NAMES.join('|')})"
    file         = file_finder.find(file_path: files_regexp)
    body         = file&.read
    config_hash = YAML.load(body.to_s) rescue {}

    return config_hash.is_a?(Hash) && config_hash
  end

  def compile_builds(version, build_configs, file_finder)
    Array.wrap(build_configs).map do |build_config|
      compiled_config = compile_build_hash(build_config, version, file_finder)
      build_config.merge compiled_config
    end
  end

  def compile_build_hash(build_config, version, file_finder)
    src_sha_filename   = build_config['sha_filename']
    src_asset_filename = build_config['asset_filename']

    compiled_sha_filename   = version.interpolate_variables(src_sha_filename)
    compiled_asset_filename = version.interpolate_variables(src_asset_filename)

    asset_filename    = File.basename(compiled_asset_filename)
    file_download_url = hosted_download_url(build_config, version)

    sha = read_sha_file(compiled_sha_filename, asset_filename, file_finder)

    return {
      'viable'        => file_download_url.present?,
      'asset_url'     => file_download_url,
      'base_filename' => asset_filename,
      'asset_sha'     => sha
    }
  end

  def read_sha_file(sha_filename, asset_filename, file_finder)
    file             = file_finder.find(file_path: sha_filename)
    sha_file_content = file&.read
    extract_sha_for_binary(asset_filename, sha_file_content)
  end

  def hosted_download_url(build_config, version)
    extension = version.extension
    platform  = build_config['platform']
    arch      = build_config['arch']

    # Eat our own dog food
    file_download_url = Rails.application.routes.url_helpers.release_asset_asset_file_url(
      extension,
      version,
      username: extension.owner_name,
      platform: platform,
      arch:     arch)
    return file_download_url
  end
end
