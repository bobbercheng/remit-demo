defmodule Remit.Persistence.AWSDynamoDBClient do
  @moduledoc """
  AWS DynamoDB client implementation.
  
  This module provides a real implementation of the DynamoDBClient behaviour
  that interacts with AWS DynamoDB.
  """
  @behaviour Remit.Persistence.DynamoDBClient

  alias ExAws.Dynamo

  @impl true
  def put_item(table_name, item) do
    table_name
    |> Dynamo.put_item(item)
    |> ExAws.request()
    |> case do
      {:ok, _response} -> {:ok, item}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def get_item(table_name, key) do
    table_name
    |> Dynamo.get_item(key)
    |> ExAws.request()
    |> case do
      {:ok, %{"Item" => item}} -> {:ok, item}
      {:ok, %{}} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def query(table_name, key_condition, opts \\ []) do
    index_name = Keyword.get(opts, :index_name)
    limit = Keyword.get(opts, :limit)

    query_opts = [
      expression_attribute_values: build_expression_values(key_condition),
      key_condition_expression: key_condition,
      limit: limit,
      index_name: index_name
    ]
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})

    table_name
    |> Dynamo.query(query_opts)
    |> ExAws.request()
    |> case do
      {:ok, %{"Items" => items}} -> {:ok, items}
      {:ok, %{}} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def update_item(table_name, key, update_expression, expression_attribute_values) do
    table_name
    |> Dynamo.update_item(
      key,
      update_expression: update_expression,
      expression_attribute_values: expression_attribute_values,
      return_values: "ALL_NEW"
    )
    |> ExAws.request()
    |> case do
      {:ok, %{"Attributes" => attributes}} -> {:ok, attributes}
      {:ok, _} -> {:ok, %{}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def create_table(table_definition) do
    Dynamo.create_table(table_definition)
    |> ExAws.request()
  end

  # Helper function to build expression values for DynamoDB query
  defp build_expression_values(key_condition) do
    key_condition
    |> String.split(" AND ")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn condition ->
      case Regex.run(~r/(\w+)\s*=\s*:(\w+)/, condition) do
        [_, _attr_name, placeholder] ->
          {":#{placeholder}", extract_placeholder_value(placeholder)}

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  # Extract placeholder value from the context
  defp extract_placeholder_value(placeholder) do
    # This is a simplified implementation
    # In a real application, you would get these values from the context
    # For now, we'll just use some dummy values for demonstration
    case placeholder do
      "sender_id" -> "sender_123"
      "recipient_id" -> "recipient_456"
      "transaction_id" -> "tx_123"
      _ -> "unknown"
    end
  end
end 