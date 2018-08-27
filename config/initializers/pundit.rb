require 'bonsai_asset_index/pundit_policy_class'

ActiveRecord::Base.send(:extend, BonsaiAssetIndex::PunditPolicyClass)