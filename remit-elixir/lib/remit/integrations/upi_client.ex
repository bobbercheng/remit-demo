defmodule Remit.Integrations.UPIClient do
  @moduledoc """
  Client for integrating with UPI payment system in India.
  
  This module handles collecting funds from users via UPI in India.
  In production, this would integrate with a real UPI payment provider.
  """
  
  require Logger
  
  alias Tesla.Middleware

  @doc """
  Creates a new payment collection request via UPI.

  Returns:
  - `{:ok, payment_details}` on success
  - `{:error, reason}` on failure
  """
  @spec create_payment(map()) :: {:ok, map()} | {:error, map()}
  def create_payment(payment_params) do
    Logger.info("Creating UPI payment: #{inspect(payment_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/payments", payment_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("UPI payment creation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to create UPI payment", details: reason}}
    end
  end

  @doc """
  Verifies a UPI payment status.

  Returns:
  - `{:ok, payment_details}` on success
  - `{:error, reason}` on failure
  """
  @spec verify_payment(String.t()) :: {:ok, map()} | {:error, map()}
  def verify_payment(payment_id) do
    Logger.info("Verifying UPI payment: #{payment_id}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.get(client, "/payments/#{payment_id}") do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("UPI payment verification failed: #{inspect(reason)}")
        {:error, %{error: "Failed to verify UPI payment", details: reason}}
    end
  end

  @doc """
  Generates a payment link for UPI payment.

  Returns:
  - `{:ok, payment_link}` on success
  - `{:error, reason}` on failure
  """
  @spec generate_payment_link(map()) :: {:ok, map()} | {:error, map()}
  def generate_payment_link(payment_params) do
    Logger.info("Generating UPI payment link: #{inspect(payment_params)}")
    
    with {:ok, client} <- build_client(),
         {:ok, response} <- Tesla.post(client, "/payment-links", payment_params) do
      handle_response(response)
    else
      {:error, reason} ->
        Logger.error("UPI payment link generation failed: #{inspect(reason)}")
        {:error, %{error: "Failed to generate UPI payment link", details: reason}}
    end
  end

  # Private functions

  defp build_client do
    upi_config = Application.get_env(:remit, :partners)[:upi]
    base_url = upi_config[:base_url]
    timeout = upi_config[:timeout_ms]
    use_mock = upi_config[:use_mock] || false
    
    middleware = [
      {Middleware.BaseUrl, base_url},
      Middleware.JSON,
      {Middleware.Timeout, timeout: timeout},
      Middleware.Logger
    ]
    
    client = Tesla.client(middleware)
    
    if use_mock do
      {:ok, MockUPIClient.new(client)}
    else
      {:ok, client}
    end
  end

  defp handle_response(%Tesla.Env{status: status, body: body}) when status in 200..299 do
    {:ok, body}
  end
  
  defp handle_response(%Tesla.Env{status: status, body: body}) do
    Logger.error("UPI API error: #{status} - #{inspect(body)}")
    {:error, %{status: status, body: body}}
  end
end

defmodule MockUPIClient do
  @moduledoc """
  Mock UPI client for development and testing.
  
  Simulates UPI payment provider responses.
  """
  
  defstruct [:client]
  
  def new(client), do: %__MODULE__{client: client}
  
  defimpl Tesla.Adapter, for: MockUPIClient do
    def call(mock, env, _opts) do
      %{method: method, url: url, body: body} = env
      
      case {method, url} do
        {:post, "/payments"} ->
          payment_id = "upi_" <> UUID.uuid4()
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "payment_id" => payment_id,
              "status" => "created",
              "amount" => body["amount"],
              "currency" => body["currency"],
              "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
              "payment_link" => "https://upi-provider.com/pay/#{payment_id}"
            }
          }}
          
        {:get, "/payments/" <> payment_id} ->
          # Simulate successful payment 90% of the time
          status = if :rand.uniform(10) <= 9, do: "completed", else: "failed"
          
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "payment_id" => payment_id,
              "status" => status,
              "completed_at" => status == "completed" && DateTime.utc_now() |> DateTime.to_iso8601(),
              "failure_reason" => status == "failed" && "user_cancelled"
            }
          }}
          
        {:post, "/payment-links"} ->
          payment_id = "upi_" <> UUID.uuid4()
          {:ok, %Tesla.Env{
            status: 200,
            body: %{
              "payment_id" => payment_id,
              "payment_link" => "https://upi-provider.com/pay/#{payment_id}",
              "qr_code_url" => "https://upi-provider.com/qr/#{payment_id}",
              "expires_at" => DateTime.utc_now() |> DateTime.add(3600) |> DateTime.to_iso8601()
            }
          }}
          
        _ ->
          {:ok, %Tesla.Env{status: 404, body: %{"error" => "Not found"}}}
      end
    end
  end
end 