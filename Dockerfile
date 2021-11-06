FROM alpine:latest

RUN apk add --update --no-cache \
    lftp \
    ca-certificates \
    openssh-client

COPY lftp-mirror.sh /usr/local/bin/lftp-mirror.sh
RUN chmod +x /usr/local/bin/lftp-mirror.sh

CMD [ "sh", "/usr/local/bin/lftp-mirror.sh" ]