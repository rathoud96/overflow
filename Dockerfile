FROM elixir:1.18-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base npm git python3 postgresql-client

# Set build ENV - explicitly set production
ENV MIX_ENV=prod \
    NODE_ENV=production \
    ERL_FLAGS="+JPperf true"

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory and copy the Elixir projects into it
WORKDIR /app

# Copy dependency files
COPY mix.exs mix.lock ./

# Install mix dependencies (excluding dev/test dependencies)
RUN MIX_ENV=prod mix deps.get --only prod
RUN MIX_ENV=prod mix deps.clean --unused
RUN MIX_ENV=prod mix deps.compile

# Copy compile-time config files before we compile dependencies
COPY config config

# Copy source code
COPY priv priv
COPY lib lib

# Compile the release (ensure production environment)
RUN MIX_ENV=prod mix compile

# Assemble the release
RUN MIX_ENV=prod mix release

# Start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM alpine:3.18 AS app

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs libstdc++ postgresql-client bash netcat-openbsd wget

# Create app user
RUN adduser -S app -h /app

# Set the locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

WORKDIR /app
USER app

# Copy the release from the build stage
COPY --from=build --chown=app:root /app/_build/prod/rel/overflow ./

# Copy entrypoint script
COPY --chown=app:root entrypoint.sh ./
USER root
RUN chmod +x entrypoint.sh
USER app

# Expose port
EXPOSE 4000

# Set default environment variables
ENV PHX_SERVER=true \
    MIX_ENV=prod

# Set the startup command to use entrypoint script
ENTRYPOINT ["./entrypoint.sh"]
