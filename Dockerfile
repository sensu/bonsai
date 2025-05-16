FROM ruby:3.4.4

# Install essential Linux packages
RUN apt-get update -qq --fix-missing

RUN apt-get install -y curl

# Get node
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && apt-get install -y nodejs apt-transport-https

RUN apt-get install -y xvfb nano build-essential libpq-dev wget postgresql-client postgresql-contrib

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
RUN gem install bundler -v 1.17.3

# Finish establishing our Ruby environment
RUN bundle install

# Copy the Rails application into place
ADD . .

# Expose a port
EXPOSE 80

# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]
