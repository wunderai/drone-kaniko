FROM golang:1.14-alpine as TOOLS
RUN apk update && apk upgrade
RUN apk add --no-cache build-base alpine-sdk busybox-extras ca-certificates 

COPY tools /go/src
RUN cd /go/src/autotag && go get -a && go build .


FROM gcr.io/kaniko-project/executor:debug-v0.24.0

COPY --from=TOOLS /go/bin/autotag /autotag

ENV HOME /root
ENV USER root
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json

# add the wrapper which acts as a drone plugin
COPY plugin.sh /kaniko/plugin.sh
ENTRYPOINT [ "/kaniko/plugin.sh" ]
