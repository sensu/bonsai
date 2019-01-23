class Tier < ApplicationRecord
  include RankedModel

  ranks :rank

  has_many :raw_extensions, foreign_key: 'tier_id', class_name: 'Extension', dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :rank, presence: true, uniqueness: true

  def self.default
    Tier.rank(:rank).first || Tier.new(name: 'No', rank: 0)
  end

  # Extensions having a nil tier are considered members of the default tier.
  def extensions
    if self != self.class.default
      return raw_extensions
    end

    # If this point is reached, then this +Tier+ is the default tier, so its extensions
    # include all extensions that have no specific tier (i.e. have a nil tier).
    tier_id = Extension.arel_table[:tier_id]
    Extension.where(tier_id.eq(nil).or(tier_id.eq(self.id)))
  end
end
