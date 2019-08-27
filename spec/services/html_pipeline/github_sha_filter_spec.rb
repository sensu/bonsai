require 'spec_helper'

describe HtmlPipeline::GithubShaFilter do
  def filter(html, asset_repo: "my/asset")
    HtmlPipeline::GithubShaFilter.call(html, asset_repo: asset_repo)
  end

  it "replaces a lone reference" do
    body = "Introduced in d50f2bd."
    link = '<a href="https://www.github.com/my/asset/commit/d50f2bd"><tt>d50f2bd</tt></a>'
    assert_equal "Introduced in #{link}.", filter(body).to_html
  end
  it "replaces multiple references" do
    body = %{
d50f2bd does a thing
abcdef0 does another thing
    }
    expt = %{
<a href=\"https://www.github.com/my/asset/commit/d50f2bd\"><tt>d50f2bd</tt></a> does a thing
<a href=\"https://www.github.com/my/asset/commit/abcdef0\"><tt>abcdef0</tt></a> does another thing
    }
    assert_equal expt, filter(body).to_html
  end

  it "replaces a reference with full path present" do
    body = "Look at: sensu/sensu@d50f2bd!"
    link = '<a href="https://www.github.com/sensu/sensu/commit/d50f2bd">sensu/sensu@<tt>d50f2bd</tt></a>'
    assert_equal "Look at: #{link}!", filter(body).to_html
  end

  it "does not replace a reference within a pre tag" do
    body = "<pre>Closes sensu/sensu@d50f2bd.</pre>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a code tag" do
    body = "<code>Closes sensu/sensu@d50f2bd.</code>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a style tag" do
    body = "<style>background: url(sensu/sensu@d50f2bd)</style>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a link" do
    body = "<p><a>sensu/sensu@d50f2bd</a> idk</p>"
    assert_equal body, filter(body).to_html
  end

  it "does not replace a reference within a link" do
    body = "<p><a>sensu/sensu@d50f2bd</a> idk</p>"
    assert_equal body, filter(body).to_html
  end

  it "does not allow injection" do
    body = "<p>d50f2bd &lt;script>alert(0)&lt;/script></p>"
    link = '<a href="https://www.github.com/my/asset/commit/d50f2bd"><tt>d50f2bd</tt></a>'
    assert_equal "<p>#{link} &lt;script&gt;alert(0)&lt;/script&gt;</p>", filter(body).to_html
  end
end
