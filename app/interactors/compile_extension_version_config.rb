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
  SHA_REGEXP = /\A(\h{40,4096})\z/

  # The required context attributes:
  delegate :version, to: :context

  def call
    result_hash             = version.config.to_hash rescue {}
    src_builds              = Array.wrap(result_hash[BUILDS_KEY])
    extension               = version.extension
    releases_data           = extension.octokit
                                .releases(extension.github_repo)
                                .find { |h| h[:tag_name] == version.version }
    compiled_builds         = compile_build_hashes(src_builds, releases_data, version.version)
    result_hash[BUILDS_KEY] = compiled_builds
    context.data_hash       = result_hash
  end

  private

  def compile_build_hashes(build_hashes, releases_data, version_name)
    build_hashes.map { |build_hash|
      Thread.new { compile_build_hash(build_hash, releases_data, version_name) }
    }.map(&:value)
  end

  def compile_build_hash(build_hash, releases_data, version_name)
    build_hash = add_asset_url(build_hash, releases_data, version_name)
    build_hash = add_asset_sha(build_hash, releases_data, version_name)
    return build_hash
  end

  def add_asset_url(build_hash, releases_data, version_name)
    return build_hash unless releases_data.present?

    src_filename = build_hash['asset_filename']
    return build_hash unless src_filename.present?

    compiled_filename = interpolate_version_name(src_filename, version_name)
    asset_hash        = Array.wrap(releases_data[:assets]).find { |h| h[:name] == compiled_filename }
    return build_hash unless asset_hash.present?

    build_hash['asset_url'] = asset_hash[:browser_download_url]
    return build_hash
  end

  def add_asset_sha(build_hash, releases_data, version_name)
    return build_hash unless releases_data.present?

    src_sha_filename = build_hash['sha_filename']
    return build_hash unless src_sha_filename.present?

    compiled_sha_filename = interpolate_version_name(src_sha_filename, version_name)
    sha_asset_hash = Array.wrap(releases_data[:assets]).find {|h| h[:name] == compiled_sha_filename}
    return build_hash unless sha_asset_hash.present?

    sha_download_url = sha_asset_hash[:browser_download_url]
    return build_hash unless sha_download_url.present?

    resp = Faraday.new(sha_download_url) { |f|
      f.use     FaradayMiddleware::FollowRedirects
      f.adapter :net_http
    }.get
    return build_hash unless resp.success?

    sha_file_content = resp.body
    sha = sha_file_content
            .to_s
            .chomp
            .split(/\s+/)
            .first
    return build_hash unless sha.present?
    return build_hash unless sha =~ SHA_REGEXP

    build_hash['asset_sha'] = sha
    return build_hash
  end

  # Converts any instances of '#{version}' in the given string to the given version name.
  # E.g. the string 'test_asset-#{version}-linux-x86_64.tar.gz' and the version_name "10.3.4"
  # become 'test_asset-10.3.4-linux-x86_64.tar.gz'.
  def interpolate_version_name(str, version_name)
    ruby_formatted_str = str.gsub(/\#{/, '%{')
    ruby_formatted_str % {version: version_name}
  end
end
