require 'spec_helper'

describe 'extension version routes' do
  context 'to show a user' do

    it 'routes /assets/sensu/sensu-pagerduty-handler/versions/master to extension_version#show' do
      expect(get: "/assets/sensu/sensu-pagerduty-handler/versions/master").to route_to(
        :controller => "extension_versions",
        :action => "show",
        :username => "sensu",
        :extension_id => "sensu-pagerduty-handler",
        :version => "master"
      )
   end

    it 'routes /assets/sensu/sensu-pagerduty-handler/versions/1.0.0 to extension_version#show' do
      expect(get: "/assets/sensu/sensu-pagerduty-handler/versions/1.0.0").to route_to(
        :controller => "extension_versions",
        :action => "show",
        :username => "sensu",
        :extension_id => "sensu-pagerduty-handler",
        :version => "1.0.0"
      )
    end

    it 'routes /assets/sensu/sensu-pagerduty-handler/versions/1.0.0-alpha to extension_version#show' do
      expect(get: "/assets/sensu/sensu-pagerduty-handler/versions/1.0.0-alpha").to route_to(
        :controller => "extension_versions",
        :action => "show",
        :username => "sensu",
        :extension_id => "sensu-pagerduty-handler",
        :version => "1.0.0-alpha"
      )
    end

    it 'routes /assets/sensu/sensu-pagerduty-handler/versions//1.0.0-alpha+1241 to extension_version#show' do
      expect(get: "/assets/sensu/sensu-pagerduty-handler/versions/1.0.0-alpha+1241").to route_to(
          :controller => "extension_versions",
          :action => "show",
          :username => "sensu",
          :extension_id => "sensu-pagerduty-handler",
          :version => "1.0.0-alpha+1241"
        )
    end

  end
end
