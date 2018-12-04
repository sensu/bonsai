class SyncExtensionRepoWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms = [])
    @extension = Extension.find(extension_id)
    return if @extension.hosted?

    releases = @extension.octokit.releases(@extension.github_repo)

    clone_repo
    @tags = extract_tags_from_releases(releases)
    destroy_unreleased_versions

    release_infos_by_tag = releases.group_by {|release| release[:tag_name]}.transform_values {|arr| arr.first.to_h}
    SyncExtensionContentsAtVersionsWorker.perform_async(extension_id, @tags, compatible_platforms, release_infos_by_tag)
  end

  private

  def clone_repo
    `git clone #{@extension.github_url} #{@extension.repo_path}`
  end

  def extract_tags_from_releases(releases)
    tags = releases.map { |r| r[:tag_name] }
    ["master", *tags]
  end

  def destroy_unreleased_versions
    @extension.extension_versions.where.not(version: @tags).destroy_all
  end
end
