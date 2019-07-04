class ActiveStorageCacheStore < ActiveSupport::Cache::Store
  private

  def read_entry(key, options)
    cache_item = ActiveStorage::CacheItem.find_by(key: key)
    return unless cache_item
    return unless cache_item.file.attached?

    Marshal.load(cache_item.file.download)
  end

  def write_entry(key, entry, options)
    cache_item = ActiveStorage::CacheItem.find_or_initialize_by(key: key)
    if cache_item.file.attached?
      cache_item.file.purge
    end

    cache_item.file.attach(io: StringIO.new(Marshal.dump(entry)), filename: 'n/a')
    cache_item.save
  end

  def delete_entry(key, options)
    cache_item = ActiveStorage::CacheItem.find_by(key: key)
    return unless cache_item

    if cache_item.file.attached?
      cache_item.file.purge
    end

    cache_item.destroy
  end
end
