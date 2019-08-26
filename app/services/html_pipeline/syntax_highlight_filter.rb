class HtmlPipeline::SyntaxHighlightFilter < HTML::Pipeline::SyntaxHighlightFilter
  THEME = Rouge::Themes::Base16.mode(:light).freeze

  # Override the default behaviour of the Syntax filter to inline styles instead
  # of relying on a stylesheet to be present.
  def initialize(*args)
    super(*args)
    @formatter = Rouge::Formatters::HTMLInline.new(THEME)
  end
end
