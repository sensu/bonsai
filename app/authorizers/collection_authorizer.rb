class CollectionAuthorizer < Authorizer::Base
  def manage?
    admin?
  end

  private

  def admin?
    user.is?(:admin)
  end
end