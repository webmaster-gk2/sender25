FROM ruby:3.2.2-bullseye AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      software-properties-common dirmngr apt-transport-https \
  && (curl -sL https://deb.nodesource.com/setup_20.x | bash -) \
  && rm -rf /var/lib/apt/lists/*

# Install main dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  build-essential  \
  netcat \
  curl \
  libmariadb-dev \
  libcap2-bin \
  nano \
  nodejs

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/ruby

# Configure 'sender25' to work everywhere (when the binary exists
# later in this process)
ENV PATH="/opt/sender25/app/bin:${PATH}"

# Setup an application
RUN useradd -r -d /opt/sender25 -m -s /bin/bash -u 999 sender25
USER sender25
RUN mkdir -p /opt/sender25/app /opt/sender25/config
WORKDIR /opt/sender25/app

# Install bundler
RUN gem install bundler -v 2.5.6 --no-doc

# Install the latest and active gem dependencies and re-run
# the appropriate commands to handle installs.
COPY --chown=sender25 Gemfile Gemfile.lock ./
RUN bundle install

# Copy the application (and set permissions)
COPY ./docker/wait-for.sh /docker-entrypoint.sh
COPY --chown=sender25 . .

# Export the version
ARG VERSION
ARG BRANCH
RUN if [ "$VERSION" != "" ]; then echo $VERSION > VERSION; fi \
  && if [ "$BRANCH" != "" ]; then echo $BRANCH > BRANCH; fi

# Set paths for when running in a container
ENV SENDER25_CONFIG_FILE_PATH=/config/sender25.yml

# Set the CMD
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["sender25"]

# ci target - use --target=ci to skip asset compilation
FROM base AS ci

# full target - default if no --target option is given
FROM base AS full

RUN RAILS_GROUPS=assets bundle exec rake assets:precompile
RUN touch /opt/sender25/app/public/assets/.prebuilt
