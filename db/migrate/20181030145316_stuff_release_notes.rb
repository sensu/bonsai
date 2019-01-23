class StuffReleaseNotes < ActiveRecord::Migration[5.2]
  def change
    ExtensionVersion.find_each do |ev|
      ev.update(release_notes: ev.description)
    end
  end
end
