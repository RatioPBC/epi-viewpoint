# ---- Application Base Stage ----
FROM alpine:latest AS app_runner_base

ENV ELIXIR_PROJECT=epicenter
ARG DEFAULT_UID=1111
ARG DEFAULT_GID=1111
ENV LANG=C.UTF-8

RUN \
  apk -Uv add --no-cache \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    ncurses-libs \
    openssl \
    openssh \
    openssh-server-pam \
    postgresql-client \
    sudo \
  && curl https://geometer-private-ca.s3.amazonaws.com/privateCA.pem -o /usr/local/share/ca-certificates/privateCA.pem \
  && chmod 644 /usr/local/share/ca-certificates/privateCA.pem \
  && update-ca-certificates

RUN \
  apk -Uv add --no-cache \
    groff \
    less \
    mailcap

RUN \
  addgroup --gid $DEFAULT_GID app \
  && adduser -G app -g app -D -h /home/app -s /bin/bash --uid $DEFAULT_UID app

RUN \
  mkdir -p /usr/local/etc \
  && mkdir -p /opt/${ELIXIR_PROJECT}

WORKDIR /opt/${ELIXIR_PROJECT}

RUN chown -R app:app /usr/local/etc \
  && chown -R app:app /opt/${ELIXIR_PROJECT} \
  && sed -i 's|root:x:0:0:root:/root:/bin/ash|root:x:0:0:root:/root:/bin/bash|' /etc/passwd

# ---- Build Stage ----
FROM elixir:1.11.1-alpine AS app_builder

# Set environment variables for building the application
ENV MIX_ENV=prod\
    LANG=C.UTF-8

RUN set -xe \
  && apk --no-cache --update add \
    alpine-sdk \
    nodejs \
    npm \
    git

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY config ./config
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
ARG HEX_GEOMETER_READ_ONLY_KEY

RUN mix hex.organization auth geometer --key ${HEX_GEOMETER_READ_ONLY_KEY}
RUN mix deps.get --only=prod
RUN mix deps.compile

COPY assets ./assets
RUN npm ci --prefix assets
RUN npm run deploy --prefix assets

COPY priv ./priv
COPY lib ./lib
RUN mix phx.digest
RUN mix release
COPY bin ./bin

# --- App runner stage ---
FROM app_runner_base

ENV MIX_ENV=prod

WORKDIR /opt/${ELIXIR_PROJECT}

COPY --from=app_builder /app/_build/prod/rel/${ELIXIR_PROJECT} .
COPY --from=app_builder /app/bin/docker/start /opt/${ELIXIR_PROJECT}/bin

ARG COMMIT_SHA
RUN echo $COMMIT_SHA > version.txt
RUN VERSION_MD5=$(md5sum version.txt | awk '{print $1}')
RUN cp version.txt version-$VERSION_MD5.txt
RUN mv version*.txt /opt/${ELIXIR_PROJECT}/lib/${ELIXIR_PROJECT}-0.1.0/priv/static/

RUN chown -R app:app /opt/${ELIXIR_PROJECT}

ENV PORT=4000
EXPOSE 22/tcp
EXPOSE 4000/tcp
USER app:app
CMD "/opt/${ELIXIR_PROJECT}/bin/start"
