require 'spec_helper'
require 'database_cleaner'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.around(:each) do |test|
    DatabaseCleaner.cleaning do
      test.run
    end
  end

end