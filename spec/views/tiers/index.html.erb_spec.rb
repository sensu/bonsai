require 'spec_helper'

RSpec.describe "tiers/index", type: :view do
  let(:tier1) { create :tier }
  let(:tier2) { create :tier }

  before(:each) do
    Extension.destroy_all
    assign(:tiers, [
      tier1,
      tier2,
    ])
  end

  it "renders a list of tiers" do
    render
    assert_select "tr>td", :text => tier1.name, :count => 1
    assert_select "tr>td", :text => tier2.name, :count => 1
    assert_select "tr>td", :text => tier1.rank.to_s, :count => 1
    assert_select "tr>td", :text => tier2.rank.to_s, :count => 1
    assert_select "tr>td", :text => tier1.icon_name, :count => 1
    assert_select "tr>td", :text => tier2.icon_name, :count => 1
  end
end
