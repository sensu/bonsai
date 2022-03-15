module BonsaiAssetIndex
  module Authentication
    AUTH_SCOPE                 = "public_repo,read:org,user:email,write:repo_hook,push"

    #
    # Include the following methods as helper methods.
    #
    def self.included(controller)
      controller.send(:helper_method, :current_user, :signed_in?)
    end

    #
    # The currently logged in user, or nil if there is no user logged in.
    #
    # @return [User, nil]
    #
    def current_user
      @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    end

    #
    # Is there a signed in user?
    #
    # @return [Boolean] is there a signed in user?
    #
    def signed_in?
      current_user.present?
    end

    #
    # Redirect to the sign in url if there is no current_user
    #
    def authenticate_user!(skip_location_storage: false)
      if !signed_in? or current_user.auth_scope != AUTH_SCOPE
        store_location! unless skip_location_storage
        redirect_to sign_in_url, notice: I18n.t('user.must_be_signed_in')
      end
    end
  end
end
