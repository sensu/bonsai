module ApplicationHelper
  #
  # The OmniAuth path for the given +provider+.
  #
  # @param [String, Symbol] provider
  #
  def auth_path(provider)
    "/auth/#{provider}"
  end

  #
  # Returns a possessive version of the string
  #
  # @param name [String]
  #
  # @return [String]
  #
  def posessivize(name)
    return name if name.blank?

    if name.last == 's'
      name + "'"
    else
      name + "'s"
    end
  end

  #
  # Returns flash message class for a given flash message name
  #
  # @param name [String]
  #
  # @return [String]
  #
  def flash_message_class_for(name)
    {
      'notice' => 'success',
      'alert' => 'alert',
      'warning' => 'warning'
    }.fetch(name)
  end

  def advanced_options_available?
    supported_architectures.any? || supported_platforms.any?
  end

  def supported_architectures
    architectures_or_nil = extension_version_configurations_summary['arch']
    Array.wrap(architectures_or_nil)
  end

  def supported_platforms
    platforms_or_nil = extension_version_configurations_summary['platform']
    Array.wrap(platforms_or_nil)
  end

  private

  # Returns a +Hash+ that looks like:
  #   {"arch"=>["x86_64", "ppc", "aarch64", "armv7hl"],
  #    "platform"=>["linux", "OSX", "alpine"]}
  #
  # None of the keys (e.g. "arch" or "platform") are guaranteed to be in the
  # returned +Hash+ object.  Caveat caller.
  def extension_version_configurations_summary
    # Bust the cache whenever an +ExtensionVersion+ is updated.
    cache_key = ExtensionVersion.maximum(:updated_at).to_f

    return Rails.cache.fetch("#{cache_key}/extension_version_configurations_summary") do
      scope = ExtensionVersion.active
      gather_configuration_summary(scope)
    end
  end

  def gather_configuration_summary(scope=ExtensionVersion)
    # cb.to_sql is "\"extension_versions\".\"config\" -> 'builds'"
    cb = Arel::Nodes::InfixOperation.new('->',
                                         ExtensionVersion.arel_table[:config],
                                         Arel::Nodes.build_quoted('builds'))

    # nf.to_sql is "jsonb_array_elements(\"extension_versions\".\"config\" -> 'builds')"
    nf = Arel::Nodes::NamedFunction.new('jsonb_array_elements', [cb])

    # +all_config+ will look like:
    #   [{"arch"     => "x86_64",
    #     "platform" => "alpine",
    #     ...},
    #    {"arch"     => "aarch64",
    #     "platform" => "linux",
    #     ...},
    #    {"arch"     => "x86_64",
    #     "platform" => "linux",
    #     ...}]
    all_configs = scope
                    .distinct
                    .pluck(nf)

    # +pairs_of_interest+ will look like:
    #   [["arch", "x86_64"],
    #    ["platform", "alpine"],
    #    ["arch", "aarch64"],
    #    ["platform", "linux"],
    #    ["platform", "OSX"],
    #    ["arch", "armv7hl"],
    #    ["arch", "ppc"]]
    pairs_of_interest = all_configs
                          .map { |h| h.slice('arch', 'platform') }
                          .map(&:to_a)
                          .flatten(1)
                          .uniq

    pairs_of_interest
      .group_by(&:first)
      .transform_values { |arrs|
        arrs.map(&:second).sort_by(&:downcase)
      }
  end
end
