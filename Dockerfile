# Build the gem
FROM ruby:2.6.3-alpine3.8 as gem-builder

ADD . /tmp/build

RUN set -o pipefail -o errexit; \
  cd /tmp/build ;\
  bundle install ;\
  gem build jfrog-cli-resource.gemspec

RUN apk add -U wget ca-certificates;\
  wget --directory-prefix /root \
  "https://jfrog.bintray.com/jfrog-cli-go/1.28.0/jfrog-cli-linux-amd64/jfrog";\
  chmod +x /root/jfrog

# Build production image
FROM ruby:2.6.3-alpine3.8

RUN apk add -U --no-cache ca-certificates; mkdir -vp /opt/resource

COPY --from=gem-builder /tmp/build/*.gem /opt/resource/.
COPY --from=gem-builder /root/jfrog /usr/local/bin/jfrog

RUN set -o pipefail -o errexit; \
    gem install /opt/resource/*.gem; \
    rm /opt/resource/*.gem; \
    ln -s "/usr/local/bundle/bin/jfrog-cli-resource-check" "/opt/resource/check"; \
    ln -s "/usr/local/bundle/bin/jfrog-cli-resource-in" "/opt/resource/in"; \
    ln -s "/usr/local/bundle/bin/jfrog-cli-resource-out" "/opt/resource/out"
