FROM ruby:2.6-alpine
WORKDIR /app
COPY . .
RUN gem install bundler && bundle install --without=development
ENTRYPOINT ["exe/spellr"]
