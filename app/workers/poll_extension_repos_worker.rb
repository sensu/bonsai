class PollExtensionReposWorker < ApplicationWorker

  # include Sidetiq::Schedulable

  # recurrence { daily }

  def perform(current_user_id=nil)
    Extension.where("updated_at < ?", Time.now - 24.hours).each do |extension|
      CollectExtensionMetadataWorker.perform_async(extension.id, [], current_user_id)
    end
  end
end
