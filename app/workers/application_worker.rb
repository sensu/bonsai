class ApplicationWorker
	include Sidekiq::Worker
  include Sidekiq::Status::Worker # enables job status tracking

  private

  def default_url_options
    ActionController::Base.default_url_options
  end

end
