# Builds a release image of the Elixir port. Two-stage build:
#   * builder: hex deps, compile, mix release
#   * runtime: minimal Debian + the release artifacts

ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=27.3.4
ARG DEBIAN_VERSION=bookworm-20250630-slim

# --- builder ------------------------------------------------------------
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS builder

# Build-time system deps. `git` is needed for the github-pinned
# mongodb_ecto dep; `build-essential` is needed because some Erlang
# packages compile NIFs.
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
       build-essential git ca-certificates curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ELIXIR_ERL_OPTIONS="+fnu"

RUN mix local.hex --force \
 && mix local.rebar --force

# Pull deps first so the layer caches independently of source changes.
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV \
 && mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile \
 && mix release csp_api

# --- runtime ------------------------------------------------------------
FROM debian:${DEBIAN_VERSION} AS runtime

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends \
      libstdc++6 openssl libncurses5 ca-certificates locales tini \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
 && locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    ELIXIR_ERL_OPTIONS="+fnu"

WORKDIR /app
RUN groupadd --system app && useradd --system --gid app --home /app --shell /sbin/nologin app
RUN chown app:app /app
USER app:app

COPY --from=builder --chown=app:app /app/_build/prod/rel/csp_api ./

EXPOSE 4000

# tini reaps zombie processes — useful when the BEAM spawns ports.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["bin/csp_api", "start"]
