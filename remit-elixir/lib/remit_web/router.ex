defmodule RemitWeb.Router do
  use RemitWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RemitWeb do
    pipe_through :api

    # Remittance endpoints
    post "/remittances", RemittanceController, :create
    get "/remittances/:id", RemittanceController, :show
    get "/remittances/sender/:sender_id", RemittanceController, :by_sender
    get "/remittances/recipient/:recipient_id", RemittanceController, :by_recipient
    get "/exchange-rates", RemittanceController, :exchange_rate
    
    # Callback endpoints
    post "/callbacks/payment", RemittanceController, :payment_callback
  end

  # Enable Swagger documentation
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :remit,
      swagger_file: "remittance_api.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Remit API",
        description: "API for cross-border remittance service between India and Canada",
        termsOfService: "https://remit.example.com/terms/",
        contact: %{
          name: "API Support",
          url: "https://remit.example.com/support",
          email: "support@remit.example.com"
        },
        license: %{
          name: "Apache 2.0",
          url: "https://www.apache.org/licenses/LICENSE-2.0.html"
        }
      },
      consumes: ["application/json"],
      produces: ["application/json"]
    }
  end
end
