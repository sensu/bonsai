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

    it 'routes /release_assets/sensu/sensu-ruby-runtime/0.0.6/alpine3.8/amd64/download' do 
      expect(get: "/release_assets/sensu/sensu-ruby-runtime/0.0.6/alpine3.8/amd64/download").to route_to(
          :controller => "release_assets",
          :action => "download",
          :username => "sensu",
          :extension_id => "sensu-ruby-runtime",
          :version => "0.0.6",
          :platform => "alpine3.8",
          :arch => "amd64"
        )
    end

  end
end
