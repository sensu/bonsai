class FetchAccessibleReposWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    repos = []
    i = 1

    loop do
      break if Rails.env.test?
      r = user.octokit.repos(nil, per_page: 100, page: i)
      break if r.none?
      repos += r.map { |r| r.to_h.slice(:full_name, :name, :description) } rescue []
      i += 1
    end
    #puts repos.inspect

    Redis.current.setex("user-repos-#{user.id}", 5.minutes.to_i, Marshal.dump(repos))
  end
end
