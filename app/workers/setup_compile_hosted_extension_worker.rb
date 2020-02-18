class SetupCompileHostedExtensionWorker < ApplicationWorker
  
  def perform(extension_id, version_name='')
    
    extension = Extension.find(extension_id)

    extension.extension_versions.each do |version|
      next unless version.source_file.attached?
      CompileExtensionStatus.call(
        extension: extension,
        task: "Compile Version #{version.version}"
      )
      version.source_file.blob.analyze
    end
  end

end