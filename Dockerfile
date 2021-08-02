# FROM ruby:3.0.2
FROM circleci/ruby:2.7.4

WORKDIR /home/app

ENV PORT 3000

EXPOSE $PORT

USER root

RUN gem install bundler
RUN sudo apt-get update -qq && apt-get install -y nodejs
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --jobs 4

ENTRYPOINT [ "/bin/bash" ]
