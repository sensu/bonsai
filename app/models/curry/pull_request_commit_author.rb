class Curry::PullRequestCommitAuthor < ApplicationRecord
  belongs_to :commit_author, required: false
  belongs_to :pull_request, required: false

  validates :commit_author_id, uniqueness: { scope: :pull_request_id }
end
