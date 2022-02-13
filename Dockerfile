FROM ruby:alpine
WORKDIR /spellr
COPY . .
RUN apk add --no-cache make musl-dev gcc
RUN gem install bundler && bundle install --without=development
WORKDIR /app
ENTRYPOINT ["/spellr/exe/spellr"]
