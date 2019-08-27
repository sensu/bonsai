# Find references to Github issues and rewrite to link.
#
# eg.
#
#   Closes #59.
#   See sensu#60 <_<
#   Wow: sensu/sensu#61!
#
# becomes...
#
#   Closes <a href="https://github.com/org/repo/issues/59">#59</a>.
#   See <a href="https://github.com/org/sensu/issues/60">sensu#60</a> <_<
#   Wow: <a href="https://github.com/sensu/sensu/issues/61">sensu/sensu#61</a>!
#
class HtmlPipeline::GithubIssueFilter < HTML::Pipeline::Filter
  # Don't look for mentions in text nodes that are children of these elements
  IGNORE_PARENTS = %w(pre code a style script).to_set

  PATTERN = /(\b[\w\-]+\/)?(\b[\w\-]+)?#([0-9]+)\b/.freeze
  PREFIX  = "#".freeze

  def call
    result[:mentioned_issues] ||= []

    doc.search('.//text()').each do |node|
      content = node.to_html
      next unless content.include?(PREFIX)
      next if has_ancestor?(node, IGNORE_PARENTS)
      html = issue_link_filter(content)
      next if html == content
      node.replace(html)
    end
    doc
  end

  private

  def asset_repo
    context[:asset_repo].tap do |repo|
      unless repo.present?
        raise ArgumentError, "expected context to include value for key :asset_repo"
      end
    end
  end

  def asset_repo_organization
    asset_repo.split("/")[0]
  end

  def asset_repo_path
    asset_repo.split("/")[1]
  end

  def issue_link_filter(content)
    content.gsub PATTERN do |match|
      result[:mentioned_issues] |= [match]

      org   = Regexp.last_match(1) || asset_repo_organization
      path  = Regexp.last_match(2) || asset_repo_path
      issue = Regexp.last_match(3)

      # In a convenient twist regardless of whether the ID refers to an issue
      # or a pull request the path /issues/:id will redirect to the place.
      url = "https://www.github.com/" + File.join(org, path, "issues", issue)
      "<a href=\"#{url}\">#{match}</a>"
    end
  end
end
