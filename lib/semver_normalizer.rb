# This utility class normalizes version tags before validating them with +Semverse::Version+.
# For example, "v3.4-20181225" gets normalized to "3.4.20181225".
# We have to normalize because +Semverse::Version+ requires version tags to be of the form "x.y.z".

class SemverNormalizer
  def self.call(tag)
    return tag unless tag

    tag
      .to_s
      .strip
      .sub(/\Av/i, '')       # strip off any leading 'v'
      .gsub(/[-_]/, '.')     # convert hyphens and underscores to dots
  end
end
