require 'rubygems/package'

class ExtensionUpload
  #
  # This class provides access to extension archives. In particular, it supports
  # finding entries in the archive which have a path matching some regular
  # expression, and it can read the contents of files given their path. These
  # are the two primary operations required by this application to locate and
  # process metadata and README files.
  #
  class Archive
    #
    # Indicates that the uploaded archive may not be an upload, since it does
    # not have a +path+
    #
    class NoPath < RuntimeError; end

    #
    # Indicates that the source could not be processed
    #
    class Error < RuntimeError; end

    #
    # Creates a new Archive
    #
    # @param source [File] the source archive
    #
    def initialize(source)
      @source = source
    end

    #
    # Returns the paths of entries in the archive which match the given regular expression
    #
    # @param pattern [Regexp]
    #
    # @return [Array<String>] matching paths
    #
    def find(pattern)
      matches = []

      each do |entry|
        full_name = entry.full_name.gsub(/\s+/, "")
        regex_name = full_name
        # Hosted assets don't have the full path used in the regex
        unless regex_name.index('./') == 0
          regex_name = './' +  regex_name
        end
        next unless regex_name.match(pattern)
        matches << full_name
      end

      matches
    end

    #
    # Reads the contents of the file at the given path
    #
    # @param path [String]
    #
    # @return [String] the contents if a file exists at the given path
    # @return [nil] if no such file exists
    #
    def read(path)
      match = nil

      each do |entry|
        next unless entry.full_name == path

        match = entry.read

        break
      end

      match
    end

    private

    #
    # Iterates through each entry in the source archive
    #
    # @raise [NoPath] if the source has no path
    # @raise [Error] if the source is not a compatible archive
    #
    # @yieldparam [::Gem::Package::TarReader::Entry] entry
    #
    # @example
    #   archive = ExtensionUpload::Archive.new(tarball)
    #   archive.each do |entry|
    #     puts "#{entry.full_name} has the following content:\n#{entry.read}"
    #   end
    #
    def each
      raise NoPath unless @source.respond_to?(:path)

      begin
        Zlib::GzipReader.open(@source.path) do |gzip|
          Gem::Package::TarReader.new(gzip) do |tar|
            tar.each { |entry| yield entry }
          end
        end
      rescue Zlib::GzipFile::Error => e
        raise Error, e.message
      end
    end
  end
end
