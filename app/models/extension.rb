class Extension < ApplicationRecord
  include PgSearch

  CONFIG_FILE_NAMES = %w[
      bonsai.yml
      bonsai.yaml
      .bonsai.yml
      .bonsai.yaml
    ]

  # Associations
  # --------------------
  belongs_to :category, required: false
  belongs_to :owner, class_name: 'User', foreign_key: :user_id, required: false
  belongs_to :github_organization, required: false
  belongs_to :parent, class_name: 'Extension', foreign_key: :parent_id, required: false
  belongs_to :replacement, class_name: 'Extension', foreign_key: :replacement_id, required: false
  belongs_to :raw_tier, class_name: "Tier", foreign_key: "tier_id", required: false
  belongs_to :selected_version, class_name: "ExtensionVersion", foreign_key: :selected_version_id, required: false
  has_one :github_account, through: :owner
  has_one :newest_extension_version, -> { order("created_at DESC") }, class_name: "ExtensionVersion"
  has_many :all_supported_platforms, through: :extension_versions, class_name: 'SupportedPlatform', source: :supported_platforms
  has_many :collaborators, as: :resourceable, dependent: :destroy
  has_many :collaborator_users, through: :collaborators, source: :user
  has_many :extension_versions, dependent: :destroy
  has_many :extension_followers
  has_many :followers, through: :extension_followers, source: :user
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :forks, class_name: 'Extension', foreign_key: :parent_id
  has_many :extension_collections, dependent: :destroy 
  has_many :collections, through: :extension_collections

  # HACK: +Extension+ objects don't really have a source_file attachment or version attribute.
  # Instead, the children extension_versions each has their own individual +source_file+ attachment and version attribute.
  # We only use this attachment on the +Extension+ and the +version+ attribute as temporaries until we
  # can transfer the blob and version to the associated +ExtensionVersion+ child.
  # To remove this hack, we should either use a form object to hold the temporaries, or
  # establish an +accepts_nested_attributes+ relationship with the associated extension_versions.
  has_one_attached :tmp_source_file
  attr_accessor :version

  serialize :config_overrides, Hash

  default_scope { where(enabled: true) }

  #
  # Query extensions by case-insensitive name.
  #
  # @param name [String, Array<String>] a single name, or a collection of names
  #
  # @example
  #   Extension.with_name('redis').first
  #     #<Extension name: "redis"...>
  #   Extension.with_name(['redis', 'apache2']).to_a
  #     [#<Extension name: "redis"...>, #<Extension name: "apache2"...>]
  #
  # @todo: query and index by +LOWER(name)+ when ruby schema dumps support such
  #   a thing.
  #
  scope :with_name, lambda { |names|
    lowercase_names = Array(names).map { |name| name.to_s.downcase.parameterize }

    where(lowercase_name: lowercase_names)
  }

  scope :ordered_by, lambda { |ordering|
    return by_most_downloaded if ordering == 'most_downloaded'
    reorder({
      'recently_updated' => 'updated_at DESC',
      'recently_added' => 'id DESC',
      #'most_downloaded' => "(web_download_count + api_download_count) DESC, id ASC",
      'most_followed' => 'extension_followers_count DESC, id ASC'
    }.fetch(ordering, 'name ASC'))
  }

  scope :by_most_downloaded, -> {
    select('web_download_count + api_download_count AS count_total, extensions.*')
    .order('count_total DESC, id ASC')
  }

  scope :owned_by, lambda { |username|
    joins(owner: :github_account).where('accounts.username = ?', username)
  }

  scope :in_namespace, lambda { |namespace|
    where(owner_name: namespace)
  }

  scope :supported_platforms, lambda { |sp_ids|
    joins(:all_supported_platforms).where('supported_platforms.id IN (?)', sp_ids)
  }

  scope :as_index, lambda { |opts = {}|
    includes(:extension_versions, owner: :github_account)
    .ordered_by(opts.fetch(:order, 'name ASC'))
    .limit(opts.fetch(:limit, 10))
    .offset(opts.fetch(:start, 0))
  }

  scope :featured, -> { where(featured: true) }
  scope :hosted, -> { where("COALESCE( TRIM(github_url), '') = ''") }
  scope :not_hosted, -> { where("COALESCE( TRIM(github_url), '') != ''") }

  scope :for_architectures, ->(archs) { joins(:extension_versions).merge(ExtensionVersion.for_architectures(archs)).distinct }
  scope :for_platforms, ->(platforms) { joins(:extension_versions).merge(ExtensionVersion.for_platforms(platforms)).distinct }

  # Search
  # --------------------
  pg_search_scope(
    :search,
    against: {lowercase_name: 'A', owner_name: 'B'},
    associated_against: {
      tags: [:name],
      github_account: [:username],
      extension_versions: [:description]
    },
    ranked_by: "((CAST(NOT extensions.deprecated AS INT) * 10), (CAST(extensions.owner_name IN (#{ENV.fetch('HOST_PREFERRED_OWNER_NAMES',"''")}) AS INT) * 10) + :tsearch)", # ensure deprecated extensions are always listed last and preferred owner_names first.
    order_within_rank: 'extensions.owner_name, extensions.name',
    using: {
      tsearch: {
        prefix: true,
        any_word: false,
        normalization: 16,
      }
    }
  )

  # Callbacks
  # --------------------
  before_validation :copy_name_to_lowercase_name, on: :create
  before_validation :normalize_github_url
  before_save :update_tags

  # Delegations
  # --------------------
  delegate :foodcritic_failure, to: :latest_extension_version, allow_nil: true
  delegate :foodcritic_feedback, to: :latest_extension_version, allow_nil: true
  delegate :name,                to: :tier, allow_nil: true, prefix: true
  delegate :icon_name,           to: :tier, allow_nil: true, prefix: true
  delegate :id,                  to: :tier, allow_nil: true, prefix: true
  delegate :oauth_token,         to: :github_account, allow_nil: true, prefix: true

  # Validations
  # --------------------
  validates :name, presence: true, uniqueness: { scope: :owner_name, case_sensitive: false, message: "already exists in this namespace" }, format: /\A[\w\s_-]+\z/i
  # validates :extension_versions, presence: true
  validates :source_url, url: {
    allow_blank: true,
    allow_nil: true
  }
  validates :issues_url, url: {
    allow_blank: true,
    allow_nil: true
  }
  validates :replacement, presence: true, if: :deprecated?
  validates :tmp_source_file, file_content_type: {
    allow:   TarBallAnalyzer::MIME_TYPES + ZipFileAnalyzer::MIME_TYPES,
    message: ': upload file must be a compressed archive type'
  }, if: ->(record) { record.tmp_source_file&.attachment }

  class << self 

    def with_owner_and_lowercase_name(owner_name:, lowercase_name:)
      Extension.find_by!(owner_name: owner_name, lowercase_name: lowercase_name)
    end

    def filter_private(current_user)
      if current_user.present?
        user_names = current_user.accounts.for(:github).map(&:username)
        where("COALESCE(extensions.privacy, false) = false OR extensions.owner_name = ?", user_names)
      else
        where("COALESCE(extensions.privacy, false) = false")
      end
    end

    #
    # The total number of times an extension has been downloaded from this application
    #
    # @return [Fixnum]
    #
    def total_download_count
      sum(:api_download_count) + sum(:web_download_count)
    end

  end # class << self

  #
  # Sorts extension versions according to their semantic version
  #
  # @return [Array<ExtensionVersion>] the sorted ExtensionVersion records
  #
  def sorted_extension_versions
    # ignore preceding 'V' and ignore 'master' so it sorts to end
    # convert version to array of integers so 10.0.0 comes after 9.0.0

    # Hack for regex issue on postgres - plus sign not escaping properly
    @sorted_extension_versions = extension_versions.order(
      Arel.sql(
        "STRING_TO_ARRAY(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                extension_versions.version, 
                E'[-](.*)', ''
              ), 
             E'[\+](.*)', ''
            ),
            E'V|v|master', ''
           )
        , '.')::bigint[] DESC ".gsub(/\s+/, " ")
      )
    )

    @sorted_extension_versions.limit(1).map(&:id) # executes query to test postgres regex
    @sorted_extension_versions
    rescue ActiveRecord::StatementInvalid => error
      @sorted_extension_versions = extension_versions.order(Arel.sql("STRING_TO_ARRAY(extension_versions.version, '.') DESC"))
  end

  #
  # Form placeholder.
  # @return [String]
  #
  attr_accessor :tag_tokens
  attr_accessor :github_url_short

  def tag_tokens
    @tag_tokens ||= tags.map(&:name).join(", ")
  end

  #
  # Form placeholder.
  # @return [Array]
  #
  attr_accessor :compatible_platforms

  #
  # Returns an array of users to whom this extension can be transferred.
  #
  # @return [Array] array of users who may receive ownership
  #
  def transferrable_to_users
    collaborator_users.where.not(id: user_id)
  end

  #
  # Transfers ownership of this extension to someone else.
  #
  # @param initiator [User] the User initiating the transfer
  # @param recipient [User] the User to assign ownership to
  #
  # @return [String] a key representing a message to display to the user
  #
  def transfer_ownership(recipient)
    update_attribute(:user_id, recipient.id)
    'extension.ownership_transfer.done'
  end

  #
  # The most recent ExtensionVersion, based on the semantic version number
  #
  # @return [ExtensionVersion] the most recent ExtensionVersion
  # exclude master and any non-semvar compliant versions
  # only use pre-release versions if no others
  #
  def latest_extension_version
    versions = remove_non_semvar_versions
    versions = remove_pre_release_versions(versions)
    if versions.blank?
      # include pre-release versions
      versions = remove_non_semvar_versions
    end
    if versions.blank?
      # use the non-compliant versions as last resort
      versions = sorted_extension_versions
    end
    versions.first
  end
  alias_method :latest_version, :latest_extension_version

  def remove_pre_release_versions(versions=nil)
    versions ||= sorted_extension_versions
    versions.reject { |v|
      Semverse::Version.new(SemverNormalizer.call(v.version)).pre_release?
    }
  end

  def remove_non_semvar_versions(versions=nil)
    versions ||= sorted_extension_versions
    versions.select { |v|
      Semverse::Version.new(SemverNormalizer.call(v.version)) rescue false
    }
  end

  #
  # Return all of the extension errors as well as full error messages for any of
  # the ExtensionVersions
  #
  # @return [Array<String>] all the error messages
  #
  def seriously_all_of_the_errors
    messages = errors.full_messages.reject { |e| e == "#{I18n.t('nouns.extension').capitalize} version is invalid" }

    extension_versions.each do |version|
      almost_everything = version.errors.full_messages.reject { |x| x =~ /Tarball can not be/ }
      messages += almost_everything
    end

    messages
  end

  #
  # Returns the name of the +Extension+ parameterized.
  #
  # @return [String] the name of the +Extension+ parameterized
  #
  def to_param
    lowercase_name.parameterize
  end

  #
  # Return the specified +ExtensionVersion+. Raises an
  # +ActiveRecord::RecordNotFound+ if the version does not exist. Versions can
  # be specified with either underscores or dots.
  #
  # @example
  #   extension.get_version!("1_0_0")
  #   extension.get_version!("1.0.0")
  #   extension.get_version!("latest")
  #
  # @param version [String] the version of the Extension to find. Pass in
  #                         'latest' to return the latest version of the
  #                         extension.
  #
  # @return [ExtensionVersion] the +ExtensionVersion+ with the version specified
  #
  def get_version!(version)
    version.gsub!('_', '.')

    if version == 'latest'
      latest_extension_version
    else
      extension_versions.find_by!(version: version)
    end
  end

  #
  # Saves a new version of the extension as specified by the given metadata, tarball
  # and readme. If it's a new extension the user specified becomes the owner.
  #
  # @raise [ActiveRecord::RecordInvalid] if the new version fails validation
  # @raise [ActiveRecord::RecordNotUnique] if the new version is a duplicate of
  #   an existing version for this extension
  #
  # @return [ExtensionVersion] the Extension Version that was published
  #
  # @param params [ExtensionUpload::Parameters] the upload parameters
  #
  def publish_version!(params)
    metadata = params.metadata

    #if metadata.privacy &&
    #    ENV['ENFORCE_PRIVACY'].present? &&
    #    ENV['ENFORCE_PRIVACY'] == 'true'
    #  errors.add(:base, I18n.t('api.error_messages.privacy_violation'))
    #  raise ActiveRecord::RecordInvalid.new(self)
    #end

    tarball = params.tarball
    readme = params.readme
    changelog = params.changelog

    dependency_names = metadata.dependencies.keys
    existing_extensions = Extension.with_name(dependency_names)

    extension_version = nil

    transaction do
      extension_version = extension_versions.build(
        extension: self,
        description: metadata.description,
        license: metadata.license,
        version: metadata.version,
        tarball: tarball,
        readme: readme.contents,
        readme_extension: readme.extension,
        changelog: changelog.contents,
        changelog_extension: changelog.extension
      )


      self.updated_at = Time.now

      [:source_url, :issues_url].each do |url|
        url_val = metadata.send(url)

        if url_val.present?
          write_attribute(url, url_val)
        end
      end

      #self.privacy = metadata.privacy
      save!

      metadata.platforms.each do |name, version_constraint|
        extension_version.add_supported_platform(name, version_constraint)
      end

      metadata.dependencies.each do |name, version_constraint|
        extension_version.extension_dependencies.create!(
          name: name,
          version_constraint: version_constraint,
          extension: existing_extensions.find { |c| c.name == name }
        )
      end
    end

    extension_version
  end

  #
  # Returns true if the user passed follows the extension.
  #
  # @return [TrueClass]
  #
  # @param user [User]
  #
  def followed_by?(user)
    extension_followers.where(user: user).any?
  end

  #
  # Returns the platforms supported by the latest version of this extension.
  #
  # @return [Array<SupportedVersion>]
  #
  def supported_platforms
    latest_extension_version.try(:supported_platforms) || []
  end

  #
  # Returns the dependencies of the latest version of this extension.
  #
  # @return [Array<ExtensionDependency>]
  #
  def extension_dependencies
    latest_extension_version.try(:extension_dependencies) || []
  end

  #
  # Returns all of the ExtensionDependency records that are contingent upon this one.
  #
  # @return [Array<ExtensionDependency>]
  #
  def contingents
    ExtensionDependency.includes(extension_version: :extension)
      .where(extension_id: id)
      .sort_by do |cd|
        [
          cd.extension_version.extension.name,
          Semverse::Version.new(SemverNormalizer.call(cd.extension_version.version))
        ]
      end
  end

  #
  # The username of this extension's owner
  #
  # @return [String]
  #
  def maintainer
    owner.username
  end

  #
  # The total number of times this extension has been downloaded
  #
  # @return [Fixnum]
  #
  def download_count
    web_download_count + api_download_count
  end

  #
  # Sets the extension's deprecated attribute to true, assigns the replacement
  # extension if specified and saves the extension.
  #
  # An extension can only be replaced with an extension that is not deprecated.
  #
  # @param replacement_extension [Extension] the extension to succeed this extension
  #   once deprecated
  #
  # @return [Boolean] whether or not the extension was successfully deprecated
  #   and  saved
  #
  def deprecate(replacement_extension)
    if replacement_extension.deprecated?
      errors.add(:base, I18n.t('extension.deprecate_with_deprecated_failure'))
      return false
    else
      self.deprecated = true
      self.replacement = replacement_extension
      save
    end
  end

  #
  # Searches for extensions based on the +query+ parameter. Returns results that
  # are elgible for deprecation (not deprecated and not this extension).
  #
  # @param query [String] the search term
  #
  # @return [Array<Extension> the +Extension+ search results
  #
  def deprecate_search(query)
    Extension.where("extensions.lowercase_name ILIKE '#{query}%'").where(deprecated: false).where.not(id: self.id).order(:lowercase_name, :owner_name)
  end

  #
  # Returns the username/repo formatted name of the GitHub repo.
  #
  # @return [String]
  #
  def github_repo
    self.github_url&.gsub("https://github.com/", "")
  end

  #
  # Returns the file system path where the repo is stored for syncing.
  #
  # @return [String]
  #
  def repo_path
    @repo_path ||= "/tmp/extension-repo-#{id}"
  end

  #
  # Returns an Octokit client configured for the Extension's owner.
  #
  # @return [Ocotkit::Client]
  #
  def octokit
    @octokit ||= octokit_client(github_oauth_token)
  end

  def commit_daily_metric_key
    @commit_daily_metric_key ||= "commits.extension-#{id}"
  end

  def hosted?
    github_repo.blank?
  end

  # We allow the referenced +Tier+ to be nil,
  # in which case we assume this extension has the default tier.
  def tier
    raw_tier || Tier.default
  end

  def namespace
    owner_name
  end

  def name_with_namespace
    "#{owner_name}/#{name}"
  end

  def github_oauth_token(current_user=nil)
    valid_token = [
      github_account_oauth_token,
      most_recent_valid_github_token,
      current_user&.github_account_oauth_token,
    ].find { |token| token.present? && is_valid_github_token?(token) }

    if valid_token && valid_token != most_recent_valid_github_token
      puts "***** GitHub auth token change"
      update(most_recent_valid_github_token: valid_token)
    end

    most_recent_valid_github_token
  end

  def github_url_with_auth(current_user=nil)
    auth_token = github_oauth_token(current_user)
    return github_url unless auth_token.present?

    uri          = URI.parse(github_url)
    uri.user     = 'x-oauth-basic'
    uri.password = auth_token

    uri.to_s
  end

  private

  def is_valid_github_token?(token)
    !!octokit_client(token).user
  rescue
    false
  end

  def octokit_client(auth_token)
    Octokit::Client.new(
      client_id:     Rails.configuration.octokit.client_id,
      client_secret: Rails.configuration.octokit.client_secret
    )
  end

  #
  # Populates the +lowercase_name+ attribute.
  #
  # Prefers to use the GitHub repo name, or if that is not available, use the lowercase +name+.be
  #
  # This exists until Rails schema dumping supports Posgres's expression
  # indices, which would allow us to create an index on LOWER(name). To do that
  # now, we'd have to use the raw SQL schema dumping functionality, which is
  # less-than ideal
  #
  def copy_name_to_lowercase_name
    self.lowercase_name = File.basename(self.github_url.to_s).presence || name.to_s.downcase.parameterize
  end

  #
  # Normalizes the GitHub URL to a standard format.
  #
  def normalize_github_url
    return if self.github_url.blank?

    url = self.github_url || ""
    url.gsub!(/(https?:\/\/)?(www\.)?github\.com\//, "")
    self.github_url = "https://github.com/#{url}"
    true
  end

  def update_tags
    self.tags = self.tag_tokens.split(",").map(&:downcase).map do |token|
      Tag.where(name: token.strip).first_or_create
    end
    true
  end

end
