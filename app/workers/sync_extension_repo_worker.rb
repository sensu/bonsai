class SyncExtensionRepoWorker < ApplicationWorker

  def perform(extension_id, compatible_platforms = [], current_user_id=nil)
    @extension = Extension.find_by(id: extension_id)
    current_user = User.find_by(id: current_user_id)
    raise RuntimeError.new("#{I18n.t('nouns.extension')} ID: #{extension_id} not found.") unless @extension

    octokit = current_user&.octokit || @extension.octokit
    releases = octokit.releases(@extension.github_repo)

    @extension.with_lock do
      clone_repo(current_user)
      @tags = extract_tags_from_releases(releases)
      destroy_unreleased_versions
    end

    puts "Tags: #{@tags}"

    error_message = @tags.blank? ? 'Compile Github Extension failed as no releases were found.' : ''
    @extension.update_column(:compilation_error, error_message)
    
    release_infos_by_tag = releases.group_by {|release| release[:tag_name]}.transform_values {|arr| arr.first.to_h}
    CompileExtensionStatus.call(
      extension: @extension, 
      worker: 'SyncExtensionContentsAtVersionsWorker', 
      job_id: SyncExtensionContentsAtVersionsWorker.perform_async(@extension.id, @tags, compatible_platforms, release_infos_by_tag, current_user_id)
    )
  end

  private

  def clone_repo(current_user)
    # Must clear any old repo as git will not clone to a non-empty directory
    FileUtils.rm_rf(Dir["#{@extension.repo_path}"])
    `git clone #{@extension.github_url_with_auth(current_user)} #{@extension.repo_path}`
  end

  def extract_tags_from_releases(releases)
    releases.map { |r| r[:tag_name] }
  end

  def destroy_unreleased_versions
    @extension.extension_versions.where.not(version: @tags).destroy_all
  end
end
