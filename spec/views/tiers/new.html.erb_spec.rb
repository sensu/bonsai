require 'spec_helper'

RSpec.describe "tiers/new", type: :view do
  before(:each) do
    assign(:tier, Tier.new(
      :name => "MyString",
      :rank => 1,
      :icon_name => "MyString"
    ))
  end

  it "renders new tier form" do
    render

    assert_select "form[action=?][method=?]", tiers_path, "post" do

      assert_select "input[name=?]", "tier[name]"

      assert_select "input[name=?]", "tier[rank]"

      assert_select "input[name=?]", "tier[icon_name]"
    end
  end
end
