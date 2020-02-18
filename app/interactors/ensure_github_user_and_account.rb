class EnsureGithubUserAndAccount
	include Interactor

  delegate :github_user, to: :context
  delegate :account,     to: :context

  def call

    account = Account.find_or_initialize_by(
      username: github_user[:login],
      provider: "github"
    )

    github_user[:name] ||= "Unknown Name"

    account.user = User.unscoped.find_or_create_by(id: account.user_id).tap do |a|
    	a.first_name = first_name
      a.last_name = last_name
      a.email = github_user[:email]
      a.avatar_url = github_user[:avatar_url]
      # enabled: true # only if you want to reactivate inactive accounts
    end

    account.save(validate: false)

    context.account = account

  end

  private

  # "John Clark Smith" = first_name: "John Clark", last_name: "Smith"
  def first_name
  	if github_user[:name].split.count > 1
     	github_user[:name].split[0..-2].join(' ')
    else
      github_user[:name]
    end
  end

  def last_name
  	if github_user[:name].split.count > 1
     	github_user[:name].split.last
    end
  end

end