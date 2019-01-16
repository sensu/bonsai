require 'spec_helper'

describe ActiveStorageCacheStore do
  let(:blob_hash)  { {
    io:           StringIO.new(Marshal.dump('hi there')),
    filename:     'n/a'
  } }
  let(:blob)       { ActiveStorage::Blob.create_after_upload! blob_hash }
  let(:key)        { 'some-key' }
  let(:cache_item) { ActiveStorage::CacheItem.create(key: key) }

  subject { ActiveStorageCacheStore.new }

  describe '#read_entry' do
    context 'when given an unknown key' do
      it 'returns nil' do
        expect(subject.send(:read_entry, 'unknown', {})).to be_nil
      end
    end

    context 'when cache item has no attached file' do
      it 'returns nil' do
        expect(subject.send(:read_entry, key, {})).to be_nil
      end
    end

    context 'when cache item has an attached file' do
      before do
        cache_item.file.attach(blob)
      end

      it 'returns a string of file contents' do
        result = subject.send(:read_entry, key, {})
        expect(result).to eql 'hi there'
      end
    end
  end

  describe '#write_entry' do
    context 'when given an existing key' do
      before do
        subject.send(:write_entry, key, 'existing', {})
        expect(subject.send(:read_entry, key, {})).to eql 'existing'
      end

      it 'replaces the content of the existing cache item without creating a new one' do
        expect {
          subject.send(:write_entry, key, 'new content', {})
        }.not_to change(ActiveStorage::CacheItem, :count)
        expect(subject.send(:read_entry, key, {})).to eql 'new content'
      end
    end

    context 'when given an unknown key' do
      let(:key) { 'new key' }

      it 'creates a new cache item' do
        expect {
          subject.send(:write_entry, key, 'content for new key', {})
        }.to change(ActiveStorage::CacheItem, :count).by(1)
        expect(subject.send(:read_entry, key, {})).to eql 'content for new key'
      end
    end
  end

  describe '#delete_entry' do
    context 'when given an unknown key' do
      it 'does nothing' do
        expect {
          expect(subject.send(:delete_entry, 'unknown', {})).to be_nil
        }.not_to change(ActiveStorage::CacheItem, :count)
      end
    end

    context 'when given an existing key' do
      before do
        subject.send(:write_entry, key, 'existing', {})
      end

      it 'deletes the existing cache item' do
        expect {
          subject.send(:delete_entry, key, {})
        }.to change(ActiveStorage::CacheItem, :count).by(-1)
        expect(subject.send(:read_entry, key, {})).to be_nil
      end
    end
  end
end
