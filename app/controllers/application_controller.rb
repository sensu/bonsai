require "application_responder"

class ApplicationController < ActionController::Base

  force_ssl if: :ssl_configured?
  protect_from_forgery with: :exception
  before_action :define_search

  helper_method :owner_scoped_extension_url, :redis_pool

  include BonsaiAssetIndex::Authorization
  include BonsaiAssetIndex::Authentication
  include BonsaiAssetIndex::LocationStorage
  include UrlHelpers

  rescue_from(
    NotAuthorizedError,
    ActiveRecord::RecordNotFound,
    ActionController::UnknownFormat,
    ActionView::MissingTemplate
  ) do |error|
    not_found!(error)
  end

  def define_search
    @search = { path: extensions_path, name: 'Extensions' }
  end

  def redis_pool
    REDIS_POOL
  end

  protected

  def not_found!(error = nil)
    raise error if error && Rails.env.development?

    options = { status: 404 }

    if error
      options[:notice] = error.message
    end

    render 'exceptions/404.html.erb', options
  end

  def after_sign_in_path_for(_resource)
    stored_location || root_path
  end

  #
  # Redirect the user to their profile page if they do not have any linked
  # GitHub accounts with the notice to instruct them to link a GitHub account
  # before signing a CCLA.
  #
  # If GitHub integration is disabled, just return true.
  #
  def require_linked_github_account!
    return unless ROLLOUT.active?(:github)

    unless current_user.linked_github_account?
      store_location!
      redirect_to link_github_profile_path,  notice: t('requires_linked_github')
    end
  end

  def github_client
    @github_client ||= Octokit::Client.new(client_id: ENV["GITHUB_CLIENT_ID"], client_secret: ENV["GITHUB_CLIENT_SECRET"])
  end

  def ssl_configured?
    !(Rails.env.development? or Rails.env.test?)
  end
  
end
