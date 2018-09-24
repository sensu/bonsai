module BonsaiAssetIndex
  module Host
    def self.full_url
      if !Rails.env.production? && ENV['APP_PORT'].present? && !%w(80 443).include?(ENV['APP_PORT'])
        "#{ENV['PROTOCOL']}://#{ENV['HOST']}:#{ENV['APP_PORT']}"
      else
        "#{ENV['PROTOCOL']}://#{ENV['HOST']}"
      end
    end

    def self.host
      ENV['HOST']
    end

    def self.port
      ENV['APP_PORT']
    end
  end
end
