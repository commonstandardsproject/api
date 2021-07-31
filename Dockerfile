FROM ruby:2.6.8

WORKDIR /home/app

ENV PORT 3000

EXPOSE $PORT

RUN gem install rails bundler
RUN gem install rails
RUN apt-get update -qq && apt-get install -y nodejs
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --jobs 4

ENTRYPOINT [ "/bin/bash" ]
