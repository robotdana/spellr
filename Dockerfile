FROM ruby:alpine
WORKDIR /spellr
COPY Gemfile spellr.gemspec .
COPY ./lib/spellr/version.rb ./lib/spellr/
RUN apk add --no-cache make musl-dev gcc && \
  BUNDLE_WITHOUT=development bundle install

FROM ruby:alpine
COPY . /spellr
COPY --from=0 /usr/local/bundle /usr/local/bundle
WORKDIR /app
ENTRYPOINT ["/spellr/exe/spellr"]
