class CreateExtension
  def initialize(params, user)
    @params               = params
    @compatible_platforms = params[:compatible_platforms] || []
    @version_name         = params[:version].presence || 'v0.0.1'
    @user                 = user
    @octokit              = user.octokit
  end

  def process!
    candidate = Extension.new(@params) do |extension|
      if extension.hosted?
        extension.owner = User.host_organization
      else
        extension.owner = @user
      end
    end

    if validate(candidate, @octokit, @user)
      candidate.save
      postprocess(candidate, @octokit, @compatible_platforms, @version_name)
    elsif !candidate.hosted?
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

  def postprocess(extension, octokit, compatible_platforms, version_name)
    if extension.hosted?
      SetUpHostedExtension.call(extension: extension, version_name: version_name)
    else
      SetUpGithubExtension.call(extension: extension, octokit: octokit, compatible_platforms: compatible_platforms)
    end
  end

  def validate(extension, octokit, user)
    return false if !extension.valid?

    if extension.hosted?
      extension.tmp_source_file.attached?
    else
      repo_valid?(extension, octokit, user)
    end
  end

  def repo_valid?(extension, octokit, user)
    validatate_repo_collaborator(extension, octokit, user) &&
      validate_config_file(extension, octokit)
  end

  def validatate_repo_collaborator(extension, octokit, user)
    begin
      result = octokit.collaborator?(extension.github_repo, user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result
      extension.errors.add(:github_url, I18n.t("extension.github_url_format_error"))
    end

    result
  end

  def validate_config_file(extension, octokit)
    config_file_names = Extension::CONFIG_FILE_NAMES

    begin
      repo_top_level_file_names   = octokit.contents(extension.github_repo).map { |h| h[:name] }
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
