class CreateExtension
  def initialize(params, user)
    @params = params
    @tags = params[:tag_tokens]
    @compatible_platforms = params[:compatible_platforms] || []
    @user = user
    @github = @user.octokit
    @version_name = params[:version].presence || 'v0.0.1'
  end

  def process!
    candidate = Extension.new(@params) do |extension|
      extension.owner = @user
    end

    if validate(candidate, @github, @user)
      candidate.save
      postprocess(candidate, @github, @compatible_platforms, @version_name)
    else
      existing = Extension.unscoped.where(enabled: false, github_url: candidate.github_url).first
      if existing
        # A disabled extension is available for re-use, but it must first be re-enabled.
        existing.update_attribute(:enabled, true)
        return existing
      end
    end

    return candidate
  end

  private

  def postprocess(extension, github, compatible_platforms, version_name)
    if extension.hosted?
      postprocess_hosted_extension(extension, version_name)
    else
      postprocess_github_extension(extension, github, compatible_platforms)
    end
  end

  def postprocess_hosted_extension(extension, version_name='master')
    owner_name = extension.owner.username

    extension.update_attributes(
      owner_name: owner_name
    )

    extension_version = extension.extension_versions.create!(version: version_name)

    if extension.tmp_source_file.attached?
      # Transfer the temporarily-staged attachment to the extension_version.
      extension_version.source_file.attach(extension.tmp_source_file.blob)
      extension.tmp_source_file.detach
      process_hosted_config_file(extension_version)
    end
  end

  def process_hosted_config_file(version)
    files_regexp = "(#{Extension::CONFIG_FILE_NAMES.join('|')})"
    result       = FetchHostedFile.call(blob: version.source_file.blob, file_path: files_regexp)
    body         = result.content
    config_hash = YAML.load(body.to_s) rescue {}

    if config_hash.is_a?(Hash)
      version.config = config_hash
      version.save # Until we get a successful compilation, we need the initial config to compile.
      result         = CompileExtensionVersionConfig.call(version: version)
      version.config = result.data_hash if result.success?
      version.save
    end
  end

  def postprocess_github_extension(extension, github, compatible_platforms)
    repo_info = github.repo(extension.github_repo)
    org       = repo_info[:organization]

    github_organization = if org
                            GithubOrganization.where(github_id: org[:id]).first_or_create!(
                              name:       org[:login],
                              avatar_url: org[:avatar_url]
                            )
                          end
    owner_name = org ? org[:login] : extension.owner.username

    extension.update_attributes(
      github_organization: github_organization,
      owner_name:          owner_name
    )

    CollectExtensionMetadataWorker.perform_async(extension.id, compatible_platforms.select { |p| !p.strip.blank? })
    SetupExtensionWebHooksWorker.perform_async(extension.id)
    NotifyModeratorsOfNewExtensionWorker.perform_async(extension.id)
  end

  def validate(extension, github, user)
    return false if !extension.valid?

    if extension.hosted?
      extension.tmp_source_file.attached?
    else
      repo_valid?(extension, github, user)
    end
  end

  def repo_valid?(extension, github, user)
    validatate_repo_collaborator(extension, github, user) &&
      validate_config_file(extension, github)
  end

  def validatate_repo_collaborator(extension, github, user)
    begin
      result = github.collaborator?(extension.github_repo, user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result
      extension.errors.add(:github_url, I18n.t("extension.github_url_format_error"))
    end

    result
  end

  def validate_config_file(extension, github)
    config_file_names = Extension::CONFIG_FILE_NAMES

    begin
      repo_top_level_file_names   = github.contents(extension.github_repo).map { |h| h[:name] }
      top_level_config_file_names = repo_top_level_file_names & config_file_names
      result                      = top_level_config_file_names.any?
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result
      allowed_config_file_names_str = config_file_names.to_sentence(last_word_connector: ', or ',
                                                                    two_words_connector: ' or ')
      extension.errors.add(:github_url,
                           I18n.t("extension.missing_config_file",
                                  allowed_config_file_names: allowed_config_file_names_str))
    end

    result
  end
end
