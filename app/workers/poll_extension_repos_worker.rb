class PollExtensionReposWorker < ApplicationWorker

  # include Sidetiq::Schedulable

  # recurrence { daily }

  def perform
    Extension.where("updated_at < ?", Time.now - 24.hours).each do |extension|
      CollectExtensionMetadataWorker.perform_async(extension)
    end
  end
end
