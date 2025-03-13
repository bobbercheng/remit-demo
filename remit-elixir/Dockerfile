FROM hexpm/elixir:1.14.5-erlang-25.3.2-debian-bullseye-20230522 as build

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set environment variables
ENV MIX_ENV=prod

# Create app directory and copy the Elixir projects into it
WORKDIR /app
COPY . .

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Compile the project
RUN mix compile

# Build the release
RUN mix release

# Prepare release image
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set environment variables
ENV MIX_ENV=prod

WORKDIR /app
COPY --from=build /app/_build/prod/rel/remit ./

# Set the default command to run when the container starts
CMD ["bin/remit", "start"] 