class Tagging < ApplicationRecord
  belongs_to :taggable, polymorphic: true, required: false
  belongs_to :tag, required: false

  def self.add(name)
    create(tag: Tag.where(name: name.strip).first_or_create)
  end
end
