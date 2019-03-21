# This utility class normalizes version tags before validating them with +Semverse::Version+.
# For example, "v3.4-20181225" gets normalized to "3.4.20181225".
# We have to normalize because +Semverse::Version+ requires version tags to be of the form "x.y.z".

# ("1.2.3-rc.1+build.1") => #<Version: @major=1, @minor=2, @patch=3, @pre_release='rc.1', @build='build.1'>

class SemverNormalizer
  def self.call(tag)
    return tag unless tag

    tag
      .to_s
      .sub(/\Av/i, '') # strip off any leading 'v'
      .strip
      # stripping hypends and underscores substantially changes the version string
      #.gsub(/[-_]/, '.')     # convert hyphens and underscores to dots
  end
end
