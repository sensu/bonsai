class Api::V1::TagsController < ApplicationController

  def index
  	query = params[:q].gsub(/[^0-9a-z ]/i, '') # remove all non-numeric chars
    @tags = Tag.where("name ILIKE :search", search: "#{query}%").limit(5).all
    @platforms = SupportedPlatform.where("name ILIKE :search", search: "#{query}%").limit(5).all
    @defaults = Tag::DEFAULT_TAGS.select { |t| t =~ /^#{query}/i }
    render json: @tags.map(&:name) + @platforms.map(&:name) + @defaults
  end

end
