class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  #
  # GET /sign-in
  #
  # Redirects the user to the OmniAuth path for authentication
  #
  def new
    redirect_to '/auth/github'
  end

  # This action is only ever used in development sandboxes.
  def passthru
    #:nocov:  This has been manually tested in a dev sandbox.
    user              = User.first     # just choose any user
    session[:user_id] = user.id
    redirect_to redirect_path, notice: t('user.signed_in', name: user.name)
    #:nocov:
  end

  #
  # POST /auth/github/callback
  #
  # Creates a new session for the user from the OmniAuth Auth hash.
  #
  def create
    user = User.find_or_create_from_github_oauth(request.env['omniauth.auth'])

    omniauth_auth_scope   = request.env.dig('omniauth.auth', 'extra', 'scope') || BonsaiAssetIndex::Authentication::AUTH_SCOPE
    normalized_auth_scope = normalize_omniauth_scope(omniauth_auth_scope)
    user.update_attribute(:auth_scope, normalized_auth_scope)
    session[:user_id] = user.id
    redirect_to redirect_path, notice: t('user.signed_in', name: user.name)
  rescue RuntimeError
    redirect_to root_path, notice: t("user.user_is_disabled")
  end

  #
  # DELETE /sign-out
  #
  # Signs out the user
  #
  def destroy
    reset_session

    flash[:signout] = true

    redirect_to root_path, notice: t('user.signed_out')
  end

  private

  def redirect_path
    stored_location || root_path
  end

  # This is a work-around for the fact that GitHub tends to leave off the "push" scope
  # when it sends us the scope in the +omniauth.auth+ env value.
  def normalize_omniauth_scope(scope_str)
    scope_str.dup.tap do |res|
      res << ',push' unless scope_str.to_s.split(',').include?('push')
    end
  end
end
