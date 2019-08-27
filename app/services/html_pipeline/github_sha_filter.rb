# Find references to commits and replace them with links.
#
# eg.
#
#   Introduced in eef98f1.
#   Reference implementation sensu/sensu-go@e1ac3d9.
#
# becomes...
#
#   Closes <a href="https://github.com/org/repo/commit/eef98f1"><tt>eef98f1</tt></a>.
#   Reference implementation <a href="https://github.com/sensu/sensu-go/commit/e1ac3d9">sensu/sensu-go@<tt>eef98f1</tt></a>.
#
class HtmlPipeline::GithubShaFilter < HTML::Pipeline::Filter
    # Don't look for mentions in text nodes that are children of these elements
    IGNORE_PARENTS = %w(pre code a style script).to_set

    PATTERN = /
      (?![\@])(^|\W)                           # non-word or amdpersand
      (?:([\w\-]+\/[\w\-]+)\@)?                  # match org and repo,
      ([a-f0-9]{7,8}|[a-f0-9]{40})               # match a 7, 8 or 40 char SHA,
      (?!\/)(?=\.+[ \t\W]|\.+$|[^0-9a-zA-Z_.]|$) # trailing characters
    /ix.freeze

    def call
      result[:mentioned_shas] ||= []

      doc.search('.//text()').each do |node|
        content = node.to_html
        next if has_ancestor?(node, IGNORE_PARENTS)
        html = sha_link_filter(content)
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

    def sha_link_filter(content)
      content.gsub PATTERN do |match|
        result[:mentioned_shas] |= [match]

        str  = Regexp.last_match(1)
        repo = Regexp.last_match(2)
        ref  = Regexp.last_match(3)

        url = "https://www.github.com/" + File.join(repo || asset_repo, "commit", ref)
        forward = "#{repo}@" if repo

        "#{str}<a href=\"#{url}\">#{forward}<tt>#{ref}</tt></a>"
      end
    end
  end
