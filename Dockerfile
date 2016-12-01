FROM ruby:2.3.1-slim

RUN apt-get update && apt-get install -y wget apt-transport-https git curl && \
     rm -rf /var/lib/apt/lists/*
RUN wget -qO- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo 'deb https://deb.nodesource.com/node_0.12 jessie main' > /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs build-essential libmysqlclient-dev libpq-dev libsqlite3-dev && \
     rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
      echo 'deb https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list && \
      apt-get update && apt-get install -y apt-transport-https ca-certificates docker-engine &&\
      rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Mostly static
COPY config.ru /app/
COPY Rakefile /app/
COPY bin /app/bin
COPY public /app/public
COPY db /app/db
COPY .env.bootstrap /app/.env
COPY .ruby-version /app/.ruby-version

# NPM
COPY package.json /app/package.json
RUN npm install

# Gems
COPY Gemfile /app/
COPY Gemfile.lock /app/
COPY vendor/cache /app/vendor/cache
COPY plugins /app/plugins

RUN bundle install --quiet --local --jobs 4 || bundle check

# Code
COPY config /app/config
COPY app /app/app
COPY lib /app/lib

EXPOSE 9080

CMD ["bundle", "exec", "puma", "-C", "./config/puma.rb"]
