defmodule Remit.Persistence.Schemas.TransactionEvent do
  @moduledoc """
  Schema for remittance transaction events stored in DynamoDB.
  
  This schema represents audit trail events for each transaction state change.
  """
  
  alias Remit.Core.TransactionStatus

  @type t :: %__MODULE__{
    transaction_id: String.t(),
    timestamp: DateTime.t(),
    event_type: String.t(),
    previous_status: TransactionStatus.t() | nil,
    new_status: TransactionStatus.t() | nil,
    details: map(),
    actor: String.t()
  }

  @enforce_keys [
    :transaction_id,
    :timestamp,
    :event_type,
    :actor
  ]

  defstruct [
    :transaction_id,
    :timestamp,
    :event_type,
    :previous_status,
    :new_status,
    :actor,
    details: %{}
  ]

  @doc """
  Creates a new transaction event.
  """
  @spec new(map()) :: t()
  def new(attrs) do
    struct!(
      __MODULE__,
      Map.merge(
        %{
          timestamp: DateTime.utc_now(),
          details: %{}
        },
        attrs
      )
    )
  end

  @doc """
  Creates a status change event.
  """
  @spec status_change(String.t(), TransactionStatus.t(), TransactionStatus.t(), String.t(), map()) :: t()
  def status_change(transaction_id, previous_status, new_status, actor, details \\ %{}) do
    new(%{
      transaction_id: transaction_id,
      event_type: "status_change",
      previous_status: previous_status,
      new_status: new_status,
      actor: actor,
      details: details
    })
  end

  @doc """
  Creates a system event.
  """
  @spec system_event(String.t(), String.t(), map()) :: t()
  def system_event(transaction_id, event_type, details \\ %{}) do
    new(%{
      transaction_id: transaction_id,
      event_type: event_type,
      actor: "system",
      details: details
    })
  end

  @doc """
  Creates a partner integration event.
  """
  @spec partner_event(String.t(), String.t(), String.t(), map()) :: t()
  def partner_event(transaction_id, partner, event_type, details \\ %{}) do
    new(%{
      transaction_id: transaction_id,
      event_type: "#{partner}_#{event_type}",
      actor: partner,
      details: details
    })
  end

  @doc """
  Converts a transaction event to a DynamoDB item map.
  """
  @spec to_dynamo_item(t()) :: map()
  def to_dynamo_item(event) do
    item = %{
      "transaction_id" => %{"S" => event.transaction_id},
      "timestamp" => %{"S" => DateTime.to_iso8601(event.timestamp)},
      "event_type" => %{"S" => event.event_type},
      "actor" => %{"S" => event.actor}
    }

    item
    |> add_optional_status("previous_status", event.previous_status)
    |> add_optional_status("new_status", event.new_status)
    |> add_details(event.details)
  end

  @doc """
  Converts a DynamoDB item map to a transaction event struct.
  """
  @spec from_dynamo_item(map()) :: t()
  def from_dynamo_item(item) do
    %__MODULE__{
      transaction_id: item["transaction_id"]["S"],
      timestamp: parse_datetime(item["timestamp"]["S"]),
      event_type: item["event_type"]["S"],
      actor: item["actor"]["S"],
      previous_status: get_optional_status(item, "previous_status"),
      new_status: get_optional_status(item, "new_status"),
      details: extract_details(item)
    }
  end

  # Helper functions for DynamoDB conversion

  defp add_optional_status(map, _key, nil), do: map
  defp add_optional_status(map, key, status) do
    Map.put(map, key, %{"S" => Atom.to_string(status)})
  end

  defp add_details(map, details) when map_size(details) == 0, do: map
  defp add_details(map, details) do
    details_map = Enum.reduce(details, %{}, fn {k, v}, acc ->
      Map.put(acc, to_string(k), %{"S" => to_string(v)})
    end)
    
    Map.put(map, "details", %{"M" => details_map})
  end

  defp extract_details(item) do
    case Map.get(item, "details") do
      %{"M" => details_map} ->
        Enum.reduce(details_map, %{}, fn {k, v}, acc ->
          Map.put(acc, String.to_atom(k), v["S"])
        end)
      _ -> %{}
    end
  end

  defp parse_datetime(str), do: DateTime.from_iso8601(str) |> elem(1)
  
  defp get_optional_status(item, key) do
    with %{"S" => value} <- Map.get(item, key, nil),
         {:ok, status} <- TransactionStatus.from_string(value) do
      status
    else
      _ -> nil
    end
  end
end 