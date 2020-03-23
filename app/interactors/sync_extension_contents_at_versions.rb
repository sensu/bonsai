class SyncExtensionContentsAtVersions
	include Interactor

	delegate :extension, 									to: :context
	delegate :tag_names, 									to: :context
	delegate :compatible_platforms,				to: :context 
	delegate :release_infos_by_tag_name,	to: :context
	delegate :errored_tag_names, 					to: :context
	delegate :command_run,								to: :context

	def call
		context.errored_tag_names = []
		context.command_run = CmdAtPath.new(extension.repo_path)
		tag_names.each do |tag_name|

			if semver?(tag_name)
				release_info = release_infos_by_tag_name[tag_name].to_h
        CompileExtensionStatus.call(
          extension: extension,
          task: "Sync Extension Version #{tag_name}",
        )
				
        sync_extension_version(tag_name, release_info)
	      tally_commits if tag_name == "master"
        
	    end # if semver?

	   end # versions.each

	end

	private

	def semver?(tag_name)
		begin
      tag = SemverNormalizer.call(tag_name)
      Semverse::Version.new(tag)
    rescue Semverse::InvalidVersionFormat => error
      unless errored_tag_names.include?(tag_name)
        context.errored_tag_names << tag_name
        compilation_error = [extension.compilation_error, error.message]
        extension.update_column(:compilation_error, compilation_error.compact.join('; '))
        context.error = compilation_error.compact.join('; ')
        message = "#{extension.lowercase_name} release is invalid: #{context.error}"
      end
      return false
    end
    true
	end

	def sync_extension_version(tag_name, release_info)
    checkout_correct_tag(tag_name)
    readme_context = FetchReadmeAtVersion.call(
      extension: extension,
      tag_name: tag_name,
    )
    
    version_context = EnsureUpdatedVersion.call(
      extension: extension,
      tag_name: tag_name,
      readme_body: readme_context.body,
      readme_ext: readme_context.file_extension
    )

    set_compatible_platforms(version_context.version)
    set_last_commit(version_context.version)
    set_commit_count(version_context.version)

    scan_files_context = ScanVersionFiles.call(
      extension: extension,
      version: version_context.version
    )

    sync_release_info(version_context.version, release_info)

    override_context = CompileGithubOverrides.call(
      extension: extension,
      version: version_context.version
    )

    persist_context = PersistAssets.call(
      version: version_context.version
    )

    update_annotations(version_context.version)
    
  end

  def set_compatible_platforms(version)
    unless version.supported_platforms.any?
      version.supported_platform_ids = compatible_platforms
    end
    rescue PG::UniqueViolation
  end

  def set_last_commit(version)
    commit = command_run.cmd("git log -1")
    # no git log for this release
    return if commit.blank?

    commit.gsub!(/^Merge: [^\n]+\n/, "")
    sha, author, date = *commit.split("\n")

    message = commit.split("\n\n").last
    # Empty repo; no commits
    return if message.blank?

    message = message.gsub("\n", " ").strip
    sha = sha.gsub("commit ", "")
    date = Time.parse(date.gsub("Date:", "").strip)
    version.update_columns(
      last_commit_sha: sha,
      last_commit_at: date,
      last_commit_string: message,
      last_commit_url: version.extension.github_url + "/commit/#{sha}"
    )
  end

  def set_commit_count(version)
    version.update_column(:commit_count, command_run.cmd("git shortlog | grep -E '^[ ]+\\w+' | wc -l").strip.to_i)
  end

  def sync_release_info(version, release_info)
    version.update_column(:release_notes, release_info['body'])
  end

  def update_annotations(version)
    config_hash = version.config
    if config_hash['annotations'].present?
      prefix = ExtensionVersion::ANNOTATION_PREFIX
      updated_annotations = {}
      config_hash['annotations'].each do |key, value|
        key = "#{prefix}.#{key}" unless key.start_with?(prefix)
        updated_annotations[key] = value
      end
      config_hash['annotations'] = updated_annotations
      version.update_columns(
        config: config_hash,
        annotations: updated_annotations
      )
    end
  end

  def checkout_correct_tag(tag_name)
    command_run.cmd("git checkout #{tag_name}")
    command_run.cmd("git pull origin #{tag_name}")
  end

  def tally_commits
    commits = command_run.cmd("git --no-pager log --format='%H|%ad'")

    commits.split("\n").each do |c|
      sha, date = c.split("|")

      CommitSha.transaction do
        if !CommitSha.where(sha: sha).first
          CommitSha.create(sha: sha)
          DailyMetric.increment(@extension.commit_daily_metric_key, 1, date.to_date)
        end
      end
    end
  end

end