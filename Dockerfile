FROM ruby:2.7-alpine
WORKDIR /spellr
COPY . .
RUN gem install bundler && bundle install --without=development
WORKDIR /app
ENTRYPOINT ["/spellr/exe/spellr"]
