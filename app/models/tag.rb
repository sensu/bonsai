class Tag < ApplicationRecord
  DEFAULT_TAGS = ["automate", "aws", "build", "data model", "dev", "policy", "policies", "events", "reports", "dashboard", "widgets", "dialogs", "vmware", "scvmm", "rhevm", "networking", "dynamic dialogs", "integration", "buttons", "spam", "configuration management", "puppet", "chef", "ansible", "soap", "rest API", "alarms", "email", "services", "catalog items", "catalog bundles", "CMDB", "rails", "ruby", "OpenStack", "Hyper-V", "RHEV", "oVirt", "vSphere", "The Foreman", "Kubernetes"].map(&:downcase).sort

  has_many :taggings

  class << self 

  	def default_tags
  		DEFAULT_TAGS
  	end

  	def all_tags
  		(DEFAULT_TAGS + self.select(:name).map(&:name)).uniq.sort
  	end

  end # class << self

end
