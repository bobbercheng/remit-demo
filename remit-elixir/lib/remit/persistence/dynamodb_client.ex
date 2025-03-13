defmodule Remit.Persistence.DynamoDBClient do
  @moduledoc """
  Client module for interacting with DynamoDB.
  
  Provides a simplified interface for working with DynamoDB tables.
  """
  
  require Logger
  
  alias ExAws.Dynamo

  @tables %{
    transactions: "remit_transactions",
    transaction_events: "remit_transaction_events"
  }

  @callback put_item(String.t(), map()) :: {:ok, map()} | {:error, any()}
  @callback get_item(String.t(), map()) :: {:ok, map() | nil} | {:error, any()}
  @callback query(String.t(), String.t(), keyword()) :: {:ok, list(map())} | {:error, any()}
  @callback update_item(String.t(), map(), String.t(), map()) :: {:ok, map()} | {:error, any()}
  @callback create_table(map()) :: {:ok, map()} | {:error, any()}

  @doc """
  Creates all required DynamoDB tables if they don't exist.
  """
  @spec create_tables() :: :ok
  def create_tables do
    create_transactions_table()
    create_transaction_events_table()
    :ok
  end

  @doc """
  Gets a single item by its partition key.
  """
  @spec get_item(atom(), map()) :: {:ok, map()} | {:error, term()}
  def get_item(table_name, key) do
    table = get_table_name(table_name)
    
    Logger.debug("Getting item from #{table} with key #{inspect(key)}")
    
    Dynamo.get_item(table, key)
    |> ExAws.request()
    |> case do
      {:ok, %{"Item" => item}} -> {:ok, item}
      {:ok, %{}} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Puts a single item into the table.
  """
  @spec put_item(atom(), map()) :: {:ok, map()} | {:error, term()}
  def put_item(table_name, item) do
    table = get_table_name(table_name)
    
    Logger.debug("Putting item into #{table}")
    
    Dynamo.put_item(table, item)
    |> ExAws.request()
  end

  @doc """
  Updates an item in the table.
  """
  @spec update_item(atom(), map(), map(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def update_item(table_name, key, updates, condition_expression \\ nil) do
    table = get_table_name(table_name)
    
    Logger.debug("Updating item in #{table} with key #{inspect(key)}")
    
    update_expression = build_update_expression(updates)
    expression_attribute_values = build_expression_attribute_values(updates)
    
    request = Dynamo.update_item(table, key, update_expression: update_expression, 
      expression_attribute_values: expression_attribute_values)
    
    request = if condition_expression do
      Dynamo.update_opts(request, condition_expression: condition_expression)
    else
      request
    end
    
    ExAws.request(request)
  end

  @doc """
  Queries items using a partition key and optional sort key conditions.
  """
  @spec query(atom(), map()) :: {:ok, [map()]} | {:error, term()}
  def query(table_name, params) do
    table = get_table_name(table_name)
    
    Logger.debug("Querying table #{table} with params #{inspect(params)}")
    
    Dynamo.query(table, params)
    |> ExAws.request()
    |> case do
      {:ok, %{"Items" => items}} -> {:ok, items}
      {:ok, %{}} -> {:ok, []}
      error -> error
    end
  end

  @doc """
  Deletes an item from the table.
  """
  @spec delete_item(atom(), map()) :: {:ok, map()} | {:error, term()}
  def delete_item(table_name, key) do
    table = get_table_name(table_name)
    
    Logger.debug("Deleting item from #{table} with key #{inspect(key)}")
    
    Dynamo.delete_item(table, key)
    |> ExAws.request()
  end

  @doc """
  Gets the configured table name for a table key.
  """
  @spec get_table_name(atom()) :: String.t()
  def get_table_name(table_key) do
    Map.get(@tables, table_key, to_string(table_key))
  end

  @doc """
  Puts an item into a DynamoDB table.

  ## Parameters

    * `table_name` - The name of the table to put the item into.
    * `item` - The item to put into the table.

  ## Returns

    * `{:ok, item}` - The item was successfully put into the table.
    * `{:error, reason}` - The item could not be put into the table.
  """
  def put_item(table_name, item) do
    client = get_dynamodb_client()
    client.put_item(table_name, item)
  end

  @doc """
  Gets an item from a DynamoDB table.

  ## Parameters

    * `table_name` - The name of the table to get the item from.
    * `key` - The key of the item to get.

  ## Returns

    * `{:ok, item}` - The item was successfully retrieved.
    * `{:ok, nil}` - The item was not found.
    * `{:error, reason}` - The item could not be retrieved.
  """
  def get_item(table_name, key) do
    client = get_dynamodb_client()
    client.get_item(table_name, key)
  end

  @doc """
  Queries a DynamoDB table.

  ## Parameters

    * `table_name` - The name of the table to query.
    * `key_condition` - The key condition expression.
    * `opts` - Additional options for the query.

  ## Returns

    * `{:ok, items}` - The query was successful.
    * `{:error, reason}` - The query failed.
  """
  def query(table_name, key_condition, opts \\ []) do
    client = get_dynamodb_client()
    client.query(table_name, key_condition, opts)
  end

  @doc """
  Updates an item in a DynamoDB table.

  ## Parameters

    * `table_name` - The name of the table to update the item in.
    * `key` - The key of the item to update.
    * `update_expression` - The update expression.
    * `expression_attribute_values` - The expression attribute values.

  ## Returns

    * `{:ok, updated_item}` - The item was successfully updated.
    * `{:error, reason}` - The item could not be updated.
  """
  def update_item(table_name, key, update_expression, expression_attribute_values) do
    client = get_dynamodb_client()
    client.update_item(table_name, key, update_expression, expression_attribute_values)
  end

  @doc """
  Creates a DynamoDB table.

  ## Parameters

    * `table_definition` - The definition of the table to create.

  ## Returns

    * `{:ok, table_description}` - The table was successfully created.
    * `{:error, reason}` - The table could not be created.
  """
  def create_table(table_definition) do
    client = get_dynamodb_client()
    client.create_table(table_definition)
  end

  defp get_dynamodb_client do
    Application.get_env(:remit, :dynamodb_client)
  end

  # Private functions

  defp create_transactions_table do
    table_name = get_table_name(:transactions)
    
    Logger.info("Creating DynamoDB table: #{table_name}")
    
    Dynamo.create_table(table_name, 
      [transaction_id: :hash], 
      [transaction_id: :string], 
      1, 1)
    |> ExAws.request()
    |> case do
      {:ok, _} -> 
        # Create a GSI for sender_id to query transactions by sender
        Dynamo.update_table(table_name,
          [
            global_secondary_index_updates: [
              [
                create: [
                  index_name: "sender_id_index",
                  key_schema: [
                    [attribute_name: "sender_id", key_type: "HASH"],
                    [attribute_name: "created_at", key_type: "RANGE"]
                  ],
                  projection: [projection_type: "ALL"],
                  provisioned_throughput: [read_capacity_units: 1, write_capacity_units: 1]
                ]
              ],
              [
                create: [
                  index_name: "recipient_id_index",
                  key_schema: [
                    [attribute_name: "recipient_id", key_type: "HASH"],
                    [attribute_name: "created_at", key_type: "RANGE"]
                  ],
                  projection: [projection_type: "ALL"],
                  provisioned_throughput: [read_capacity_units: 1, write_capacity_units: 1]
                ]
              ],
              [
                create: [
                  index_name: "status_index",
                  key_schema: [
                    [attribute_name: "status", key_type: "HASH"],
                    [attribute_name: "updated_at", key_type: "RANGE"]
                  ],
                  projection: [projection_type: "ALL"],
                  provisioned_throughput: [read_capacity_units: 1, write_capacity_units: 1]
                ]
              ]
            ],
            attribute_definitions: [
              [attribute_name: "sender_id", attribute_type: "S"],
              [attribute_name: "recipient_id", attribute_type: "S"],
              [attribute_name: "status", attribute_type: "S"],
              [attribute_name: "created_at", attribute_type: "S"],
              [attribute_name: "updated_at", attribute_type: "S"]
            ]
          ]
        )
        |> ExAws.request()
        
        Logger.info("Created table: #{table_name}")
        :ok
      
      {:error, {"ResourceInUseException", "Cannot create preexisting table"}} ->
        Logger.info("Table already exists: #{table_name}")
        :ok
      
      error ->
        Logger.error("Failed to create table #{table_name}: #{inspect(error)}")
        error
    end
  end

  defp create_transaction_events_table do
    table_name = get_table_name(:transaction_events)
    
    Logger.info("Creating DynamoDB table: #{table_name}")
    
    Dynamo.create_table(table_name, 
      [transaction_id: :hash, timestamp: :range], 
      [transaction_id: :string, timestamp: :string], 
      1, 1)
    |> ExAws.request()
    |> case do
      {:ok, _} -> 
        # Create a GSI for event_type to query events by type
        Dynamo.update_table(table_name,
          [
            global_secondary_index_updates: [
              [
                create: [
                  index_name: "event_type_index",
                  key_schema: [
                    [attribute_name: "event_type", key_type: "HASH"],
                    [attribute_name: "timestamp", key_type: "RANGE"]
                  ],
                  projection: [projection_type: "ALL"],
                  provisioned_throughput: [read_capacity_units: 1, write_capacity_units: 1]
                ]
              ]
            ],
            attribute_definitions: [
              [attribute_name: "event_type", attribute_type: "S"]
            ]
          ]
        )
        |> ExAws.request()
        
        Logger.info("Created table: #{table_name}")
        :ok
      
      {:error, {"ResourceInUseException", "Cannot create preexisting table"}} ->
        Logger.info("Table already exists: #{table_name}")
        :ok
      
      error ->
        Logger.error("Failed to create table #{table_name}: #{inspect(error)}")
        error
    end
  end

  defp build_update_expression(updates) do
    expressions = Enum.map(updates, fn {key, _value} ->
      "#{key} = :#{key}"
    end)
    
    "SET " <> Enum.join(expressions, ", ")
  end

  defp build_expression_attribute_values(updates) do
    Enum.reduce(updates, %{}, fn {key, value}, acc ->
      Map.put(acc, ":#{key}", value)
    end)
  end
end 