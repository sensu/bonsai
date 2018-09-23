module RedirectBack
  def from(url)
    request.env['HTTP_REFERER'] = url
  end
end
