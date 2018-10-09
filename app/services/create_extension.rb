class CreateExtension
  def initialize(params, user)
    @params = params
    @tags = params[:tag_tokens]
    @compatible_platforms = params[:compatible_platforms] || []
    @user = user
    @github = @user.octokit
  end

  def process!
    candidate = Extension.new(@params) do |extension|
      extension.owner = @user
    end

    if validate(candidate, @github, @user)
      candidate.save
      postprocess(candidate, @github, @compatible_platforms)
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

  def postprocess(extension, github, compatible_platforms)
    if extension.hosted?
      postprocess_hosted_extension(extension)
    else
      postprocess_github_extension(extension, github, compatible_platforms)
    end
  end

  def postprocess_hosted_extension(extension)
    owner_name = extension.owner.username

    extension.update_attributes(
      owner_name: owner_name
    )

    extension_version = extension.extension_versions.create!(version: 'master')

    if extension.tmp_source_file.attached?
      # Transfer the temporarily-staged attachment to the extension_version.
      extension_version.source_file.attach(extension.tmp_source_file.blob)
      extension.tmp_source_file.detach
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

    (extension.hosted? && extension.tmp_source_file.attached?) || repo_valid?(extension, github, user)
  end

  def repo_valid?(extension, github, user)
    begin
      result = github.collaborator?(extension.github_repo, user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized, Octokit::Forbidden
      result = false
    end

    if !result then extension.errors.add(:github_url, I18n.t("extension.github_url_format_error")) end

    result
  end
end
