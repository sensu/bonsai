require 'spec_helper'

describe HtmlPipeline::GithubIssueFilter do
  def filter(html, asset_repo: "my/asset")
    HtmlPipeline::GithubIssueFilter.call(html, asset_repo: asset_repo)
  end

  it "replaces a lone reference" do
    body = "Closes #90."
    link = '<a href="https://www.github.com/my/asset/issues/90">#90</a>'
    assert_equal "Closes #{link}.", filter(body).to_html
  end

  it "replaces a reference with repo path present" do
    body = "Closes other-repo#90."
    link = '<a href="https://www.github.com/my/other-repo/issues/90">other-repo#90</a>'
    assert_equal "Closes #{link}.", filter(body).to_html
  end

  it "replaces a reference with full path present" do
    body = "Closes sensu/sensu#90."
    link = '<a href="https://www.github.com/sensu/sensu/issues/90">sensu/sensu#90</a>'
    assert_equal "Closes #{link}.", filter(body).to_html
  end

  it "does not replace a reference within a pre tag" do
    body = "<pre>Closes sensu/sensu#90.</pre>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a code tag" do
    body = "<code>Closes sensu/sensu#90.</code>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a style tag" do
    body = "<style>background: url(sensu/sensu#90)</style>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a link" do
    body = "<p><a>sensu/sensu#90</a> idk</p>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a link" do
    body = "<p><a>sensu/sensu#90</a> idk</p>"
    assert_equal body, filter(body).to_html
  end

  it "does not allow injection" do
    body = "<p>app#90 &lt;script>alert(0)&lt;/script></p>"
    link = '<a href="https://www.github.com/my/app/issues/90">app#90</a>'
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>", filter(body).to_html
  end
end
