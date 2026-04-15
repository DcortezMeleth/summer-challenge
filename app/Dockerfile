# Build stage: compile app and assets
FROM elixir:1.19-otp-28 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

# Copy dependency manifests first for better layer caching
COPY mix.exs mix.lock ./

RUN mix deps.get --only $MIX_ENV

COPY config config

RUN mix deps.compile

COPY lib lib
COPY priv priv
COPY assets assets
COPY rel rel

RUN mix compile

RUN mix assets.deploy

RUN mix release

# ------------------------------------------------------------------------------
# Runtime stage: only the OTP release, no build tools
FROM debian:trixie-slim AS runner

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libncurses6 \
    openssl \
    ca-certificates \
    locales \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m appuser

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

COPY --from=builder --chown=appuser:appuser /build/_build/prod/rel/summer_challenge ./

USER appuser

ENV PHX_SERVER=true

EXPOSE 4000

CMD ["sh", "-c", "./bin/migrate && ./bin/server"]
