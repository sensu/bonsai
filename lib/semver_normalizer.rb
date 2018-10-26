class SemverNormalizer
  def self.call(tag)
    tag.gsub(/\Av/, "")
  end
end
