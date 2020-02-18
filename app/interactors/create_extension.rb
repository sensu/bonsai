class CreateExtension
	include Interactor

  delegate :params,    to: :context
	delegate :candidate, to: :context 
	delegate :user,      to: :context 

	def call

		if candidate.hosted?
      candidate.owner = User.host_organization
      candidate.owner_name = ENV['HOST_ORGANIZATION']
    else
      fetch_context = FetchGithubInfo.call(extension: candidate, owner: user)
    	candidate.owner = user
    	candidate.owner_name = fetch_context.owner_name
    	candidate.github_organization = fetch_context.github_organization
    end

		# A disabled extension is available for re-use, but it must first be re-enabled.
    unless candidate.hosted? 
      existing = Extension.unscoped.where(enabled: false, github_url: candidate.github_url).first
      if existing.present?
        existing.update_attribute(:enabled, true)
        # TODO Does this need to validated and/or recompiled?
        context.extension = existing
        return
      end
    end

    validate_context = ValidateNewExtension.call(extension: candidate, owner: user)

    if validate_context.success?
    	candidate = validate_context.extension

      candidate.save

      CompileExtensionStatusClear.call(extension: candidate)
      
      if candidate.hosted?
      	version_name = params[:version] || '0.0.1'
        CompileExtensionStatus.call(
          extension: candidate,
          task: 'Set Up Hosted Compilation',
          worker: 'SetupHostedExtensionWorker', 
          job_id: SetupHostedExtensionWorker.perform_async(candidate.id, version_name)
        )
      else
      	compatible_platforms = params[:compatible_platforms] || []
        compatible_platforms.select!{ |p| p.present? }

        CompileExtensionStatus.call(
          extension: candidate,
          task: 'Set Up Github Compilation',
          worker: 'SetupGithubExtensionWorker', 
          job_id: SetupGithubExtensionWorker.perform_async(candidate.id, compatible_platforms)
        )
      end
    end

    context.extension = candidate
	end

end