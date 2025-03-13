defmodule RemitWeb.RemittanceController do
  use RemitWeb, :controller
  
  alias Remit.Core.RemittanceService
  
  action_fallback RemitWeb.FallbackController

  @doc """
  Initiates a new remittance transaction.
  """
  def create(conn, params) do
    with {:ok, remittance_params} <- validate_and_convert_params(params),
         {:ok, transaction} <- RemittanceService.initiate_remittance(remittance_params) do
      
      conn
      |> put_status(:created)
      |> render("transaction.json", transaction: transaction)
    end
  end

  @doc """
  Gets a transaction by ID.
  """
  def show(conn, %{"id" => transaction_id}) do
    with {:ok, transaction} <- RemittanceService.get_transaction(transaction_id) do
      render(conn, "transaction.json", transaction: transaction)
    end
  end

  @doc """
  Gets transactions by sender ID.
  """
  def by_sender(conn, %{"sender_id" => sender_id} = params) do
    limit = Map.get(params, "limit", "10") |> String.to_integer()
    
    with {:ok, transactions} <- RemittanceService.get_transactions_by_sender(sender_id, limit) do
      render(conn, "transactions.json", transactions: transactions)
    end
  end

  @doc """
  Gets transactions by recipient ID.
  """
  def by_recipient(conn, %{"recipient_id" => recipient_id} = params) do
    limit = Map.get(params, "limit", "10") |> String.to_integer()
    
    with {:ok, transactions} <- RemittanceService.get_transactions_by_recipient(recipient_id, limit) do
      render(conn, "transactions.json", transactions: transactions)
    end
  end

  @doc """
  Gets the current exchange rate.
  """
  def exchange_rate(conn, %{"source" => source_currency, "target" => target_currency}) do
    with {:ok, rate} <- RemittanceService.get_current_exchange_rate(source_currency, target_currency) do
      render(conn, "exchange_rate.json", %{
        source_currency: source_currency,
        target_currency: target_currency,
        rate: rate,
        timestamp: DateTime.utc_now()
      })
    end
  end

  @doc """
  Handles UPI payment callbacks.
  """
  def payment_callback(conn, %{"transaction_id" => transaction_id} = params) do
    with {:ok, transaction} <- RemittanceService.process_payment_callback(transaction_id, params) do
      render(conn, "transaction.json", transaction: transaction)
    end
  end

  # Private functions

  defp validate_and_convert_params(params) do
    try do
      remittance_params = %{
        source_amount: parse_float(params["source_amount"]),
        source_currency: params["source_currency"],
        destination_currency: params["destination_currency"],
        sender_id: params["sender_id"],
        recipient_id: params["recipient_id"]
      }
      
      {:ok, remittance_params}
    rescue
      e ->
        {:error, "Invalid parameters: #{inspect(e)}"}
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(value) when is_float(value), do: value
  defp parse_float(value) when is_integer(value), do: value * 1.0
  defp parse_float(value) when is_binary(value), do: String.to_float(value)
end 