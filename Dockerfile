FROM ruby:2.6.3-alpine3.8

COPY . /opt/resource

RUN set -o pipefail -o errexit; \
    gem install bundler; \
    cd /opt/resource; \
    bundle install
