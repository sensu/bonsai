class SyncExtensionRepoWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms = [])
    @extension = Extension.find_by(id: extension_id)
    raise RuntimeError.new("#{I18n.t('nouns.extension')} ID: #{extension_id} not found.") unless @extension
    releases = @extension.octokit.releases(@extension.github_repo)

    @extension.with_lock do
      clone_repo
      @tags = extract_tags_from_releases(releases)
      destroy_unreleased_versions
    end

    release_infos_by_tag = releases.group_by {|release| release[:tag_name]}.transform_values {|arr| arr.first.to_h}
    SyncExtensionContentsAtVersionsWorker.perform_async(@extension.id, @tags, compatible_platforms, release_infos_by_tag)
  end

  private

  def clone_repo
    # Must clear any old repo as git will not clone to a non-empty directory
    FileUtils.rm_rf(Dir["#{@extension.repo_path}"])
    `git clone #{@extension.github_url} #{@extension.repo_path}`
  end

  def extract_tags_from_releases(releases)
    #tags = 
    releases.map { |r| r[:tag_name] }
    #["master", *tags]
  end

  def destroy_unreleased_versions
    @extension.extension_versions.where.not(version: @tags).destroy_all
  end
end
