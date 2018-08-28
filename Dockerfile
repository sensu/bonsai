FROM ruby:2.5.1
 
# Install essential Linux packages
RUN apt-get update -qq 

RUN apt-get install -y curl 

# Get node
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && apt-get install -y nodejs apt-transport-https

# Get Yarn dist
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - 
# RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# RUN apt-get update
# RUN apt-get install yarn

RUN apt-get install -y xvfb nano build-essential libpq-dev wget postgresql-9.6 postgresql-client postgresql-contrib

RUN rm -rf /var/lib/apt/lists/*

# Define where our application will live inside the image
ENV RAILS_ROOT /bonsai-asset-index
 
# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids
 
# Set our working directory inside the image
WORKDIR $RAILS_ROOT

#
# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
 
# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler
 
# Finish establishing our Ruby environment
RUN bundle install 

# Copy the Rails application into place
ADD . .

# Install npm packages
# COPY package.json yarn.lock ./
# RUN yarn install --production
# RUN yarn add caniuse-lite@^1.0.30000697
# RUN yarn upgrade css-loader -p
# RUN yarn upgrade webpack@^2.2.0 || ^3.0.0
# RUN yarn add babel-loader

# Expose a port
EXPOSE 80

# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]