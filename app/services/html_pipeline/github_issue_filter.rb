# Find references to Github issues and Pull Requests and rewrite.
#
# eg.
#
#   Closes #59.
#
# becomes...
#
#   Closes <a href="https://github.com/org/repo/issues/59">#59</a>.
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
      if !repo
        raise StandardError, "expected context to include value for :asset_repo"
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

      url = "https://www.github.com/" + File.join(org, path, "issues", issue)
      "<a href=\"#{url}\">#{match}</a>"
    end
  end
end
