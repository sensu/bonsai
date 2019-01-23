# If you change this list, also update the +ExtensionVersion.pick_blob_analyzer method.

Rails.application.config.active_storage.analyzers.prepend TarBallAnalyzer
Rails.application.config.active_storage.analyzers.prepend ZipFileAnalyzer
