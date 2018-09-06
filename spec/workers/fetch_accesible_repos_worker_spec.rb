require 'spec_helper'

describe FetchAccessibleReposWorker do
  let(:user) { create(:user) }

  it 'fetches repos' do
    FetchAccessibleReposWorker.new.perform(user.id)
    expect( Marshal.load(Redis.current.get("user-repos-#{user.id}")) ).to eql([])
  end

end