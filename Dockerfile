FROM ruby:3.4.13-slim AS base
WORKDIR /rails
RUN apt-get update -qq && apt-get install --no-install-recommends -y curl libyaml-0-2 sqlite3 && rm -rf /var/lib/apt/lists/*
ENV BUNDLE_PATH=/usr/local/bundle

FROM base AS compiler
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./

FROM compiler AS development
RUN bundle install
COPY . .
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

FROM compiler AS build
ENV BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=1 RAILS_ENV=production
RUN bundle install && bundle clean
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base AS production
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=1
RUN groupadd -g 1000 rails && useradd -u 1000 -g rails -m rails
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails
USER rails
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
