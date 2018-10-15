class Tier < ApplicationRecord
  include RankedModel

  ranks :rank

  validates :name, presence: true, uniqueness: true
  validates :rank, presence: true, uniqueness: true
end
