defmodule Remit.Integrations.ADBankClient do
  @moduledoc """
  Client for integrating with AD Bank for currency conversion.
  
  This module handles the conversion of INR to CAD via an Authorized Dealer (AD) Bank in India.
  In production, this would integrate with an actual AD Bank's API.
  """
  
  require Logger
  
  alias Tesla.Middleware

  @doc """
  Fetches the current exchange rate from INR to CAD.

  Returns:
  - `{:ok, rate_details}` on success
  - `{:error, reason}` on failure
  """
  @spec get_exchange_rate(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def get_exchange_rate(source_currency, target_currency) do
    Logger.info("Getting exchange rate: #{source_currency} to #{target_currency}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.get(client, "/exchange-rates", query: [
           from: source_currency,
           to: target_currency
         ]) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Exchange rate fetch failed: #{inspect(reason)}")
        {:error, %{error: "Failed to fetch exchange rate", details: reason}}
    end
  end

  @doc """
  Initializes a currency conversion transaction.

  Returns:
  - `{:ok, conversion_details}` on success
  - `{:error, reason}` on failure
  """
  @spec initiate_conversion(map()) :: {:ok, map()} | {:error, map()}
  def initiate_conversion(conversion_params) do
    Logger.info("Initiating currency conversion: #{inspect(conversion_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/conversions", conversion_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Currency conversion initiation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to initiate currency conversion", details: reason}}
    end
  end

  @doc """
  Checks the status of a conversion transaction.

  Returns:
  - `{:ok, conversion_details}` on success
  - `{:error, reason}` on failure
  """
  @spec check_conversion_status(String.t()) :: {:ok, map()} | {:error, map()}
  def check_conversion_status(conversion_id) do
    Logger.info("Checking conversion status: #{conversion_id}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.get(client, "/conversions/#{conversion_id}") do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Conversion status check failed: #{inspect(reason)}")
        {:error, %{error: "Failed to check conversion status", details: reason}}
    end
  end

  @doc """
  Initiates an outward remittance after conversion.

  Returns:
  - `{:ok, remittance_details}` on success
  - `{:error, reason}` on failure
  """
  @spec initiate_outward_remittance(map()) :: {:ok, map()} | {:error, map()}
  def initiate_outward_remittance(remittance_params) do
    Logger.info("Initiating outward remittance: #{inspect(remittance_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/outward-remittances", remittance_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Outward remittance initiation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to initiate outward remittance", details: reason}}
    end
  end

  # Private functions

  defp build_client do
    adbank_config = Application.get_env(:remit, :partners)[:ad_bank]
    base_url = adbank_config[:base_url]
    timeout = adbank_config[:timeout_ms]
    use_mock = adbank_config[:use_mock] || false
    
    middleware = [
      {Middleware.BaseUrl, base_url},
      Middleware.JSON,
      {Middleware.Timeout, timeout: timeout},
      Middleware.Logger
    ]
    
    client = Tesla.client(middleware)
    
    if use_mock do
      {:ok, MockADBankClient.new(client)}
    else
      {:ok, client}
    end
  end

  defp handle_response(%Tesla.Env{status: status, body: body}) when status in 200..299 do
    {:ok, body}
  end
  
  defp handle_response(%Tesla.Env{status: status, body: body}) do
    Logger.error("AD Bank API error: #{status} - #{inspect(body)}")
    {:error, %{status: status, body: body}}
  end
end

defmodule MockADBankClient do
  @moduledoc """
  Mock AD Bank client for development and testing.
  
  Simulates AD Bank API responses.
  """
  
  defstruct [:client]
  
  def new(client), do: %__MODULE__{client: client}
  
  defimpl Tesla.Adapter, for: MockADBankClient do
    def call(mock, env, _opts) do
      %{method: method, url: url, query: query, body: body} = env
      
      case {method, url} do
        {:get, "/exchange-rates"} ->
          from = Keyword.get(query || [], :from, "INR")
          to = Keyword.get(query || [], :to, "CAD")
          
          rate = exchange_rate(from, to)
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "source_currency" => from,
              "target_currency" => to,
              "rate" => rate,
              "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
            }
          }}
          
        {:post, "/conversions"} ->
          conversion_id = "conv_" <> UUID.uuid4()
          source_amount = body["source_amount"]
          source_currency = body["source_currency"]
          target_currency = body["target_currency"]
          rate = exchange_rate(source_currency, target_currency)
          target_amount = source_amount * rate
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "conversion_id" => conversion_id,
              "status" => "processing",
              "source_amount" => source_amount,
              "source_currency" => source_currency,
              "target_amount" => target_amount,
              "target_currency" => target_currency,
              "rate" => rate,
              "created_at" => DateTime.utc_now() |> DateTime.to_iso8601()
            }
          }}
          
        {:get, "/conversions/" <> conversion_id} ->
          # Simulate successful conversion 95% of the time
          status = if :rand.uniform(100) <= 95, do: "completed", else: "failed"
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "conversion_id" => conversion_id,
              "status" => status,
              "completed_at" => status == "completed" && DateTime.utc_now() |> DateTime.to_iso8601(),
              "failure_reason" => status == "failed" && "regulatory_check_failed"
            }
          }}
          
        {:post, "/outward-remittances"} ->
          remittance_id = "rem_" <> UUID.uuid4()
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "remittance_id" => remittance_id,
              "status" => "processing",
              "amount" => body["amount"],
              "currency" => body["currency"],
              "beneficiary" => body["beneficiary"],
              "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
              "estimated_completion_time" => DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_iso8601()
            }
          }}
          
        _ ->
          {:ok, %Tesla.Env{status: 404, body: %{"error" => "Not found"}}}
      end
    end
    
    defp exchange_rate("INR", "CAD"), do: 0.016
    defp exchange_rate("CAD", "INR"), do: 62.5
    defp exchange_rate(_, _), do: nil
  end
end 