defmodule Remit.Persistence.Repositories.TransactionEventRepository do
  @moduledoc """
  Repository module for transaction event operations.
  
  Handles create, read operations for transaction events in DynamoDB.
  """
  
  require Logger
  
  alias Remit.Persistence.DynamoDBClient
  alias Remit.Persistence.Schemas.TransactionEvent

  @table_name :transaction_events

  @doc """
  Creates a new transaction event.
  """
  @spec create(TransactionEvent.t()) :: {:ok, TransactionEvent.t()} | {:error, term()}
  def create(event) do
    Logger.debug("Creating transaction event: #{event.transaction_id} - #{event.event_type}")
    
    dynamo_item = TransactionEvent.to_dynamo_item(event)
    
    case DynamoDBClient.put_item(@table_name, dynamo_item) do
      {:ok, _} -> {:ok, event}
      error -> error
    end
  end

  @doc """
  Gets a transaction event by transaction ID and timestamp.
  """
  @spec get(String.t(), DateTime.t()) :: {:ok, TransactionEvent.t()} | {:error, term()}
  def get(transaction_id, timestamp) do
    timestamp_str = DateTime.to_iso8601(timestamp)
    Logger.debug("Getting transaction event: #{transaction_id} at #{timestamp_str}")
    
    key = %{
      "transaction_id" => %{"S" => transaction_id},
      "timestamp" => %{"S" => timestamp_str}
    }
    
    case DynamoDBClient.get_item(@table_name, key) do
      {:ok, item} -> {:ok, TransactionEvent.from_dynamo_item(item)}
      error -> error
    end
  end

  @doc """
  Gets all events for a transaction, ordered by timestamp.
  """
  @spec get_by_transaction_id(String.t()) :: {:ok, [TransactionEvent.t()]} | {:error, term()}
  def get_by_transaction_id(transaction_id) do
    Logger.debug("Getting events for transaction: #{transaction_id}")
    
    params = %{
      key_condition_expression: "transaction_id = :transaction_id",
      expression_attribute_values: %{
        ":transaction_id" => %{"S" => transaction_id}
      }
    }
    
    case DynamoDBClient.query(@table_name, params) do
      {:ok, items} -> 
        events = items
                |> Enum.map(&TransactionEvent.from_dynamo_item/1)
                |> Enum.sort_by(& &1.timestamp)
        
        {:ok, events}
      error -> error
    end
  end

  @doc """
  Gets all events of a specific type, ordered by timestamp.
  """
  @spec get_by_event_type(String.t(), integer()) :: {:ok, [TransactionEvent.t()]} | {:error, term()}
  def get_by_event_type(event_type, limit \\ 100) do
    Logger.debug("Getting events of type: #{event_type}")
    
    params = %{
      index_name: "event_type_index",
      key_condition_expression: "event_type = :event_type",
      expression_attribute_values: %{
        ":event_type" => %{"S" => event_type}
      },
      limit: limit
    }
    
    case DynamoDBClient.query(@table_name, params) do
      {:ok, items} -> 
        events = items
                |> Enum.map(&TransactionEvent.from_dynamo_item/1)
                |> Enum.sort_by(& &1.timestamp)
        
        {:ok, events}
      error -> error
    end
  end

  @doc """
  Records a status change event.
  """
  @spec record_status_change(String.t(), atom(), atom(), String.t(), map()) :: {:ok, TransactionEvent.t()} | {:error, term()}
  def record_status_change(transaction_id, previous_status, new_status, actor, details \\ %{}) do
    event = TransactionEvent.status_change(transaction_id, previous_status, new_status, actor, details)
    create(event)
  end

  @doc """
  Records a system event.
  """
  @spec record_system_event(String.t(), String.t(), map()) :: {:ok, TransactionEvent.t()} | {:error, term()}
  def record_system_event(transaction_id, event_type, details \\ %{}) do
    event = TransactionEvent.system_event(transaction_id, event_type, details)
    create(event)
  end

  @doc """
  Records a partner integration event.
  """
  @spec record_partner_event(String.t(), String.t(), String.t(), map()) :: {:ok, TransactionEvent.t()} | {:error, term()}
  def record_partner_event(transaction_id, partner, event_type, details \\ %{}) do
    event = TransactionEvent.partner_event(transaction_id, partner, event_type, details)
    create(event)
  end
end 