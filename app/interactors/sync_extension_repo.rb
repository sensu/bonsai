
class SyncExtensionRepo
  include Interactor

  delegate :extension, 						to: :context
  delegate :compatible_platforms, to: :context

  def call

    context.compatible_platforms ||= []

  	# clear previous error messages
  	extension.update_column(:compilation_error, '')

    begin
      releases = extension.octokit.releases(extension.github_repo)
    rescue Octokit::NotFound
      message = 'Compile Github Extension failed as octokit failed to connect.'
      extension.update_column(:compilation_error, message)
      context.fail!(error: message)
    end

  	clone_repo
  	tag_names = extract_tag_names_from_releases(releases)
  	destroy_unreleased_versions(tag_names)

  	if tag_names.blank?
  		message = 'Compile Github Extension failed as no releases were found.'
  		extension.update_column(:compilation_error, message)
  		context.fail!(error: message)
  	end

  	release_infos_by_tag_name = releases.group_by {|release| release[:tag_name]}.transform_values {|arr| arr.first.to_h}

  	SyncExtensionContentsAtVersions.call(
  		extension: extension,
  		tag_names: tag_names,
  		compatible_platforms: compatible_platforms,
  		release_infos_by_tag_name: release_infos_by_tag_name
  	)

  end

  private

  def clone_repo
    # Must clear any old repo as git will not clone to a non-empty directory
    FileUtils.rm_rf(Dir["#{extension.repo_path}"])
    system("git clone #{extension.github_url} #{extension.repo_path}")
  end

  def extract_tag_names_from_releases(releases)
    releases.map { |r| r[:tag_name] }
  end

  def destroy_unreleased_versions(tag_names)
    extension.extension_versions.where.not(version: tag_names).destroy_all
  end

end