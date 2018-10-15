require 'spec_helper'

describe Tier do
  subject { build_stubbed :tier }

  it {expect(subject).to be_valid}
end
