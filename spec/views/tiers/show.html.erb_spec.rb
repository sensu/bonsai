require 'spec_helper'

RSpec.describe "tiers/show", type: :view do
  before(:each) do
    @tier = assign(:tier, Tier.create!(
      :name => "MyString",
      :rank => 1,
      :icon_name => "MyString"
    ))
  end

  it "renders the show tier form" do
    render

    assert_select "form[action=?][method=?]", tier_path(@tier), "post" do

      assert_select "input[name=?]", "tier[name]"

      assert_select "input[name=?]", "tier[rank]"

      assert_select "input[name=?]", "tier[icon_name]"
    end
  end
end
