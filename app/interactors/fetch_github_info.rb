# Call this service before creating a GitHub-hosted extension.
# This service gathers information from Github for the new extension.

class FetchGithubInfo
  include Interactor

  delegate :extension,  to: :context
  delegate :owner,      to: :context 
  
  def call
    repo_info = owner.octokit.repo(extension.github_repo)
    org       = repo_info[:organization]

    context.github_organization = if org
      GithubOrganization.where(github_id: org[:id]).first_or_create!(
        name:       org[:login],
        avatar_url: org[:avatar_url]
      )
    else
      nil
    end

    context.owner_name = if org 
      org[:login] 
    else 
      owner.username
    end
  end

end 