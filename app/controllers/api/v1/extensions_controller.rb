class Api::V1::ExtensionsController < Api::V1Controller
  before_action :init_params, only: [:index]

  api! <<~EOD
    Retrieve data for all the #{I18n.t('nouns.extension').pluralize} in the #{Rails.configuration.app_name}.
    Results are paginated, with pagination controlled via the "start" and "items" params.
    If there are remaining pages to be retrieved, the payload will include a "next" URL.
  EOD
  param :start, Integer, desc: "zero-based index of the starting #{I18n.t('nouns.extension')} (default is 0)"
  param :items, Integer, desc: "zero-based index of the starting #{I18n.t('nouns.extension')} (default is 10, max is 100)"
  example "GET https://#{ENV['HOST']}/api/v1/extensions"
  example <<-EOX
    {
    "start": 0,
    "total": 2,
    "next": "https://bonsai-asset-index.com/api/v1/extensions?start=10",
    "extensions": [
        {
            "name": "gofullstack/acms-admin-wildcard-redirect",
            "description": "Average CMS Wildcard Admin Redirect WordPress Plugin",
            "url": "https://bonsai-asset-index.com/api/v1/extensions/gofullstack/acms-admin-wildcard-redirect",
            "github_url": "https://github.com/gofullstack/acms-admin-wildcard-redirect",
            "download_url": "https://bonsai-asset-index.com/assets/gofullstack/acms-admin-wildcard-redirect/download",
            "builds": []
        },
        {
            "name": "demillir/maruku",
            "description": "A pure-Ruby Markdown-superset interpreter (Official Repo).",
            "url": "https://bonsai-asset-index.com/api/v1/extensions/demillir/maruku",
            "github_url": "https://github.com/demillir/maruku",
            "download_url": "https://bonsai-asset-index.com/assets/demillir/maruku/download",
            "builds": [
                {
                    "platform": "linux",
                    "arch": "x86_64",
                    "version": "v0.1-20181022",
                    "asset_url": "https://github.com/demillir/maruku/releases/download/v0.1-20181022/test_asset-v0.1-20181030-linux-x86_64.tar.gz",
                    "asset_sha": "6f2121a6c8690f229e9cb962d8d71f60851684284755d4cdba4e77ef7ba20c03283795c4fccb9d6ac8308b248f2538bf7497d6467de0cf9e9f0814625b4c6f91",
                    "details_url": "http://srv2:3000/api/v1/extensions/demillir/maruku/v0.1-20181022/linux/x86_64/release_asset"
                },
                {
                    "platform": "alpine",
                    "arch": "x86_64",
                    "version": "v0.1-20181030",
                    "asset_url": null,
                    "asset_sha": "67752b4721bb4c61a5c728439141e5b55c361e2867ac0889eacdd887a301ebb2c08abf82a814c201539a588b46b0d356024e03716dd4c1bea60d3cc723885c87",
                    "details_url": "http://srv2:3000/api/v1/extensions/demillir/maruku/v0.1-20181030/alpine/x86_64/release_asset"
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
  example "GET https://#{ENV['HOST']}/api/v1/extensions/demillir/maruku"
  example <<-EOX
    {
        "name": "demillir/maruku",
        "description": "A pure-Ruby Markdown-superset interpreter (Official Repo).",
        "url": "https://bonsai-asset-index.com/api/v1/extensions/demillir/maruku",
        "github_url": "https://github.com/demillir/maruku",
        "download_url": "https://bonsai-asset-index.com/assets/demillir/maruku/download",
        "builds": [
            {
                "platform": "linux",
                "arch": "x86_64",
                "version": "v0.1-20181022",
                "asset_url": "https://github.com/demillir/maruku/releases/download/v0.1-20181022/test_asset-v0.1-20181030-linux-x86_64.tar.gz",
                "asset_sha": "6f2121a6c8690f229e9cb962d8d71f60851684284755d4cdba4e77ef7ba20c03283795c4fccb9d6ac8308b248f2538bf7497d6467de0cf9e9f0814625b4c6f91",
                "details_url": "http://srv2:3000/api/v1/extensions/demillir/maruku/v0.1-20181022/linux/x86_64/release_asset"
            },
            {
                "platform": "alpine",
                "arch": "x86_64",
                "version": "v0.1-20181030",
                "asset_url": null,
                "asset_sha": "67752b4721bb4c61a5c728439141e5b55c361e2867ac0889eacdd887a301ebb2c08abf82a814c201539a588b46b0d356024e03716dd4c1bea60d3cc723885c87",
                "details_url": "http://srv2:3000/api/v1/extensions/demillir/maruku/v0.1-20181030/alpine/x86_64/release_asset"
            }
        ]
    }
  EOX
  def show
    @extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
  end
end
