class Api::V1::ExtensionsController < Api::V1Controller
  before_action :init_params, only: [:index]

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
end
