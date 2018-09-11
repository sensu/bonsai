class ApplicationWorker
  include Sidekiq::Worker

  private

  def default_url_options
    debugger
    ActionController::Base.default_url_options
  end

end
