class Api::V1::ExtensionsController < Api::V1Controller

  include Annotations
  
  before_action :init_params, only: [:index]
  before_action :authenticate_user!, only: [:update, :sync_repo]

  attr_reader :current_user

  resource_description do
    name 'Assets'
  end

  api! <<~EOD
    Retrieve data for all the #{I18n.t('nouns.extension').pluralize} in the #{Rails.configuration.app_name}.
    Results are paginated, with pagination controlled via the "start" and "items" params.
    If there are remaining pages to be retrieved, the payload will include a "next" URL.
  EOD
  param :start, Integer, desc: "zero-based index of the starting #{I18n.t('nouns.extension')} (default is 0)"
  param :items, Integer, desc: "zero-based index of the starting #{I18n.t('nouns.extension')} (default is 10, max is 100)"
  example "GET https://#{ENV['HOST']}/api/v1/assets"
  example <<-EOX
    {
    "start": 0,
    "total": 2,
    "next": "https://bonsai-asset-index.com/api/v1/assets?start=10",
    "assets": [
        {
            "name": "gofullstack/acms-admin-wildcard-redirect",
            "description": "Average CMS Wildcard Admin Redirect WordPress Plugin",
            "url": "https://bonsai-asset-index.com/api/v1/assets/gofullstack/acms-admin-wildcard-redirect",
            "github_url": "https://github.com/gofullstack/acms-admin-wildcard-redirect",
            "download_url": "https://bonsai-asset-index.com/assets/gofullstack/acms-admin-wildcard-redirect/download",
            "builds": []
        },
        {
            "name": "demillir/maruku",
            "description": "A pure-Ruby Markdown-superset interpreter (Official Repo).",
            "url": "https://bonsai-asset-index.com/api/v1/assets/demillir/maruku",
            "github_url": "https://github.com/demillir/maruku",
            "download_url": "https://bonsai-asset-index.com/assets/demillir/maruku/download",
            "versions": [
              "0.1.1-20181030": {
                "assets": [
                  {
                    "platform": "linux",
                    "arch": "x86_64",
                    "version": "0.1.1-20181030",
                    "asset_sha": "6f2121a6c8690f229e9cb962d8d71f60851684284755d4cdba4e77ef7ba20c03283795c4fccb9d6ac8308b248f2538bf7497d6467de0cf9e9f0814625b4c6f91",
                    "asset_url": "http://srv2:3000/f60851684284755d4cdba4e77ef7ba2/test_asset-v0.1-20181030-linux-x86_64.tar.gz",
                    "last_modified": "2019-01-01 12:00:00"
                  },
                  {
                    "platform": "alpine",
                    "arch": "x86_64",
                    "version": "v0.1-20181030",
                    "asset_sha": null,
                    "asset_url": null,
                    "last_modified": null
                  }
                ]
              }
            ]
        }
    ]
    }
  EOX
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

  api! <<~EOD
    Retrieve data for a single #{I18n.t('nouns.extension')}, identified by a username and repo ID.
  EOD
  param :username, String, required: true, desc: "Bonsai Asset Index user name of the asset owner"
  param :id,       String, required: true, desc: "Bonsai Asset Index asset name"
  example "GET https://#{ENV['HOST']}/api/v1/assets/demillir/maruku"
  example <<-EOX
    {
      "name": "demillir/maruku",
      "description": "A pure-Ruby Markdown-superset interpreter (Official Repo).",
      "url": "https://bonsai-asset-index.com/api/v1/assets/demillir/maruku",
      "github_url": "https://github.com/demillir/maruku",
      "download_url": "https://bonsai-asset-index.com/assets/demillir/maruku/download",
      "versions": [
        "0.1.1-20181030": {
          "assets": [
            {
              "platform": "linux",
              "arch": "x86_64",
              "version": "0.1.1-20181022",
              "asset_sha": "6f2121a6c8690f229e9cb962d8d71f60851684284755d4cdba4e77ef7ba20c03283795c4fccb9d6ac8308b248f2538bf7497d6467de0cf9e9f0814625b4c6f91",
              "asset_url": "http://srv2:3000/api/v1/assets/demillir/maruku/0.1.1-20181030/linux/x86_64/release_asset",
              "last_modified": "2019-01-01 12:00:00"
            },
            {
              "platform": "alpine",
              "arch": "x86_64",
              "version": "0.1.1-20181030",
              "asset_sha": null,
              "asset_url": null,
              "last_modified": null
            }
          ]
        }
      ]
    }
  EOX
  def show
    @extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
  end

  api! <<~EOD
    Recompile #{I18n.t('nouns.extension').pluralize} in the #{Rails.configuration.app_name}.
    This endpoint functions for authenticated users (via API auth), and authorized users (site owner, admin).
    Requires a header tag of X-Ops-Userid with the username of the authenticated user.
    Responds with either success or error.
  EOD
  param :username, String, required: true, desc: "#{Rails.configuration.app_name} user name of the #{I18n.t('nouns.extension')} owner"
  param :id,       String, required: true, desc: "#{Rails.configuration.app_name} #{I18n.t('nouns.extension')} name"
  example "GET https://#{ENV['HOST']}/api/v1/assets/recompile/demillir/maruku/"
  example "{'message'=>'Please wait a minute or so for the repository releases to be recompiled, then refresh this page to see the updates.'}"

  def sync_repo
    @extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    if @extension.blank?
      render json: {error_code: I18n.t('api.error_codes.not_found'), error_messages: [I18n.t('api.error_messages.not_found')] }, status: 404
      return
    end
    begin
      authorize! @extension
    rescue
      render_not_authorized([t('api.error_messages.unauthorized_recompile_error')])
    else
      CompileExtension.call(extension: @extension, current_user: current_user)
      render json: {message: t("extension.syncing_in_progress")}, status: 202
    end
  end

  api! <<~EOD
    Update data for a single #{I18n.t('nouns.extension')}, identified by a username and repo ID.  
    Currently limited to just updating tags.
    The authentication headers consists of the following params:
    'X-Ops-Userid' => "username" where username is the owner of the #{I18n.t('nouns.extension')} or the site admin.  This is required as authentication for each request.
    Authentication headers example:
      "X-Ops-Userid": "username",
  EOD
  error 401, I18n.t('api.error_messages.unauthorized_update_error')
  param :username, String, required: true, desc: "Bonsai Asset Index user name of the asset owner"
  param :id,       String, required: true, desc: "Bonsai Asset Index asset name"
  param :extension, Hash, required: true do 
    param :tag_tokens, String, 'String of comma seperated tags'
  end
  example "PUT https://#{ENV['HOST']}/api/v1/assets/demillir/maruku"
  def update
    @extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    begin
      authorize! @extension
    rescue
      render_not_authorized([t('api.error_messages.unauthorized_update_error')])
    else
      eparams = params.require(:extension).permit(:tag_tokens)
      @extension.update_attributes(eparams)
    end
  end
  
end
