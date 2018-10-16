class ExtensionTiersController < ApplicationController
  def update
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:extension_id])
    tier      = Tier.find(params[:id])
    authorize! extension, :change_tier?

    extension.update(tier_id: tier.id)
    redirect_to owner_scoped_extension_url(extension), notice: 'Tier updated'
  end
end
