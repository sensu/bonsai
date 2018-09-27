SimpleCov.start 'rails' do
  add_filter "/vendor/"
  add_filter "/app/channels"
end
SimpleCov.minimum_coverage 50  # Take this up to 100 once the dust settles
