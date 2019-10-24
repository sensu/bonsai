class CollectionsController < ApplicationController

	def index
		authorize! Collection, :manage?
		@collections = Collection.rank(:row_order).all
	end

	def new
		authorize! Collection, :manage?
		@collection = Collection.new
	end

	def edit
		authorize! Collection, :manage?
		@collection = Collection.find(params[:id])
	end

	def create
    authorize Collection, :manage?
    @collection = Collection.new(collection_params)

    if @collection.save
      redirect_to collections_path, notice: 'Collection was successfully created.'
    else
      render :new
    end
  end

  def update
    authorize Collection, :manage?
    @collection = Collection.find(params[:id])
    if @collection.update(collection_params)
      redirect_to collections_path, notice: 'Collection was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    authorize Collection, :manage?
    @collection = Collection.find(params[:id])
    if @collection.extensions.blank?
    	@collection.destroy
    	flash[:notice] = 'Collection was successfully destroyed'
    else
    	flash[:error] = 'Cannot delete Collection when Extensions are associated with it.'
    end
    redirect_to collections_path
  end

  private

  def collection_params
    params.require(:collection).permit(:title, :slug, :description)
  end

end
