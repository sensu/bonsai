source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.1'
gem 'responders'

# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
gem 'pg_search'

# gem 'redis-rails' # not necessary in rails 5.2+
gem 'sidekiq'
gem 'sidekiq-status'

# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# Disable Turbolinks, as it conflicts with Sparklines
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
# gem 'bootsnap', '>= 1.1.0', require: false

gem 'omniauth'
gem 'omniauth-github'
gem 'mixlib-authentication'
gem 'pundit'

gem 'redcarpet' # markdown parsing

gem 'html-pipeline' # Github HTML processing filters and utilities
# html-pipeline dependancies
gem 'commonmarker' # markdown parsing used by Github
gem 'rouge'
gem 'escape_utils'
gem 'email_reply_parser'
gem 'gemoji'
gem 'sanitize'
gem 'RedCloth'

gem 'safe_yaml', :require => false

gem "select2-rails"

gem 'octokit'
gem 'aws-sdk-s3', '~> 1'

gem 'premailer-rails'
gem 'virtus'
gem 'validate_url'
gem 'semverse'
gem 'sitemap_generator'
gem 'yajl-ruby', require: 'yajl'
gem 'utf8-cleaner'
gem 'rinku', :require => 'rails_rinku'
gem 'html_truncator'
gem 'ranked-model'                      # for managing extension tiers
gem 'rollout'
gem 'rubyzip'
gem 'interactor'                        # better wrangling of service objects
gem 'faraday_middleware'                # for following redirects
gem 'apipie-rails', '0.5.1'             # Lock to v0.5.1 because subsequent versions drop content after a couple of page refreshes
gem 'maruku'                            # so apipie can use Markdown
gem 'file_validators'                   # for validating hosted asset file types

gem 'kaminari'

gem 'airbrake'

gem 'puma_worker_killer'                # periodic restart to refresh memory on Heroku

group :doc do
  gem 'yard', :require => false
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'launchy'
  gem 'and_feathers'
  gem 'and_feathers-gzipped_tarball'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri] #, :mingw, :x64_mingw]
end

group :development do
  # Only in development as SendGrid is provisioned by Heroku
  gem 'sendgrid-ruby'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  # gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
end

group :test do
  gem 'rails-controller-testing'
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'poltergeist'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', :require => false
  gem 'vcr', :require => false
  gem 'webmock', :require => false
end

group :tools do
  gem 'squasher', '>= 0.6.0'
  #gem 'capistrano'
  gem 'rubocop'
  gem 'rubocop-rspec'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "multi_json", "~> 1.15"
