class HtmlPipeline::MentionFilter < HTML::Pipeline::MentionFilter
  # Override the default behaviour of the mention filter so that we are able to
  # directly link to the correct path.
  def base_url
    context[:users_path]
  end
end
