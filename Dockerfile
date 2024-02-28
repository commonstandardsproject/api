# FROM ruby:3.0.2
FROM circleci/ruby:2.7.4
RUN sudo apt-get update && sudo apt-get install libjemalloc2 && sudo rm -rf /var/lib/apt/lists/*
ENV LD_PRELOAD=libjemalloc.so.2

WORKDIR /home/app

ENV PORT 3000

EXPOSE $PORT

USER root

RUN gem install bundler -v 2.4.22
RUN sudo apt-get update -qq && apt-get install -y nodejs
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --jobs 4
COPY ./ ./

ENTRYPOINT [ "/bin/sh", "-c" ]

CMD ["bundle", "exec","puma", "-C", "puma.rb"]

