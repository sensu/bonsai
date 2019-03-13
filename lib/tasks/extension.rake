namespace 'extension' do

	task :assign_host_organization => :environment do
		host = User.host_organization
		Extension.hosted.each do |extension|
			extension.owner_name = ENV['HOST_ORGANIZATION']
			extension.owner = host
			extension.save!
			puts "**** #{extension.lowercase_name} -> #{extension.owner.company}"
		end
	end

	task :update_support_badges => :environment do
		tier = Tier.find_by(name: 'Supported')
		tier.update_column(:icon_name, 'hand-holding-heart')
		tier = Tier.find_by(name: 'Enterprise')
		tier.update_column(:icon_name, 'rocket')
	end
	
end