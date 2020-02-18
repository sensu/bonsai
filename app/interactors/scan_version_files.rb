class ScanVersionFiles
	include Interactor

	delegate :extension, 			to: :context
	delegate :version,				to: :context
	delegate :command_run,		to: :context

	def call
		context.command_run = CmdAtPath.new(extension.repo_path)

    # remove existing content items
		version.extension_version_content_items.delete_all

    scan_config_yml_file
    scan_yml_files
    scan_class_dirs

	end

	private

	def scan_config_yml_file

    compilation_context = CompileGithubExtensionVersionConfig.call(
    	extension: extension, 
    	version: version
    )
    if compilation_context.success? && compilation_context.config_hash.present?
      version.update_columns(
        config: compilation_context.config_hash,
        compilation_error: nil
      )
    elsif compilation_context.error.present?
      version.update_column(:compilation_error, compilation_context.error)
    else
      message = "Compile Github Extension Version #{version.version} Config failed."
      version.update_column(:compilation_error, message)
      context.fail!(error: message)
    end
  end

  def scan_yml_files
    yml_files = command_run.cmd("find . -name '*.yml' -o -name '*.yaml'").split("\n")

    yml_files.each do |path|
      
      body = command_run.cmd("cat '#{path}'")
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

      version.extension_version_content_items.create(
        path: path,
        name: path.gsub(/.+\//, ""),
        item_type: type,
        github_url: extension.github_url + "/blob/#{version.version}/#{CGI.escape(path)}"
      )
      
    end
  end

  def scan_class_dirs
    dirs = command_run.cmd("find . -name '*.class'").split("\n")

    dirs.each do |path|
      version.extension_version_content_items.create!(
        path: path,
        name: path.gsub(/.+\//, ""),
        item_type: "Class",
        github_url: extension.github_url + "/blob/#{version.version}/#{path}"
      )
    end
  end


end
	