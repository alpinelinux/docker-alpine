FROM alpine:3.16
RUN adduser -S -H -h / -g "Container Execution User" --shell /usr/sbin/nologin containerexec
RUN apk add --no-cache lua5.3 lua-filesystem lua-lyaml lua-http
COPY fetch-latest-releases.lua /usr/local/bin
VOLUME /out
ENTRYPOINT [ "/usr/local/bin/fetch-latest-releases.lua" ]
