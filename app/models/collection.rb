class Collection < ApplicationRecord

  include RankedModel

	has_many :extension_collections
  has_many :extensions, through: :extension_collections
	belongs_to :user, optional: true

  ranks :row_order

  before_save :set_slug

  validates :title, presence: true, uniqueness: true

	private

  #
  # Sets the slug to the parameterized name of the +Collection+, if one doesn't
  # already exist
  #
  def set_slug
    self.slug = title.parameterize if slug.blank?
  end
end
