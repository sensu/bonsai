enterprise_tier = Tier.find_by(name: 'Enterprise')
extensions = Array.wrap(enterprise_tier&.extensions)

extensions.each do |extension|
  CompileExtension.call(extension: extension)
end
