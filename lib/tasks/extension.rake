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
end