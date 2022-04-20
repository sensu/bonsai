class AddMostRecentValidGithubTokenToExtension < ActiveRecord::Migration[5.2]
  def change
    add_column :extensions, :most_recent_valid_github_token, :string
  end
end
