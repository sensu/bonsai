class EnsureUpdatedVersion
	include Interactor

	delegate :extension, 			to: :context
	delegate :tag_name, 			to: :context
	delegate :readme_body, 		to: :context 
	delegate :readme_ext, 		to: :context
	delegate :error_message,	to: :context
	delegate :command_run,		to: :context

	def call
		context.command_run = CmdAtPath.new(extension.repo_path)

		yml_line_count = command_run.cmd("find . -name '*.yml' -o -name '*.yaml' -print0 | xargs -0 wc -l")&.split("\n")&.last || ""
    rb_line_count = command_run.cmd("find . -name '*.rb' -print0 | xargs -0 wc -l")&.split("\n")&.last || ""

    yml_line_count = yml_line_count.strip.to_i
    rb_line_count = rb_line_count.strip.to_i

    version = extension.extension_versions.find_or_create_by(version: tag_name)

    version.update_columns(
    	readme: readme_body,
    	readme_extension: readme_ext,
      yml_line_count: yml_line_count,
      rb_line_count: rb_line_count
    )

    context.version = version
      
	end

end