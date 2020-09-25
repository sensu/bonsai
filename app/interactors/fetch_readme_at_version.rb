class FetchReadmeAtVersion
	include Interactor

	delegate :extension, 			to: :context
	delegate :tag_name,				to: :context
	delegate :command_run,		to: :context
	delegate :file_extension,	to: :context
	delegate :body,						to: :context

	def call

		context.command_run = CmdAtPath.new(extension.repo_path)
		filename = command_run.cmd("ls README*")
		
		if filename.present?
      filename = filename.split("\n").first
      extract_file_extension(filename)
      context.body = command_run.cmd("cat '#{filename}'")
      context.body = body.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''})
    else
    	context.error = "There is no README file for the #{context.tag_name} #{I18n.t('nouns.extension')}."
    end

	end

	private

	def extract_file_extension(filename)
		match = filename.match(/\.[a-zA-Z0-9]+$/)
    context.file_extension = if match.present?
      match[0].gsub(".", "")
    else
      "txt"
    end
  end

end

