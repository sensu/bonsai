require 'active_support/concern'

module ExtractsFiles
  extend ActiveSupport::Concern

  class StringIOWithPath < StringIO
    attr_reader :path

    def initialize(path, *args)
      @path = path
      super *args
    end
  end

  private

  def find_file(file_path:, files:, path_method:, file_reader:)
    full_paths     = files.map(&path_method)
    regexp         = file_path.is_a?(Regexp) ? file_path : /#{file_path}\z/
    matching_paths = full_paths.grep regexp
    best_path      = matching_paths.sort_by { |path| [path.split('/').size, File.basename(path).size] }.first
    return nil unless best_path

    # Don't go deeper than one level down, e.g. foo/<file_path> is fine, but foo/down/<file_path> is not.
    split_file_path = file_path.to_s.split('/')
    # Handle Regexps that begin with /, e.g. /\/readme/i
    split_file_path.shift if file_path.is_a?(Regexp) && split_file_path.first =~ /\\\z/
    return nil if best_path.split('/').size > split_file_path.size + 1

    content = file_reader.call(files, best_path).to_s
    return StringIOWithPath.new(best_path, content)
  end
end
