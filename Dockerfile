FROM scratch
ADD alpine-minirootfs-3.16.6-x86_64.tar.gz /
CMD ["/bin/sh"]
RUN apk add --no-cache lua5.3 lua-filesystem lua-lyaml lua-http
COPY fetch-latest-releases.lua /usr/local/bin
VOLUME /out
ENTRYPOINT [ "/usr/local/bin/fetch-latest-releases.lua" ]
