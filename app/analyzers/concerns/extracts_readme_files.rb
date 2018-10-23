require 'active_support/concern'

module ExtractsReadmeFiles
  extend ActiveSupport::Concern

  private

  def extract_readme(files:, path_method:, file_reader:)
    full_paths       = files.map(&path_method)
    readme_paths     = full_paths.grep /\/readme/i
    best_readme_path = readme_paths.sort_by { |path| path.split('/').size }.first

    # Don't go deeper than one level down, e.g. foo/readme is fine, but foo/down/readme is not.
    return [nil, nil] if best_readme_path.split('/').size > 2

    content   = file_reader.call(files, best_readme_path).presence
    extension = File.extname(best_readme_path).to_s.sub(/\A\./, '').presence  # strip off any leading '.'
    return [content, extension]
  end
end
