class TiersController < ApplicationController
  before_action :set_tier, only: [:show, :edit, :update, :destroy]

  def index
    authorize! Tier
    @tiers = Tier.rank(:rank)
  end

  def show
    authorize @tier
  end

  def new
    authorize Tier
    @tier = Tier.new
  end

  def create
    authorize Tier
    @tier = Tier.new(tier_params)

    if @tier.save
      redirect_to tiers_url, notice: 'Tier was successfully created.'
    else
      render :new
    end
  end

  def update
    authorize @tier
    if @tier.update(tier_params)
      redirect_to tiers_url, notice: 'Tier was successfully updated.'
    else
      render :show
    end
  end

  def destroy
    authorize @tier
    @tier.destroy
    redirect_to tiers_url, notice: 'Tier was successfully destroyed.'
  end

  private

  def set_tier
    @tier = Tier.find(params[:id])
  end

  def tier_params
    params.require(:tier).permit(:name, :rank, :icon_name)
  end
end
