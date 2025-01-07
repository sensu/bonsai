class ExtensionsController < ApplicationController
  include Annotations

  before_action :assign_extension, except: [:index, :directory, :collections, :new, :create, :sync_status]
  before_action :store_location_then_authenticate_user!, only: [:follow, :unfollow, :adoption]
  before_action :authenticate_user!, only: [:new, :create]

  skip_before_action :verify_authenticity_token, only: [:webhook, :build]

  #
  # GET /extensions
  #
  # Return all extensions. Extensions are sorted alphabetically by name.
  # Optionally a category can be specified to return only extensions for a
  # given category. Extensions can also be returned as an atom feed if the atom
  # format is specified.
  #
  # @example
  #   GET /extensions?q=redis
  #
  # Pass in order params to specify a sort order.
  #
  # @example
  #   GET /extensions?order=recently_updated
  #
  def index
    params['platforms'].reject!(&:blank?) if params['platforms'].present?
    @extensions = qualify_scope(Extension, params)
                    .includes(:extension_versions)
    @extensions = @extensions.filter_private(current_user)
    @number_of_extensions = @extensions.count(:all)
    @extensions = @extensions.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.atom
    end
  end

  #
  # GET /extensions/new
  #
  # Show a form for creating a new extension.
  #
  def new
    if @repo_names = Redis.current.get("user-repos-#{current_user.id}")
      @repo_names = Marshal.load(@repo_names)
    else
      FetchAccessibleReposWorker.perform_async(current_user.id)
      # puts '******* FetchAccessibleReposWorker *********'
    end

    @extension = Extension.new
  end

  #
  # POST /extensions
  #
  # Create an extension.
  #
  def create
    eparams = params.require(:extension).permit(:name, :description, :github_url, :github_url_short, :tmp_source_file, :tag_tokens, :version, compatible_platforms: [])
    create_extension = CreateExtension.new(eparams, current_user)
    @extension = create_extension.process!

    if @extension.errors.none?
      redirect_to owner_scoped_extension_url(@extension), notice: t("extension.created")
    else
      @repo_names = current_user.octokit.repos.map { |r| r.to_h.slice(:full_name, :name, :description) } rescue []
      render :new
    end
  end

  #
  # GET /extensions/directory
  #
  # Return the three most recently updated and created extensions.
  #
  def directory
    @recently_updated_extensions = Extension.
      filter_private(current_user).
      includes(:extension_versions).
      where.not(owner: nil).
      where("extension_versions.version != 'master'").
      order("extension_versions.created_at DESC").
      limit(4)
    @most_downloaded_extensions = Extension.
      filter_private(current_user).
      includes(:extension_versions).
      where.not(owner: nil).
      ordered_by('most_downloaded').
      limit(6)

    @top_tags = Tag.where(
      id: Tagging.select("tag_id, count(*) as count").
        group("tag_id").
        order("count DESC").
        limit(15).
        map(&:tag_id)
    ).sort_by(&:name)

    @top_collections = Collection.rank(:row_order).limit(10)

    @extension_count = Extension.count
    @user_count = User.count
  end

  #
  # GET /extensions/directory
  #
  # Return the three most recently updated and created extensions.
  #
  def collections
    @collections = Collection.rank(:row_order)
  end

  #
  # GET /extensions/:id
  #
  # Displays an extension.
  #
  def show
    @default_version = @extension.selected_version || @extension.latest_extension_version
    @extension_versions = @extension.sorted_extension_versions
    @collaborators = @extension.collaborators
    @supported_platforms = @extension.supported_platforms
    @downloads = DailyMetric.counts_since(@default_version.download_daily_metric_key, Date.today - 1.month) if @default_version
    @commits = DailyMetric.counts_since(@extension.commit_daily_metric_key, Date.today - 1.year)
    respond_to do |format|
      format.atom
      format.html
    end
  end

  #
  # GET /extensions/:id/download
  #
  # Redirects to the download location for the latest version of this extension.
  #
  def download
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    latest_version = extension.latest_extension_version
    if latest_version.present?
      BonsaiAssetIndex::Metrics.increment('extension.downloads.web')
      DailyMetric.increment(latest_version.download_daily_metric_key)
      redirect_to extension_version_download_url(extension, latest_version, username: params[:username])
    else
      redirect_to(
        owner_scoped_extension_url(extension),
        notice: t(
          'download.not_found',
          extension_or_tool: extension.name
        )
      )
    end
  end

  #
  # PATCH /extensions/:id
  #
  # Update a the specified extension. This currently only supports updating the
  # extension's URLs. It also only returns JSON.
  #
  # NOTE: :id must be the name of the extension.
  #
  def update
    authorize! @extension, :manage?

    @extension.update_attributes(extension_edit_params)

    key = if extension_edit_params.key?(:up_for_adoption)
            if extension_edit_params[:up_for_adoption] == 'true'
              'adoption.up'
            else
              'adoption.down'
            end
          else
            'extension.updated'
          end

    redirect_to owner_scoped_extension_url(@extension), notice: t(key, name: @extension.name)
  end

  #
  # PUT /extensions/:extension/follow
  #
  # Makes the current user follow the specified extension.
  #
  def follow
    FollowExtensionWorker.perform_async(@extension.id, current_user.id)
    @extension.extension_followers.create(user: current_user)
    BonsaiAssetIndex::Metrics.increment 'extension.followed'

    render_follow_button
  end

  #
  # DELETE /extensions/:extension/unfollow
  #
  # Makes the current user unfollow the specified extension.
  #
  def unfollow
    UnfollowExtensionWorker.perform_async(@extension.id, current_user.id)
    extension_follower = @extension.extension_followers.
      where(user: current_user).first!
    extension_follower.destroy
    BonsaiAssetIndex::Metrics.increment 'extension.unfollowed'

    render_follow_button
  end

  #
  # PUT /extensions/:extension/deprecate
  #
  # Deprecates the extension, sets the replacement extension, kicks off a notifier
  # to send emails and redirects back to the deprecated extension.
  #
  def deprecate
    authorize! @extension
    replacement = extension_deprecation_params[:replacement].split(',')
    owner_name, lowercase_name = replacement[0].strip, replacement[1].strip
    replacement_extension = Extension.with_owner_and_lowercase_name(owner_name: owner_name, lowercase_name: lowercase_name )

    if @extension.deprecate(replacement_extension)
      ExtensionDeprecatedNotifier.perform_async(@extension.id)
      redirect_to(
        owner_scoped_extension_url(@extension),
        notice: t(
          'extension.deprecated',
          extension: "#{@extension.owner_name}/#{@extension.name}",
          replacement_extension: "#{replacement_extension.owner_name}/#{replacement_extension.name}"
        )
      )
    else
      redirect_to owner_scoped_extension_url(@extension), notice: @extension.errors.full_messages.join(', ')
    end
  end

  #
  # DELETE /extensions/:extension/deprecate
  #
  # Un-deprecates the extension and sets its replacement extension to nil.
  #
  def undeprecate
    authorize! @extension

    @extension.update_attributes(deprecated: false, replacement: nil)

    redirect_to(
      owner_scoped_extension_url(@extension),
      notice: t(
        'extension.undeprecated',
        extension: @extension.name
      )
    )
  end

  #
  # POST /extensions/:id/adoption
  #
  # Sends an email to the extension owner letting them know that someone is
  # interested in adopting their extension.
  #
  def adoption
    AdoptionMailer.delay.interest_email(@extension, current_user)

    redirect_to(
      owner_scoped_extension_url(@extension),
      notice: t(
        'adoption.email_sent',
        extension_or_tool: @extension.name
      )
    )
  end

  #
  # PUT /extensions/:extension/toggle_featured
  #
  # Allows an application admin to set an extension as featured or
  # unfeatured (if it is already featured).
  #
  def toggle_featured
    authorize! @extension

    @extension.update_attribute(:featured, !@extension.featured)

    redirect_to(
      owner_scoped_extension_url(@extension),
      notice: t(
        'extension.featured',
        extension: @extension.name,
        state: "#{@extension.featured? ? 'featured' : 'unfeatured'}"
      )
    )
  end

  #
  # PUT /extensions/:extension/disable
  #
  # Allows an admin to disable an extension, hiding it from view.
  #
  def disable
    authorize! @extension, :disable?
    @extension.update_attribute(:enabled, false)
    ExtensionDisabledNotifier.perform_async(@extension.id)
    redirect_to "/", notice: t("extension.disabled", extension: @extension.name)
  end

  #
  # PUT /extensions/:extension/enable
  #
  # Allows an admin to enable an extension.
  #
  def enable
    authorize! @extension, :disable?
    @extension.update_attribute(:enabled, true)
    redirect_to owner_scoped_extension_url(@extension), notice: t("extension.enabled", extension: @extension.name)
  end

  #
  # PUT /extensions/:extension/report
  #
  # Notifies moderators to check an extension for inappropriate content.
  #
  def report
    authorize! @extension, :report?
    NotifyModeratorsOfReportedExtensionWorker.perform_async(@extension.id, params[:report][:description], current_user.try(:id))
    redirect_to owner_scoped_extension_url(@extension), notice: t("extension.reported", extension: @extension.name)
  end

  def sync_repo
    extension = Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    authorize! extension
    CompileExtension.call(extension: extension, current_user: current_user)
    redirect_to owner_scoped_extension_url(@extension), notice: t("extension.syncing_in_progress")
  end

  def sync_status
    @extension = Extension.find_by(id: params[:id])
    redis_pool.with do |redis|
      @job_ids = JSON.parse( redis.get("compile.extension;#{params[:id]};status") || "{}" )
    end

    respond_to do |format|
      format.js
    end
  end

  #
  # GET /extensions/:id/deprecate_search?q=QUERY
  #
  # Return extensions with a name that contains the specified query. Takes the
  # +q+ parameter for the query. Only returns extension elgible for replacement -
  # extensions that are not deprecated and not the extension being deprecated.
  #
  # @example
  #   GET /extensions/redis/deprecate_search?q=redisio
  #
  def deprecate_search
    @results = @extension.deprecate_search(params.fetch(:q, nil))

    respond_to do |format|
      format.json
    end
  end

  #
  # POST /assets/:username/:id/webhook
  #
  # Receive updates from GitHub's webhook API about an extension's repo.
  #
  def webhook
    event_type = request.headers["X-GitHub-Event"]
    payload    = JSON.parse(request.body.read)

    case event_type
      when "release"
        unless payload['release']['draft']
          CollectExtensionMetadataWorker.perform_async(@extension.id, [], current_user&.id)
        end
      ##
      # Trigger recompile on "completed" workflow_job event matching workflow_job.name "bonsai-recompile" and workflow.name "bonsai" 
      ##
      when "workflow_job"
        if payload['action'] == "completed"
          if payload['workflow_job']['name'].downcase.strip == "bonsai-recompile" 
            CollectExtensionMetadataWorker.perform_async(@extension.id, [], current_user&.id)
          end
        end
      when "watch"
        ExtractExtensionStargazersWorker.perform_async(@extension.id)
      when "member"
        ExtractExtensionCollaboratorsWorker.perform_async(@extension.id)
      else
        Rails.logger.info '*** Github Error: unidentified event type'
    end
    head :ok
  end

  #
  # POST /assets/:username/:id/build
  #
  # Triggers a release build of the specified asset.
  # Returns one of the following HTTP status codes:
  #   2XX - Success
  #   401 - Invalid or missing X-GitHub-Token header
  #   403 - GitHub user not authorized for the specified asset
  #   404 - Unknown GitHub repo for the asset
  #
  # Requires an +X-GitHub-Token+ header containing a GitHub personal access token (PAT)
  # belonging to a user who is a collaborator on the project.
  # See https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token.
  # The header must use the +X-GitHub-Token+ key, as in:
  #   X-GitHub-Token: ${GITHUB_PERSONAL_ACCESS_TOKEN}
  #
  def build
    github_token = request.headers['X-GitHub-Token']
    status_code_symbol = with_collaborator_authorization(github_token, @extension) do
      CollectExtensionMetadataWorker.perform_async(@extension.id, [], current_user&.id)
    end

    head status_code_symbol
  end

  def select_default_version
    version = @extension.extension_versions.find_by(id: params[:extension_version_id])
    version_id = version.present? ? version.id : nil
    @extension.update_column(:selected_version_id, version_id)
    redirect_to owner_scoped_extension_url(@extension), notice: t("extension.default_version_selected")
  end

  def update_collection
    collection = Collection.find_by(id: params[:collection_id])
    if collection.present?
      if params[:update] == 'add'
        @extension.collections << collection
      elsif params[:update] == 'remove'
        @extension.collections.delete(collection)
      end
    end
    head :ok
  end

  def update_config_overrides
    config_overrides = {}
    params[:configs].each do |config|
      config.each do |input|
        next if input['key'].blank?
        config_overrides[ input['key'] ] = input['value']
      end
    end
    config_overrides.sort.to_h
    @extension.update(config_overrides: config_overrides)
  end

  def privacy
    @extension.update(privacy: !@extension.privacy)
    redirect_to owner_scoped_extension_url(@extension), notice: t("extension.privacy_changed")
  end

  private

  def qualify_scope(scope, params)
    if params[:q].present?
      # separate words so the results are based on word score
      scope = scope.search(params[:q].gsub('-', ' '))
    end

    if params[:featured].present?
      scope = scope.featured
    end

    if params[:tiers].present?
      # allow nil tier_id if default tier included
      params[:tiers] << nil if params[:tiers].include?(Tier.default.id.to_s)
      scope = scope.merge(Extension.where(tier_id: params[:tiers]))
    end

    if params[:order].present?
      scope = scope.ordered_by(params[:order])
    end

    if params[:order].blank? && params[:q].blank?
      scope = scope.order(deprecated: :asc, name: :asc)
    end

    if params[:supported_platform_id].present?
      scope = scope.supported_platforms([params[:supported_platform_id]])
    end

    if params[:archs]
      scope = scope.where(id: Extension.for_architectures(Array.wrap(params[:archs])))
    end

    if params[:platforms]
      scope = scope.where(id: Extension.for_platforms(Array.wrap(params[:platforms])))
    end

    if params[:owner_name]
      owner_name = params[:owner_name].gsub(/\s+/, "")
      scope = scope.where("owner_name ILIKE '%#{owner_name}%'")
    end

    return scope
  end

  def assign_extension
    @extension ||= begin
      Extension.with_owner_and_lowercase_name(owner_name: params[:username], lowercase_name: params[:id])
    rescue ActiveRecord::RecordNotFound
      extension = Extension.unscoped.with_name(params[:id]).first
      if extension && (current_user && (current_user == extension.owner || current_user.roles_mask > 0))
        @extension = extension
      else
        raise
      end
    end
  end

  def store_location_then_authenticate_user!
    store_location!(owner_scoped_extension_url(@extension))
    authenticate_user!(skip_location_storage: true)
  end

  def extension_edit_params
    params.require(:extension).permit(:source_url, :issues_url, :up_for_adoption, :tag_tokens, :name, :description)
  end

  def extension_deprecation_params
    params.require(:extension).permit(:replacement)
  end

  def render_follow_button
    # In order to refresh the follower count the extension must be
    # reloaded before rendering.
    @extension.reload

    partial_template = params[:list].present? ? 'follow_button_list' : 'follow_button_show'

    respond_to do |format|
      format.js   { render partial: partial_template, locals: { extension: @extension } }
      format.html { render partial: partial_template, locals: { extension: @extension } }
    end
  end

  # Attempts to authorize the GitHub user who corresponds to the given GitHub token
  # as having GitHub collaborator permissions for the given +Extension+ object.
  #
  # If the authorization succeeds, this method calls the given code block.
  #
  # Returns an HTTP status code symbol representing the success or failure of the authorization.
  #
  def with_collaborator_authorization(github_token, extension, &block)
    return :unknown      unless extension
    return :unauthorized unless github_token.present?

    repo_name = extension.github_repo
    return :unknown unless repo_name.present?

    github_client = Octokit::Client.new(client_id: ENV["GITHUB_CLIENT_ID"], client_secret: ENV["GITHUB_CLIENT_SECRET"])
    github_login_name = begin
                          github_client.user.login
                        rescue Octokit::Unauthorized
                          return :unauthorized
                        rescue
                          nil
                        end
    return :not_found unless github_login_name.present?

    # The GitHub user corresponding to the auth token must be a collaborator on the GitHub repo.
    is_collaborator = github_client.collaborator?(repo_name, github_login_name) rescue false
    return :forbidden unless is_collaborator

    # If this point is reached, we can call the given code block.
    block.call
    return :ok
  end
end
