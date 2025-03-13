# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :remit,
  ecto_repos: [Remit.Repo],
  generators: [timestamp_type: :utc_datetime]

# Remittance service configuration
config :remit, :remittance,
  # Transaction limits
  min_transaction_amount_inr: 500,
  max_transaction_amount_inr: 1_000_000,
  daily_limit_inr: 2_000_000,
  
  # Default fees
  base_fee_percentage: 0.5,
  min_fee_inr: 50,
  
  # Transaction rules
  transaction_expiry_hours: 24,
  retry_attempts: 3,
  retry_delay_seconds: 60

# Partner integration configuration
config :remit, :partners,
  # UPI integration for India fund collection
  upi: [
    base_url: "https://api.upi-provider.com",
    timeout_ms: 10_000
  ],
  
  # AD Bank integration for currency conversion
  ad_bank: [
    base_url: "https://api.adbank.com",
    timeout_ms: 15_000
  ],
  
  # Wise integration for Canada fund disbursement
  wise: [
    base_url: "https://api.wise.com",
    timeout_ms: 15_000
  ]

# Configures the endpoint
config :remit, RemitWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RemitWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Remit.PubSub,
  live_view: [signing_salt: "jqE6wPEX"]

# Configure DynamoDB
config :ex_aws,
  debug_requests: false,
  json_codec: Jason,
  access_key_id: "local",
  secret_access_key: "local",
  region: "us-east-1"

# Configure OpenAPI documentation
config :remit, :phoenix_swagger,
  swagger_files: %{
    "priv/openapi/remittance_api.json" => [
      router: RemitWeb.Router,
      endpoint: RemitWeb.Endpoint
    ]
  }

config :phoenix_swagger, json_library: Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
