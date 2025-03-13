defmodule Remit.Persistence.Repositories.TransactionRepository do
  @moduledoc """
  Repository module for transaction operations.
  
  Handles create, read, update, and delete operations for transactions in DynamoDB.
  """
  
  require Logger
  
  alias Remit.Persistence.DynamoDBClient
  alias Remit.Persistence.Schemas.Transaction

  @table_name :transactions

  @doc """
  Creates a new transaction.
  """
  @spec create(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def create(transaction) do
    Logger.info("Creating transaction: #{transaction.transaction_id}")
    
    dynamo_item = Transaction.to_dynamo_item(transaction)
    
    case DynamoDBClient.put_item(@table_name, dynamo_item) do
      {:ok, _} -> {:ok, transaction}
      error -> error
    end
  end

  @doc """
  Gets a transaction by ID.
  """
  @spec get(String.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def get(transaction_id) do
    Logger.info("Getting transaction: #{transaction_id}")
    
    key = %{"transaction_id" => %{"S" => transaction_id}}
    
    case DynamoDBClient.get_item(@table_name, key) do
      {:ok, item} -> {:ok, Transaction.from_dynamo_item(item)}
      error -> error
    end
  end

  @doc """
  Updates a transaction.
  """
  @spec update(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def update(transaction) do
    Logger.info("Updating transaction: #{transaction.transaction_id}")
    
    key = %{"transaction_id" => %{"S" => transaction.transaction_id}}
    dynamo_item = Transaction.to_dynamo_item(transaction)
    
    case DynamoDBClient.put_item(@table_name, dynamo_item) do
      {:ok, _} -> {:ok, transaction}
      error -> error
    end
  end

  @doc """
  Updates a transaction's status.
  """
  @spec update_status(String.t(), atom(), map()) :: {:ok, Transaction.t()} | {:error, term()}
  def update_status(transaction_id, new_status, attrs \\ %{}) do
    Logger.info("Updating transaction status: #{transaction_id} -> #{new_status}")
    
    with {:ok, transaction} <- get(transaction_id),
         updated_transaction = Transaction.update_status(transaction, new_status, attrs),
         {:ok, _} <- update(updated_transaction) do
      {:ok, updated_transaction}
    else
      error -> error
    end
  end

  @doc """
  Gets transactions by sender ID.
  """
  @spec get_by_sender(String.t(), integer()) :: {:ok, [Transaction.t()]} | {:error, term()}
  def get_by_sender(sender_id, limit \\ 10) do
    Logger.info("Getting transactions for sender: #{sender_id}")
    
    params = %{
      index_name: "sender_id_index",
      key_condition_expression: "sender_id = :sender_id",
      expression_attribute_values: %{
        ":sender_id" => %{"S" => sender_id}
      },
      limit: limit
    }
    
    case DynamoDBClient.query(@table_name, params) do
      {:ok, items} -> 
        transactions = Enum.map(items, &Transaction.from_dynamo_item/1)
        {:ok, transactions}
      error -> error
    end
  end

  @doc """
  Gets transactions by recipient ID.
  """
  @spec get_by_recipient(String.t(), integer()) :: {:ok, [Transaction.t()]} | {:error, term()}
  def get_by_recipient(recipient_id, limit \\ 10) do
    Logger.info("Getting transactions for recipient: #{recipient_id}")
    
    params = %{
      index_name: "recipient_id_index",
      key_condition_expression: "recipient_id = :recipient_id",
      expression_attribute_values: %{
        ":recipient_id" => %{"S" => recipient_id}
      },
      limit: limit
    }
    
    case DynamoDBClient.query(@table_name, params) do
      {:ok, items} -> 
        transactions = Enum.map(items, &Transaction.from_dynamo_item/1)
        {:ok, transactions}
      error -> error
    end
  end

  @doc """
  Gets transactions by status.
  """
  @spec get_by_status(atom(), integer()) :: {:ok, [Transaction.t()]} | {:error, term()}
  def get_by_status(status, limit \\ 10) do
    Logger.info("Getting transactions with status: #{status}")
    
    params = %{
      index_name: "status_index",
      key_condition_expression: "status = :status",
      expression_attribute_values: %{
        ":status" => %{"S" => Atom.to_string(status)}
      },
      limit: limit
    }
    
    case DynamoDBClient.query(@table_name, params) do
      {:ok, items} -> 
        transactions = Enum.map(items, &Transaction.from_dynamo_item/1)
        {:ok, transactions}
      error -> error
    end
  end

  @doc """
  Deletes a transaction by ID (mostly for testing).
  """
  @spec delete(String.t()) :: {:ok, String.t()} | {:error, term()}
  def delete(transaction_id) do
    Logger.info("Deleting transaction: #{transaction_id}")
    
    key = %{"transaction_id" => %{"S" => transaction_id}}
    
    case DynamoDBClient.delete_item(@table_name, key) do
      {:ok, _} -> {:ok, transaction_id}
      error -> error
    end
  end
end 