class SyncExtensionContentsAtVersionsWorker < ApplicationWorker
  include MarkdownHelper

  def perform(extension_id, tags, compatible_platforms = [], release_infos_by_tag = {}, current_user_id=nil)
    current_user = User.find_by(id: current_user_id)
    @extension = Extension.find_by(id: extension_id)
    raise RuntimeError.new("#{I18n.t('nouns.extension')} ID: #{extension_id.inspect} not found.") unless @extension

    # puts "PERFORMING #{@extension.name}: #{tags.join(', ')}"

    logger.info("PERFORMING: #{@extension.inspect}, #{tags.inspect}, #{compatible_platforms.inspect}")

    @errored_tags = []

    @extension.with_lock do
      @tags = tags
      @tag = @tags.shift
      @compatible_platforms = compatible_platforms
      @release_infos_by_tag = release_infos_by_tag
      @run = CmdAtPath.new(@extension.repo_path)

      if semver?
        release_info = release_infos_by_tag[@tag].to_h
        sync_extension_version(release_info, current_user)
        tally_commits if @tag == "master"
      end
    end
    CompileExtensionStatus.call(
      extension: @extension,
      worker: 'ExtractExtensionCollaboratorsWorker',
      job_id: ExtractExtensionCollaboratorsWorker.perform_async(@extension.id)
    )
    # update license in case it has changed
    CompileExtensionStatus.call(
      extension: @extension,
      worker: 'ExtractExtensionLicenseWorker',
      job_id: ExtractExtensionLicenseWorker.perform_async(@extension.id)
    )
    perform_next
  end

  def logger
    if Rails.env.production?
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/scan.log")
    end
  end

  private

  def sync_extension_version(release_info, current_user)
    checkout_correct_tag
    readme_body, readme_ext = fetch_readme
    logger.info "GOT README: #{readme_body}"
    puts "Got-readme"
    version = ensure_updated_version(readme_body, readme_ext)
    set_compatible_platforms(version)
    set_last_commit(version)
    set_commit_count(version)
    scan_files(version, current_user)
    sync_release_info(version, release_info)
    check_for_overrides(version)
    PersistAssets.call(version: version)
    update_annotations(version)
    version.save
  end

  def perform_next
    if @tags.any?
      self.class.perform_async(@extension.id, @tags, @compatible_platforms, @release_infos_by_tag)
    end
  end

  def semver?
    return true if @tag == "master"

    begin
      tag = SemverNormalizer.call(@tag)
      # puts "Normalized Tag: #{tag}"
      Semverse::Version.new(tag)
      return true
    rescue Semverse::InvalidVersionFormat => error
      unless @errored_tags.include?(@tag)
        @errored_tags << @tag
        compilation_error = [@extension.compilation_error, error.message]
        @extension.update_column(:compilation_error, compilation_error.compact.join('; '))
        message = "#{@extension.lowercase_name} release is invalid: #{error.message}"
        logger.info message
      end
      return false
    end
  end

  def checkout_correct_tag
    @run.cmd("git checkout #{@tag}")
    @run.cmd("git pull origin #{@tag}")
  end

  def fetch_readme
    filename = @run.cmd("ls README*")
    logger.info filename.inspect

    if filename.present?
      filename = filename.split("\n").first
      ext = extract_readme_file_extension(filename)
      body = @run.cmd("cat '#{filename}'")
      body = body.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
      return body, ext
    else
      return "There is no README file for this #{I18n.t('nouns.extension')}.", "txt"
    end
  end

  def check_for_overrides(version)
    return if version.blank?
    version_overrides = version.config["overrides"].nil? ? {} : version.config["overrides"][0]
    extension_overrides = version.extension.config_overrides
    if version_overrides.present?  && version_overrides["readme_url"].present?
      override_readme(version, version_overrides["readme_url"])
    elsif extension_overrides["readme_url"].present?
      override_readme(version, extension_overrides["readme_url"])
    end
  end

  def override_readme(version, readme_url)

    message = []

    begin
      url = URI.parse(readme_url)
    rescue URI::Error => error
      logger.info "URI error: #{readme_url} - #{error.message}"
      return
    end

    readme_ext = File.extname(url.path).gsub(".", "")
    unless ExtensionVersion::MARKDOWN_EXTENSIONS.include?(readme_ext)
      message << "#{version.version} override readme_url is not a valid markdown file."
    end

    # resconstruct Github url to get file, not html
    # https://github.com/jspaleta/sensu-plugins-redis/blob/master/README.md
    # should translate to
    # https://raw.githubusercontent.com/jspaleta/sensu-plugins-redis/master/README.md

    if ['github.com', 'www.github.com'].include?(url.host)
      url.host = "raw.githubusercontent.com"
      url.path.gsub!('/blob', '')
    end

    # get file contents
    begin
      file = url.open
    rescue OpenURI::HTTPError => error
      status = error.io.status
      message << "#{version.version} #{url.path} file read error: #{status[0]} - #{status[1]}"
      logger.info message.compact.join('; ')
      compilation_error = [version.compilation_error] + message
      version.update_column(:compilation_error, compilation_error.compact.join('; '))
      return
    end

    readme = file.read

    if readme.include?('!DOCTYPE html')
      message << "#{version.version} override readme is not valid markdown."
    end

    begin
      filter = HTML::Pipeline.new [
          HTML::Pipeline::MarkdownFilter,
        ], {gfm: true}
      filter.call(readme)
    rescue
      message << "#{version.version} override readme is not valid markdown."
    end

    if message.present?
      compilation_error = [version.compilation_error] + message
      compilation_error.compact!
      if compilation_error.present?
        compilation_error = compilation_error.join('; ')
        version.update_column(:compilation_error, compilation_error)
      end
    else

      readme = readme.encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')

      version.update(
        readme: readme,
        readme_extension: readme_ext
      )
      logger.info "OVERRIDE README: #{url.path}"
    end
  end

  def extract_readme_file_extension(filename)
    if match = filename.match(/\.[a-zA-Z0-9]+$/)
      match[0].gsub(".", "")
    else
      "txt"
    end
  end

  def ensure_updated_version(readme_body, readme_ext)
    yml_line_count = @run.cmd("find . -name '*.yml' -o -name '*.yaml' -print0 | xargs -0 wc -l")&.split("\n")&.last || ""
    rb_line_count = @run.cmd("find . -name '*.rb' -print0 | xargs -0 wc -l")&.split("\n")&.last || ""

    yml_line_count = yml_line_count.strip.to_i
    rb_line_count = rb_line_count.strip.to_i

    @extension.extension_versions.where(version: @tag).first_or_create!.tap do |version|
      version.update_attributes(
        readme: readme_body,
        readme_extension: readme_ext,
        yml_line_count: yml_line_count,
        rb_line_count: rb_line_count
      )
    end
  end

  def set_compatible_platforms(version)
    unless version.supported_platforms.any?
      version.supported_platform_ids = @compatible_platforms
    end
    rescue PG::UniqueViolation
  end

  def set_last_commit(version)
    commit = @run.cmd("git log -1")
    # no response from tmp repo
    return if commit.blank?

    commit.gsub!(/^Merge: [^\n]+\n/, "")
    sha, author, date = *commit.split("\n")

    unless message = commit.split("\n\n").last
      # Empty repo; no commits
      return
    end

    message = message.gsub("\n", " ").strip
    sha = sha.gsub("commit ", "")
    date = Time.parse(date.gsub("Date:", "").strip)
    version.last_commit_sha = sha
    version.last_commit_at = date
    version.last_commit_string = message
    version.last_commit_url = version.extension.github_url + "/commit/#{sha}"
  end

  def set_commit_count(version)
    version.commit_count = @run.cmd("git shortlog | grep -E '^[ ]+\\w+' | wc -l").to_s.strip.to_i
    logger.info "COMMIT COUNT: #{version.commit_count}"
  end

  def scan_files(version, current_user)
    version.extension_version_content_items.destroy_all
    logger.info("SCANNING FILES")
    scan_config_yml_file(version, current_user)
    scan_yml_files(version)
    scan_class_dirs(version)
  end

  def sync_release_info(version, release_info)
    version.release_notes = release_info['body']
  end

  def scan_yml_files(version)
    @run.cmd("find . -name '*.yml' -o -name '*.yaml'").tap { |r| logger.info("YAML FILES: #{r.inspect}") }.split("\n").each do |path|
      logger.info("SCANNING: #{path}")
      body = @run.cmd("cat '#{path}'")
      path = path.gsub("./", "")

      type = if body["MiqReport"]
        "Report"
      elsif body["MiqPolicySet"]
        "Policy"
      elsif body["MiqAlert"]
        "Alert"
      elsif body["dialog_tabs"]
        "Dialog"
      elsif body["MiqWidget"]
        "Widget"
      elsif body["CustomButtonSet"]
        "Button Set"
      end

      next if type.nil?

      logger.info version.extension_version_content_items.where(path: path).first_or_create!(
        name: path.gsub(/.+\//, ""),
        item_type: type,
        github_url: version.extension.github_url + "/blob/#{version.version}/#{CGI.escape(path)}"
      ).inspect
    end
  end

  def scan_config_yml_file(version, current_user, system_command_runner=@run)
    compilation_result = CompileGithubExtensionVersionConfig.call(
      current_user:          current_user,
      version:               version,
      system_command_runner: system_command_runner
    )

    if compilation_result.success? && compilation_result.data_hash.present? && compilation_result.data_hash.is_a?(Hash)
      version.update_columns(
        config: compilation_result.data_hash,
        compilation_error: nil
      )
      version.update_column(:compilation_error, "test")
    elsif compilation_result.error.present?
      version.update_column(:compilation_error, compilation_result.error)
    else
      version.update_column(:compilation_error, "Compile Github Extension Version ID #{version.id} Config failed.")
    end
  end

  def scan_class_dirs(version)
    @run.cmd("find . -name '*.class'").tap { |r| logger.info("RB FILES: #{r.inspect}") }.split("\n").each do |path|
      logger.info("SCANNING: #{path}")
      logger.info version.extension_version_content_items.where(path: path).first_or_create!(
        name: path.gsub(/.+\//, ""),
        item_type: "Class",
        github_url: version.extension.github_url + "/blob/#{version.version}/#{path}"
      ).inspect
    end
  end

  def tally_commits
    commits = @run.cmd("git --no-pager log --format='%H|%ad'")

    commits.split("\n").each do |c|
      sha, date = c.split("|")

      CommitSha.transaction do
        if !CommitSha.where(sha: sha).first
          CommitSha.create(sha: sha)
          DailyMetric.increment(@extension.commit_daily_metric_key, 1, date.to_date)
        end
      end
    end
  end

  def update_annotations(version)
    config_hash = version.config
    if config_hash['annotations'].present?
      prefix = ExtensionVersion::ANNOTATION_PREFIX
      updated_annotations = {}
      config_hash['annotations'].each do |key, value|
        key = "#{prefix}.#{key}" unless key.start_with?(prefix)
        updated_annotations[key] = value
      end
      config_hash['annotations'] = updated_annotations
      version.update_column(:config, config_hash)
      version.update_column(:annotations, updated_annotations)
    end
  end

end
