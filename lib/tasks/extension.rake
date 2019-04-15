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

	task :update_s3_store => :environment do
		worker = SyncExtensionContentsAtVersionsWorker.new
		Extension.not_hosted.each do |extension|
			puts "Copying assets for #{extension.name}"
			extension.extension_versions.each do |version|
				worker.send(:persist_assets, version)
			end
		end
	end

	task :delete_release_assets => :environment do
		# note that this doesn't delete the physical asset on S3
		extension_ids = Extension.not_hosted.pluck(:id)
		version_ids = ExtensionVersion.where(extension_id: extension_ids).pluck(:id)
		assets = ReleaseAsset.where(extension_version_id: version_ids)
		assets.delete_all
	end
	
end