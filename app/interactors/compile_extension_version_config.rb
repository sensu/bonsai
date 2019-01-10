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
class CompileExtensionVersionConfig
  include Interactor

  BUILDS_KEY = 'builds'

  # The required context attributes:
  delegate :version, to: :context

  def call
    config_hash             = version.config.to_hash rescue {}
    src_builds              = Array.wrap(config_hash[BUILDS_KEY])
    config_hash[BUILDS_KEY] = compile_builds(version, src_builds)

    context.data_hash = config_hash
  end

  private

  def compile_builds(version, src_builds)
    asset_hashes = gather_github_release_asset_hashes(version)

    return compile_build_hashes(src_builds, asset_hashes, version)
  end

  def gather_github_release_asset_hashes(version)
    releases_data = version.octokit
                      .releases(version.github_repo)
                      .find { |h| h[:tag_name] == version.version }
                      .to_h
    Array.wrap(releases_data[:assets])
  end

  def compile_build_hashes(build_configs, asset_hashes, version)
    asset_hashes_lut = asset_hashes
                         .group_by { |h| h[:name] }
                         .transform_values(&:first)

    build_configs.map { |build_config|
      Thread.new do
        compiled_config = compile_build_hash(build_config, asset_hashes_lut, version)
        build_config.merge compiled_config
      end
    }.map(&:value)
  end

  def compile_build_hash(build_config, asset_hashes_lut, version)
    src_sha_filename   = build_config['sha_filename']
    src_asset_filename = build_config['asset_filename']

    compiled_sha_filename   = interpolate_variables(src_sha_filename, version)
    compiled_asset_filename = interpolate_variables(src_asset_filename, version)

    file_asset_hash = compiled_asset_filename.present? && asset_hashes_lut.fetch(compiled_asset_filename, {})
    sha_asset_hash  = compiled_sha_filename.present?   && asset_hashes_lut.fetch(compiled_sha_filename,   {})

    file_download_url = file_asset_hash[:browser_download_url]
    sha_download_url  = sha_asset_hash[ :browser_download_url]

    result = FetchRemoteSha.call(
      sha_download_url: sha_download_url,
      sha_filename:     compiled_sha_filename,
      asset_filename:   compiled_asset_filename
    )

    return {
      'viable'    => file_download_url.present?,
      'asset_url' => file_download_url,
      'asset_sha' => result.sha
    }
  end

  # Converts any instances of '#{var-name}' in the given string to the corresponding value from
  # the given version object.
  # E.g. the string 'test_asset-#{version}-linux-x86_64.tar.gz' and a version with the name "10.3.4"
  # become 'test_asset-10.3.4-linux-x86_64.tar.gz'.
  def interpolate_variables(str, version)
    ruby_formatted_str = str.to_s.gsub(/\#{/, '%{')

    interpolations = {
      repo:    version.extension_lowercase_name,
      version: version.version,
    }
    interpolated_str = ruby_formatted_str % interpolations

    return interpolated_str.presence
  end
end
