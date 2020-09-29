# ---- Application Base Stage ----
FROM alpine:latest AS app_runner_base

ARG ELIXIR_PROJECT=epicenter
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
  addgroup app \
  && adduser -G app -g app -D -h /home/app -s /bin/bash app

RUN \
  mkdir -p /usr/local/etc \
  && mkdir -p /opt/bin \
  && mkdir -p /opt/${ELIXIR_PROJECT}

WORKDIR /opt/${ELIXIR_PROJECT}

RUN chown -R app:app /usr/local/etc \
  && chown -R app:app /opt/${ELIXIR_PROJECT} \
  && sed -i 's|root:x:0:0:root:/root:/bin/ash|root:x:0:0:root:/root:/bin/bash|' /etc/passwd

# ---- Build Stage ----
FROM elixir:1.10.3-alpine AS app_builder

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
ARG HEX_OBAN_UI_KEY

RUN mix hex.organization auth geometer --key ${HEX_GEOMETER_READ_ONLY_KEY}
RUN mix hex.organization auth oban --key ${HEX_OBAN_UI_KEY}
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
ARG PROJECT=epicenter

WORKDIR /opt/${ELIXIR_PROJECT}

COPY --from=app_builder /app/_build/prod/rel/${ELIXIR_PROJECT} .
COPY --from=app_builder /app/bin/docker/start /opt/${ELIXIR_PROJECT}/bin

RUN chown -R app:app /opt/${ELIXIR_PROJECT}

ENV PORT=4000
ENV ELIXIR_PROJECT=${ELIXIR_PROJECT}
EXPOSE 22/tcp
EXPOSE 4000/tcp
USER app:app

CMD "/opt/${ELIXIR_PROJECT}/bin/start"