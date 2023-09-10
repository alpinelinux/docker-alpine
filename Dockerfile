FROM python:3.7.17-alpine
RUN apk add --no-cache lua5.3 lua-filesystem lua-lyaml lua-http
COPY fetch-latest-releases.lua /usr/local/bin
VOLUME /out
ENTRYPOINT [ "/usr/local/bin/fetch-latest-releases.lua" ]

RUN set -eux; \
        \
        wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
        echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; \
        \
        export PYTHONDONTWRITEBYTECODE=1; \
        \
        python get-pip.py \
                --disable-pip-version-check \
                --no-cache-dir \
                --no-compile \
                "pip==$PYTHON_PIP_VERSION" \
                "setuptools==$PYTHON_SETUPTOOLS_VERSION" \
        ; \
        rm -f get-pip.py; \
        \
        pip --version
