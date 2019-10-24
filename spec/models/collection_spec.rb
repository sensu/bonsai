require 'spec_helper'

RSpec.describe Collection, type: :model do
  context 'associations' do
    it { should have_many(:extension_collections) }
    it { should have_many(:extensions) }
  end

  context 'slugs' do
    it 'should automatically add a slug before saving' do
      c = create(:collection, title: 'Test Category', slug: '')
      expect(c.slug).to eql('test-category')
    end
  end

  context 'validation' do 
  	describe 'title' do 
  		it { should validate_presence_of(:title) }
  	end
  end
end
