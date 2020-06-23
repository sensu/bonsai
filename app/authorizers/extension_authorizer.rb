class ExtensionAuthorizer < Authorizer::Base
  #
  # Owners and collaborators of an extension can publish new versions of an extension.
  #
  def create?
    owner_or_collaborator?
  end

  #
  # Owners of an extension and admins can update an extension.
  #
  def update?
    owner_or_admin?
  end

  #
  # Owners of an extension can destroy an extension.
  #
  def destroy?
    owner?
  end

  #
  # Owners of an extension and application admins can manage an extension.
  #
  def manage?
    owner_or_admin?
  end

  #
  # Owners of an extension are the only ones that can add collaborators.
  #
  # @return [Boolean]
  #
  def create_collaborator?
    owner?
  end

  #
  # Owners and collaborators of an extension and application admins can manage
  # the extension's urls.
  #
  # @return [Boolean]
  #
  def manage_extension_urls?
    owner_or_collaborator? || admin?
  end

  #
  # Admins can transfer ownership of an extension to another user.
  #
  # @return [Boolean]
  #
  def transfer_ownership?
    owner_or_admin?
  end

  #
  # Owners of an extension and application admins can deprecate an extension if
  # that extension is not already deprecated.
  #
  # @return [Boolean]
  #
  def deprecate?
    !record.deprecated? && owner_or_admin?
  end

  #
  # Owners of an extension and application admins can undeprecate an extension if
  # that extension is deprecated.
  #
  # @return [Boolean]
  #
  def undeprecate?
    record.deprecated? && owner_or_admin?
  end

  #
  # Owners of an extension and application admins can put an extension up for
  # adoption.
  #
  # @return [Boolean]
  #
  def manage_adoption?
    owner_or_admin?
  end

  #
  # Admins can toggle an extension as featured.
  #
  # @return [Boolean]
  #
  def toggle_featured?
    admin?
  end

  #
  # Admins can disable an extension.
  #
  # @return [Boolean]
  #
  def disable?
    owner_or_collaborator? || admin?
  end

  def make_hosted_extension?
    ROLLOUT.active?(:hosted_extensions) && admin?
  end

  def add_hosted_extension_version?
    make_hosted_extension?
  end

  def delete_hosted_extension_version?
    add_hosted_extension_version?
  end

  def download_hosted_extension_version_source?
    owner_or_admin?
  end

  def change_tier?
    admin?
  end

  def sync_repo?
    owner_or_collaborator? || admin?
  end

  def select_default_version?
    owner_or_admin?
  end

  def edit_extension_config_overrides?
    owner_or_admin?
  end

  def report?
    signed_in?
  end

  private

  def signed_in?
    user&.persisted? || false
  end

  def admin?
    user.is?(:admin)
  end

  def owner?
    record.owner == user
  end

  def owner_or_collaborator?
    owner? || record.collaborator_users.include?(user)
  end

  def owner_or_admin?
    owner? || admin?
  end

end
