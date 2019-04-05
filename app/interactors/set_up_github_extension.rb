# Call this service after creating a GitHub-hosted extension.
# This service sets up all of the information, webhooks, email notifications, etc
# for the new extension.

class SetUpGithubExtension
  include Interactor

  # The required context attributes:
  delegate :extension,            to: :context
  delegate :octokit,              to: :context
  delegate :compatible_platforms, to: :context

  def call
    platforms = compatible_platforms.select { |p| !p.strip.blank? }
    CollectExtensionMetadataWorker.perform_async(extension.id, platforms)
    SetupExtensionWebHooksWorker.perform_async(extension.id)
    NotifyModeratorsOfNewExtensionWorker.perform_async(extension.id)
  end

  def self.gather_github_info(extension, octokit, owner)
    repo_info = octokit.repo(extension.github_repo)
    org       = repo_info[:organization]

    github_organization = if org
                            GithubOrganization.where(github_id: org[:id]).first_or_create!(
                              name:       org[:login],
                              avatar_url: org[:avatar_url]
                            )
                          end
    owner_name          = org ? org[:login] : owner.username
    return github_organization, owner_name
  end

end
