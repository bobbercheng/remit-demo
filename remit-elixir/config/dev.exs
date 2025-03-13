import Config

# Configure your database
config :remit, Remit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "remit_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure DynamoDB for development
config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 8000,
  region: "us-east-1"

# Configure partner API mocks for development
config :remit, :partners,
  upi: [
    base_url: "https://api.upi-provider.com",
    use_mock: true,
    timeout_ms: 10_000
  ],
  ad_bank: [
    base_url: "https://api.adbank.com",
    use_mock: true,
    timeout_ms: 15_000
  ],
  wise: [
    base_url: "https://api.wise.com",
    use_mock: true,
    timeout_ms: 15_000
  ]

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
# Binding to loopback ipv4 address prevents access from other machines.
config :remit, RemitWeb.Endpoint,
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "TwridxOJpALNimwp7l9Y1Bia3HLmvvGuT8kudN7nFjEi30JyXlh5RcngGVql7sgN",
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Enable dev routes for dashboard and mailbox
config :remit, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
