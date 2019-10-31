require 'spec_helper'

RSpec.describe ExtensionCollection, type: :model do
  context 'associations' do
  	it { should belong_to(:extension) }
    it { should belong_to(:collection) }
    #it { should belong_to(:user) }
  end
end
