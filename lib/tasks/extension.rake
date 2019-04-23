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
		Extension.all.each do |extension|
			puts "Copying assets for #{extension.name}"
			extension.extension_versions.each do |version|
				PersistAssets.call(version: version)
			end
		end
	end

	task :update_hosted_verson_last_commit => :environment do
		Extension.hosted.each do |extension|
			puts "Updating versions for #{extension.name}"
			extension.extension_versions.each do |version|
				if version.source_file.attached?
					last_commit_sha = version.source_file.blob.checksum
					puts "Updating last commit for #{version.version}"
	      	version.update_columns(last_commit_sha:  last_commit_sha, last_commit_at: DateTime.now)
	      end
			end
		end
	end

	task :delete_release_assets => :environment do
		# do not delete release assets not associated with version
		# note that this doesn't delete the physical asset on S3
		version_ids = ExtensionVersion.all.each do |version|
			version.release_assets.delete_all
		end
	end
	
end