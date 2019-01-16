require 'rails_helper'

RSpec.describe ActiveStorage::CacheItem, type: :model do
  subject { ActiveStorage::CacheItem.new }

  it {expect(subject).to be_valid}
end
