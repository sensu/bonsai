class ExtractExtensionLicenseWorker < ApplicationWorker

  def perform(extension_id, current_user_id = nil)
    @extension = Extension.find(extension_id)
    current_user = User.find_by(id: current_user_id) if current_user_id.present?

    client = current_user&.octokit || octokit()
    @repo = client.repo(@extension.github_repo, accept: "application/vnd.github.drax-preview+json")

    if @repo[:license]

      begin
        license = client.license(@repo[:license][:key], accept: "application/vnd.github.drax-preview+json")
      rescue Octokit::NotFound
        license = {
          name: @repo[:license][:name],
          body: ""
        }
      end

      @extension.update_attributes(
        license_name: license[:name],
        license_text: license[:body]
      )
    end
  end

  private

  def octokit
    @octokit ||= @extension.octokit
  end
end
