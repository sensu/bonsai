require 'spec_helper'

describe ApplicationController do
  it { should be_a(BonsaiAssetIndex::Authorization) }
  it { should be_a(BonsaiAssetIndex::LocationStorage) }

  describe 'a controller which responds to specific formats' do
    controller do
      def index
        respond_to do |format|
          format.json do
            render json: {}
          end
        end
      end

      def show
        respond_to do |format|
          format.html do
            render plain: ''
          end
        end
      end

      def edit
      end
    end

    it '404s when HTML is requested by JSON is served' do
      get :index

      expect(response).to render_template('exceptions/404.html.erb')
      expect(response.status.to_i).to eql(404)
    end

    it '404s when JSON is requested but HTML is served' do
      get :show, params: {id: 1, format: :json}

      expect(response).to render_template('exceptions/404.html.erb')
      expect(response.status.to_i).to eql(404)
    end

    it 'sets the default search context as extensions' do
      get :index

      expect(assigns[:search][:name]).to eql('Extensions')
      expect(assigns[:search][:path]).to eql(extensions_path)
    end
  end

  describe 'github integration' do
    before { ROLLOUT.deactivate(:github) }
    after { ROLLOUT.activate(:github) }

    controller do
      before_action :require_linked_github_account!

      def index
        respond_to do |format|
          format.html do
            render plain: 'haha'
          end
        end
      end

      def current_user
        nil
      end
    end

    it 'skips the require_linked_github_account! filter if github integration is disabled' do
      get :index

      expect(response).to be_successful
      expect(response.body).to eql('haha')
    end
  end
end
