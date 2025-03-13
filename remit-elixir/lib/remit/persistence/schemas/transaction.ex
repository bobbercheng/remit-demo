defmodule Remit.Persistence.Schemas.Transaction do
  @moduledoc """
  Schema for remittance transactions stored in DynamoDB.
  
  This schema represents the main transaction entity in the system.
  """
  
  alias Remit.Core.TransactionStatus

  @type t :: %__MODULE__{
    transaction_id: String.t(),
    status: TransactionStatus.t(),
    source_amount: float(),
    source_currency: String.t(),
    destination_amount: float(),
    destination_currency: String.t(),
    exchange_rate: float(),
    fees: float(),
    sender_id: String.t(),
    recipient_id: String.t(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    completion_time: DateTime.t() | nil,
    error_message: String.t() | nil,
    error_code: String.t() | nil,
    metadata: map()
  }

  @enforce_keys [
    :transaction_id,
    :status,
    :source_amount,
    :source_currency,
    :destination_amount,
    :destination_currency,
    :exchange_rate,
    :fees,
    :sender_id,
    :recipient_id,
    :created_at,
    :updated_at
  ]

  defstruct [
    :transaction_id,
    :status,
    :source_amount,
    :source_currency,
    :destination_amount,
    :destination_currency,
    :exchange_rate,
    :fees,
    :sender_id,
    :recipient_id,
    :created_at,
    :updated_at,
    :completion_time,
    :error_message,
    :error_code,
    metadata: %{}
  ]

  @doc """
  Creates a new transaction struct with default values.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    now = DateTime.utc_now()
    transaction_id = Map.get(attrs, :transaction_id, UUID.uuid4())

    struct!(
      __MODULE__,
      Map.merge(
        %{
          transaction_id: transaction_id,
          status: :initiated,
          created_at: now,
          updated_at: now,
          metadata: %{}
        },
        attrs
      )
    )
  end

  @doc """
  Updates the status of a transaction, automatically updating the updated_at timestamp
  and applying completion_time if the status is terminal.
  """
  @spec update_status(t(), TransactionStatus.t(), map()) :: t()
  def update_status(transaction, new_status, attrs \\ %{}) do
    now = DateTime.utc_now()
    
    attrs = if TransactionStatus.terminal?(new_status) do
      Map.put_new(attrs, :completion_time, now)
    else
      attrs
    end

    struct!(
      transaction,
      Map.merge(
        %{
          status: new_status,
          updated_at: now
        },
        attrs
      )
    )
  end

  @doc """
  Sets a transaction to failed status with error details.
  """
  @spec set_failed(t(), String.t(), String.t() | nil) :: t()
  def set_failed(transaction, error_message, error_code \\ nil) do
    update_status(transaction, :failed, %{
      error_message: error_message,
      error_code: error_code
    })
  end

  @doc """
  Converts a transaction to a DynamoDB item map.
  """
  @spec to_dynamo_item(t()) :: map()
  def to_dynamo_item(transaction) do
    %{
      "transaction_id" => %{"S" => transaction.transaction_id},
      "status" => %{"S" => Atom.to_string(transaction.status)},
      "source_amount" => %{"N" => Float.to_string(transaction.source_amount)},
      "source_currency" => %{"S" => transaction.source_currency},
      "destination_amount" => %{"N" => Float.to_string(transaction.destination_amount)},
      "destination_currency" => %{"S" => transaction.destination_currency},
      "exchange_rate" => %{"N" => Float.to_string(transaction.exchange_rate)},
      "fees" => %{"N" => Float.to_string(transaction.fees)},
      "sender_id" => %{"S" => transaction.sender_id},
      "recipient_id" => %{"S" => transaction.recipient_id},
      "created_at" => %{"S" => DateTime.to_iso8601(transaction.created_at)},
      "updated_at" => %{"S" => DateTime.to_iso8601(transaction.updated_at)}
    }
    |> add_optional_field("completion_time", transaction.completion_time, fn time -> %{"S" => DateTime.to_iso8601(time)} end)
    |> add_optional_field("error_message", transaction.error_message, fn msg -> %{"S" => msg} end)
    |> add_optional_field("error_code", transaction.error_code, fn code -> %{"S" => code} end)
    |> add_metadata(transaction.metadata)
  end

  @doc """
  Converts a DynamoDB item map to a transaction struct.
  """
  @spec from_dynamo_item(map()) :: t()
  def from_dynamo_item(item) do
    {:ok, status} = TransactionStatus.from_string(item["status"]["S"])
    
    %__MODULE__{
      transaction_id: item["transaction_id"]["S"],
      status: status,
      source_amount: parse_float(item["source_amount"]["N"]),
      source_currency: item["source_currency"]["S"],
      destination_amount: parse_float(item["destination_amount"]["N"]),
      destination_currency: item["destination_currency"]["S"],
      exchange_rate: parse_float(item["exchange_rate"]["N"]),
      fees: parse_float(item["fees"]["N"]),
      sender_id: item["sender_id"]["S"],
      recipient_id: item["recipient_id"]["S"],
      created_at: parse_datetime(item["created_at"]["S"]),
      updated_at: parse_datetime(item["updated_at"]["S"]),
      completion_time: get_optional_datetime(item, "completion_time"),
      error_message: get_optional_string(item, "error_message"),
      error_code: get_optional_string(item, "error_code"),
      metadata: extract_metadata(item)
    }
  end

  # Helper functions for DynamoDB conversion

  defp add_optional_field(map, _key, nil, _converter), do: map
  defp add_optional_field(map, key, value, converter), do: Map.put(map, key, converter.(value))

  defp add_metadata(map, metadata) when map_size(metadata) == 0, do: map
  defp add_metadata(map, metadata) do
    metadata_map = Enum.reduce(metadata, %{}, fn {k, v}, acc ->
      Map.put(acc, Atom.to_string(k), %{"S" => to_string(v)})
    end)
    
    Map.put(map, "metadata", %{"M" => metadata_map})
  end

  defp extract_metadata(item) do
    case Map.get(item, "metadata") do
      %{"M" => metadata_map} ->
        Enum.reduce(metadata_map, %{}, fn {k, v}, acc ->
          Map.put(acc, String.to_atom(k), v["S"])
        end)
      _ -> %{}
    end
  end

  defp parse_float(str), do: String.to_float(str)
  defp parse_datetime(str), do: DateTime.from_iso8601(str) |> elem(1)
  
  defp get_optional_string(item, key) do
    with %{"S" => value} <- Map.get(item, key, nil) do
      value
    else
      _ -> nil
    end
  end
  
  defp get_optional_datetime(item, key) do
    with %{"S" => value} <- Map.get(item, key, nil) do
      parse_datetime(value)
    else
      _ -> nil
    end
  end
end 