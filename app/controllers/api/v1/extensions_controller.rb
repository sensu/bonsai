class Api::V1::ExtensionsController < Api::V1Controller
  before_action :init_params, only: [:index, :search]

  def index
    scope = Extension.all

    if params[:namespace]
      scope = scope.in_namespace(params[:namespace])
    end

    if params[:name]
      scope = scope.with_name(params[:name])
    end

    @total      = scope.count
    @extensions = scope.as_index(order: @order, limit: @items, start: @start)

    if @total <= @next_page_params[:start]
      @next_page_params = nil
    end
  end

  def show
    @extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
  end

  #
  # GET /api/v1/search?q=QUERY
  #
  # Return extensions with a name that contains the specified query. Takes the
  # +q+ parameter for the query. It also handles the start and items parameters
  # for specify where to start the search and how many items to return. Start
  # defaults to 0. Items defaults to 10. Items has an upper limit of 100.
  #
  # @example
  #   GET /api/v1/search?q=redis
  #   GET /api/v1/search?q=redis&start=3&items=5
  #
  def search
    @results = Extension.search(
      params.fetch(:q, nil)
    ).offset(@start).limit(@items)

    @total = @results.count(:all)
  end
end
