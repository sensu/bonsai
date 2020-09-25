class SetupHostedExtensionWorker < ApplicationWorker

  def perform(extension_id, version_name)
  	extension = Extension.find(extension_id)

  	compile_context = CompileNewHostedExtension.call(extension: extension, version_name: version_name)

  end

end
