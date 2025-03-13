defmodule Remit.Integrations.WiseClient do
  @moduledoc """
  Client for integrating with Wise (former TransferWise) for international transfers.
  
  This module handles sending money to Canada via the Wise API.
  In production, this would integrate with the actual Wise API.
  """
  
  require Logger
  
  alias Tesla.Middleware

  @doc """
  Creates a recipient account in Wise.

  Returns:
  - `{:ok, recipient_details}` on success
  - `{:error, reason}` on failure
  """
  @spec create_recipient(map()) :: {:ok, map()} | {:error, map()}
  def create_recipient(recipient_params) do
    Logger.info("Creating Wise recipient: #{inspect(recipient_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/recipients", recipient_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise recipient creation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to create Wise recipient", details: reason}}
    end
  end

  @doc """
  Gets a quote for a transfer.

  Returns:
  - `{:ok, quote_details}` on success
  - `{:error, reason}` on failure
  """
  @spec create_quote(map()) :: {:ok, map()} | {:error, map()}
  def create_quote(quote_params) do
    Logger.info("Creating Wise quote: #{inspect(quote_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/quotes", quote_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise quote creation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to create Wise quote", details: reason}}
    end
  end

  @doc """
  Creates a transfer in Wise.

  Returns:
  - `{:ok, transfer_details}` on success
  - `{:error, reason}` on failure
  """
  @spec create_transfer(map()) :: {:ok, map()} | {:error, map()}
  def create_transfer(transfer_params) do
    Logger.info("Creating Wise transfer: #{inspect(transfer_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/transfers", transfer_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise transfer creation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to create Wise transfer", details: reason}}
    end
  end

  @doc """
  Funds a transfer in Wise.

  Returns:
  - `{:ok, funding_details}` on success
  - `{:error, reason}` on failure
  """
  @spec fund_transfer(String.t(), map()) :: {:ok, map()} | {:error, map()}
  def fund_transfer(transfer_id, funding_params) do
    Logger.info("Funding Wise transfer #{transfer_id}: #{inspect(funding_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/transfers/#{transfer_id}/payments", funding_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise transfer funding failed: #{inspect(reason)}")
        {:error, %{error: "Failed to fund Wise transfer", details: reason}}
    end
  end

  @doc """
  Gets the status of a transfer.

  Returns:
  - `{:ok, transfer_details}` on success
  - `{:error, reason}` on failure
  """
  @spec get_transfer(String.t()) :: {:ok, map()} | {:error, map()}
  def get_transfer(transfer_id) do
    Logger.info("Getting Wise transfer: #{transfer_id}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.get(client, "/transfers/#{transfer_id}") do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise transfer fetch failed: #{inspect(reason)}")
        {:error, %{error: "Failed to get Wise transfer", details: reason}}
    end
  end

  @doc """
  Cancels a transfer.

  Returns:
  - `{:ok, cancellation_details}` on success
  - `{:error, reason}` on failure
  """
  @spec cancel_transfer(String.t(), String.t()) :: {:ok, map()} | {:error, map()}
  def cancel_transfer(transfer_id, reason) do
    Logger.info("Cancelling Wise transfer #{transfer_id}: #{reason}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.put(client, "/transfers/#{transfer_id}/cancel", %{
           "cancelReason" => reason
         }) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("Wise transfer cancellation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to cancel Wise transfer", details: reason}}
    end
  end

  # Private functions

  defp build_client do
    wise_config = Application.get_env(:remit, :partners)[:wise]
    base_url = wise_config[:base_url]
    timeout = wise_config[:timeout_ms]
    use_mock = wise_config[:use_mock] || false
    
    middleware = [
      {Middleware.BaseUrl, base_url},
      Middleware.JSON,
      {Middleware.Timeout, timeout: timeout},
      Middleware.Logger
    ]
    
    client = Tesla.client(middleware)
    
    if use_mock do
      {:ok, MockWiseClient.new(client)}
    else
      {:ok, client}
    end
  end

  defp handle_response(%Tesla.Env{status: status, body: body}) when status in 200..299 do
    {:ok, body}
  end
  
  defp handle_response(%Tesla.Env{status: status, body: body}) do
    Logger.error("Wise API error: #{status} - #{inspect(body)}")
    {:error, %{status: status, body: body}}
  end
end

defmodule MockWiseClient do
  @moduledoc """
  Mock Wise client for development and testing.
  
  Simulates Wise API responses.
  """
  
  defstruct [:client]
  
  def new(client), do: %__MODULE__{client: client}
  
  defimpl Tesla.Adapter, for: MockWiseClient do
    def call(mock, env, _opts) do
      %{method: method, url: url, body: body} = env
      
      case {method, url} do
        {:post, "/recipients"} ->
          recipient_id = "r_" <> UUID.uuid4()
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "id" => recipient_id,
              "profile" => body["profile"],
              "accountHolderName" => body["accountHolderName"],
              "currency" => body["currency"],
              "country" => body["country"],
              "type" => body["type"],
              "details" => body["details"]
            }
          }}
          
        {:post, "/quotes"} ->
          quote_id = "q_" <> UUID.uuid4()
          source_amount = body["sourceAmount"]
          source_currency = body["sourceCurrency"]
          target_currency = body["targetCurrency"]
          
          # Apply a small fee and rate
          fee = source_amount * 0.01
          rate = if source_currency == "CAD" && target_currency == "CAD", do: 1.0, else: 0.99
          target_amount = (source_amount - fee) * rate
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "id" => quote_id,
              "sourceCurrency" => source_currency,
              "targetCurrency" => target_currency,
              "sourceAmount" => source_amount,
              "targetAmount" => target_amount,
              "fee" => fee,
              "rate" => rate,
              "expirationTime" => DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_iso8601()
            }
          }}
          
        {:post, "/transfers"} ->
          transfer_id = "t_" <> UUID.uuid4()
          quote_id = body["quoteId"]
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "id" => transfer_id,
              "status" => "created",
              "quoteId" => quote_id,
              "targetAccount" => body["targetAccount"],
              "reference" => body["reference"],
              "rate" => 0.99,
              "sourceAmount" => body["sourceAmount"],
              "targetAmount" => body["targetAmount"],
              "sourceCurrency" => body["sourceCurrency"],
              "targetCurrency" => body["targetCurrency"],
              "created" => DateTime.utc_now() |> DateTime.to_iso8601()
            }
          }}
          
        {:post, "/transfers/" <> transfer_id <> "/payments"} ->
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "status" => "processing",
              "errorCode" => nil,
              "errorMessage" => nil
            }
          }}
          
        {:get, "/transfers/" <> transfer_id} ->
          # Simulate successful transfer 95% of the time
          status = if :rand.uniform(100) <= 95, do: "outgoing_payment_sent", else: "failed"
          
          error_code = if status == "failed", do: "balance_not_sufficient", else: nil
          error_message = if status == "failed", do: "Not enough balance to fund the transfer", else: nil
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "id" => transfer_id,
              "status" => status,
              "errorCode" => error_code,
              "errorMessage" => error_message,
              "sourceCurrency" => "CAD",
              "targetCurrency" => "CAD",
              "sourceAmount" => 100.0,
              "targetAmount" => 99.0,
              "estimatedDeliveryDate" => status == "outgoing_payment_sent" && 
                (DateTime.utc_now() |> DateTime.add(24 * 3600) |> DateTime.to_iso8601())
            }
          }}
          
        {:put, "/transfers/" <> transfer_id <> "/cancel"} ->
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "id" => transfer_id,
              "status" => "cancelled",
              "cancelReason" => body["cancelReason"]
            }
          }}
          
        _ ->
          {:ok, %Tesla.Env{status: 404, body: %{"error" => "Not found"}}}
      end
    end
  end
end 