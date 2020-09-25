# Call this service before saving a new extension.
# This service validates the new extension.

class ValidateNewExtension
  include Interactor

  delegate :extension,  to: :context 
  delegate :owner,      to: :context
  
  def call

    context.fail!(error: I18n.t("extension.tmp_source_file_error")) unless extension.valid?
    
    if extension.hosted?
      validate_tmp_source_file
    else
      validate_repo_collaborator
      validate_config_file
    end
   
  end

  def validate_tmp_source_file
    unless extension.tmp_source_file.attached?
      extension.errors.add(:tmp_source_file, I18n.t("extension.tmp_source_file_error"))
      context.fail!(error: I18n.t("extension.tmp_source_file_error"))
    end
  end

  def validate_repo_collaborator
    begin
      valid = owner.octokit.collaborator?(extension.github_repo, owner.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      valid = false
    end

    unless valid 
      extension.errors.add(:github_url, I18n.t("extension.github_url_format_error"))
      context.fail!(error: I18n.t("extension.github_url_format_error"))
    end
  end

  def validate_config_file
    config_file_names = Extension::CONFIG_FILE_NAMES
    begin
      repo_top_level_file_names = owner.octokit.contents(extension.github_repo).map { |h| h[:name] }
      valid = (repo_top_level_file_names & config_file_names).present?
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      valid = false
    end

    unless valid
      allowed_config_file_names = config_file_names.to_sentence(last_word_connector: ', or ', two_words_connector: ' or ')
      message = I18n.t("extension.missing_config_file", allowed_config_file_names: allowed_config_file_names)
      extension.errors.add(:github_url, message)   
      context.fail!(error: message)
    end
  end

end 