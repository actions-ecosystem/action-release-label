FROM alpine:latest

RUN apk add --no-cache jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
