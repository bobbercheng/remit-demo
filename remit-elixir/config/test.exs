import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environments.
# Run `mix help test` for more information.
config :remit, Remit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "remit_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Configure DynamoDB for testing
config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 8000,
  region: "us-east-1"

# Configure test-specific remittance settings
config :remit, :remittance,
  min_transaction_amount_inr: 100,  # Lower for testing
  max_transaction_amount_inr: 100_000,  # Lower for testing
  daily_limit_inr: 200_000,
  base_fee_percentage: 0.5,
  min_fee_inr: 50,
  transaction_expiry_hours: 1,  # Shorter for testing
  retry_attempts: 1,  # Fewer for testing
  retry_delay_seconds: 1  # Shorter for testing

# Configure mock partner APIs for testing
config :remit, :partners,
  upi: [
    base_url: "https://api.upi-provider.com",
    use_mock: true,
    timeout_ms: 1_000  # Shorter for testing
  ],
  ad_bank: [
    base_url: "https://api.adbank.com",
    use_mock: true,
    timeout_ms: 1_000  # Shorter for testing
  ],
  wise: [
    base_url: "https://api.wise.com",
    use_mock: true,
    timeout_ms: 1_000  # Shorter for testing
  ]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :remit, RemitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5KvhSzPaP9xmQWPUQHE5zQODzYEp47qHu9HS1XQnXYQDtJFFV9KA6FZpI9bKnv1v",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
