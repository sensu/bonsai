require 'spec_helper'

describe UsersHelper do
  describe '#gravatar_for' do
    it "returns the image tag for the specified user's gravatar image" do
      user = create(:user, email: 'johndoe@example.com')
      expect(gravatar_for(user)).to match(/https\:\/\/secure.gravatar.com\/avatar\/fd876f8cd6a58277fc664d47ea10ad19/)
    end

    it "returns the image tag for the specified user's gravtar image with size" do
      user = create(:user, email: 'johndoe@example.com')
      expect(gravatar_for(user, size: 128)).to match(/https\:\/\/secure.gravatar.com\/avatar\/fd876f8cd6a58277fc664d47ea10ad19/)
    end

    it "returns the hosted organization image tag for user" do 
      user = User.host_organization
      expect(gravatar_for(user, size: 48)).to  match(/\/web-assets\//)
    end

    it "returns the hosted organization image tag for hosted" do 
      user = User.host_organization
      expect(gravatar_for(user, size: 48, hosted: true)).to  match(/\/web-assets\//)
    end

  end
end
