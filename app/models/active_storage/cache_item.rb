class ActiveStorage::CacheItem < ApplicationRecord
  has_one_attached :file
end
