class CompileGithubOverrides
	include Interactor

	delegate :extension, to: :context
	delegate :version, 		to: :context 

	def call

		version_overrides = version.config["overrides"].nil? ? {} : version.config["overrides"][0]
    extension_overrides = extension.config_overrides

    # readme overrides
    if version_overrides.present?  && version_overrides["readme_url"].present?
      override_readme(version_overrides["readme_url"])
    elsif extension_overrides["readme_url"].present?
      override_readme(extension_overrides["readme_url"])
    end

	end

	private

	def override_readme(readme_url)

    message = []

    begin
      url = URI.parse(readme_url)
    rescue URI::Error => error
    	context.fail!( error: "URI error: #{readme_url} - #{error.message}")
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
      compilation_error = ([version.compilation_error] + message).compact
      version.update_column(:compilation_error, compilation_error.join('; '))
      context.fail!(error: compilation_error.join('; '))
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
      compilation_error =([version.compilation_error] + message).compact
      if compilation_error.present?
        version.update_column(:compilation_error, compilation_error.join('; '))
        context.fail!(error: compilation_error.join('; '))
      end
    else

      readme = readme.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''})

      version.update_columns(
        readme: readme,
        readme_extension: readme_ext
      )
    end
  end

end