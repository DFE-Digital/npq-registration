# Build compilation image
FROM ruby:3.4.4-alpine3.21 AS builder

# The application runs from /app
WORKDIR /app

# Add the timezone as it's not configured by default in Alpine
RUN apk add --update --no-cache tzdata && \
    cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

# build-base: complication tools for bundle
# yarn: node package manager
# postgresql-dev: postgres driver and libraries
RUN apk add --no-cache build-base git postgresql-dev yaml-dev yarn

# Install bundler to run bundle exec
# This should be the same version as the Gemfile.lock
RUN gem install bundler:2.5.15 --no-document

# Install gems defined in Gemfile
COPY .ruby-version Gemfile Gemfile.lock ./

ENV NODE_OPTIONS=--openssl-legacy-provider

ARG BUNDLE_WITHOUT="development test"
# Install gems and remove gem cache
RUN bundler -v && \
    bundle config set no-cache 'true' && \
    bundle config set no-binstubs 'true' && \
    bundle config without ${BUNDLE_WITHOUT} && \
    bundle install --retry=5 --jobs=4 && \
    rm -rf /usr/local/bundle/cache

# Install node packages defined in package.json, including webpack
COPY package.json yarn.lock ./
RUN yarn install --immutable --ignore-scripts

# Copy all files to / inside image (except what is defined in .dockerignore)
COPY . .

# Precompile assets
RUN RAILS_ENV=production SECRET_KEY_BASE=required-to-run-but-not-used \
    bundle exec rails assets:precompile

# Cleanup to save space in the production image
RUN rm -rf node_modules log/* tmp/* /tmp && \
    rm -rf /usr/local/bundle/cache && \
    rm -rf .env && \
    find /usr/local/bundle/gems -name "*.c" -delete && \
    find /usr/local/bundle/gems -name "*.h" -delete && \
    find /usr/local/bundle/gems -name "*.o" -delete && \
    find /usr/local/bundle/gems -name "*.html" -delete

# Build runtime image
FROM ruby:3.4.4-alpine3.21 AS production

# The application runs from /app
WORKDIR /app

# Add the timezone as it's not configured by default in Alpine
ARG EXTRA_PACKAGES=""
RUN apk add --update --no-cache libpq tzdata yaml ${EXTRA_PACKAGES} && \
    cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

# Create non-root user and group with specific UIDs/GIDs
RUN addgroup -S appgroup -g 20001 && adduser -S appuser -G appgroup -u 10001

# Copy files generated in the builder image
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Change ownership only for directories that need write access
RUN chown -R appuser:appgroup /app/tmp /app/public/api/docs

ARG COMMIT_SHA
ENV AUTHORISED_HOSTS=127.0.0.1 \
    COMMIT_SHA=${COMMIT_SHA}

ENV PORT=8080

EXPOSE ${PORT}

# Switch to non-root user
USER 10001

SHELL ["/bin/sh", "-c"]
CMD bundle exec rake db:migrate && exec bundle exec rails s -p ${PORT} --binding=0.0.0.0
