class TierAuthorizer < Authorizer::Base
  def index?
    manage?
  end

  def show?
    index?
  end

  def new?
    create?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  #
  # Only admins can manage +Tier+s.
  #
  def manage?
    admin?
  end

  private

  def admin?
    user.is?(:admin)
  end
end
