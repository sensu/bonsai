class ExtensionVersionAuthorizer < Authorizer::Base
  def show_config?
    admin?
  end

  private

  def admin?
    user.is?(:admin)
  end
end
