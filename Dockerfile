#
# HAProxy Dockerfile
#

FROM blueimp/alpine:3.4

MAINTAINER Sebastian Tschan <mail@blueimp.net>

RUN apk --no-cache add \
    haproxy'<'1.7

COPY haproxy /etc/haproxy

CMD ["haproxy", "-f", "/etc/haproxy/http.cfg"]
