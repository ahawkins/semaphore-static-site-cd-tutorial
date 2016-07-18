FROM ruby:2.3-onbuild

ENV LC_ALL C.UTF-8

RUN apt-get update -y && apt-get install -y nodejs

CMD [ "bundle", "exec", "middleman", "--help" ]
