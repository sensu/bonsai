class OrganizationAuthorizer < Authorizer::Base
  #
  # A user who is an application admin or is a member of an organization can view a +CclaSignature+
  #
  def view_cclas?
    user.is?(:admin) || user.organizations.include?(record)
  end

  #
  # An admin of an organization the application can resign a CCLA.
  #
  # @return [Boolean]
  #
  def resign_ccla?
    organization_or_application_admin?
  end

  #
  # An admin of an organization the application can manage its invitations.
  #
  # @return [Boolean]
  #
  def manage_contributors?
    organization_or_application_admin?
  end

  #
  # application admins can manage organizations
  #
  # @return [Boolean]
  #
  def manage_organization?
    user.is?(:admin)
  end

  #
  # application admins can see the page to manage organizations
  #
  # @return [Boolean]
  #
  def show?
    manage_organization?
  end

  #
  # application admins can delete organizations
  #
  # @return [Boolean]
  #
  def destroy?
    manage_organization?
  end

  #
  # application admins can combine organizations
  #
  # @return [Boolean]
  #
  def combine?
    manage_organization?
  end

  #
  # Only users who don't already belong to the organization can join
  #
  # @return [Boolean]
  #
  def request_to_join?
    record.contributors.where(user_id: user.id).empty? &&
      record.contributor_requests.where(user_id: user.id).empty?
  end

  #
  # A user who is an organization admin or an application admin can
  # manage the requests to join
  #
  def manage_requests_to_join?
    organization_or_application_admin?
  end

  private

  def organization_or_application_admin?
    user.is?(:admin) || user.admin_of_organization?(record)
  end
end
