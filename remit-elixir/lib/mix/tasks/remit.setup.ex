defmodule Mix.Tasks.Remit.Setup do
  @moduledoc """
  Mix task to set up DynamoDB tables for the Remit application.

  This task creates the necessary DynamoDB tables for storing transactions and transaction events.

  ## Usage

      mix remit.setup

  """
  use Mix.Task
  alias Remit.Persistence.DynamoDBClient

  @shortdoc "Sets up DynamoDB tables for Remit"
  def run(_) do
    # Start the application to ensure all dependencies are loaded
    Mix.Task.run("app.start")

    IO.puts("Setting up DynamoDB tables for Remit...")

    # Create transactions table
    create_transactions_table()

    # Create transaction events table
    create_transaction_events_table()

    IO.puts("Setup complete!")
  end

  defp create_transactions_table do
    IO.puts("Creating transactions table...")

    table_name = Application.get_env(:remit, :dynamodb_transactions_table)

    table_definition = %{
      "TableName" => table_name,
      "KeySchema" => [
        %{
          "AttributeName" => "transaction_id",
          "KeyType" => "HASH"
        }
      ],
      "AttributeDefinitions" => [
        %{
          "AttributeName" => "transaction_id",
          "AttributeType" => "S"
        },
        %{
          "AttributeName" => "sender_id",
          "AttributeType" => "S"
        },
        %{
          "AttributeName" => "recipient_id",
          "AttributeType" => "S"
        }
      ],
      "GlobalSecondaryIndexes" => [
        %{
          "IndexName" => "sender_id-index",
          "KeySchema" => [
            %{
              "AttributeName" => "sender_id",
              "KeyType" => "HASH"
            }
          ],
          "Projection" => %{
            "ProjectionType" => "ALL"
          },
          "ProvisionedThroughput" => %{
            "ReadCapacityUnits" => 5,
            "WriteCapacityUnits" => 5
          }
        },
        %{
          "IndexName" => "recipient_id-index",
          "KeySchema" => [
            %{
              "AttributeName" => "recipient_id",
              "KeyType" => "HASH"
            }
          ],
          "Projection" => %{
            "ProjectionType" => "ALL"
          },
          "ProvisionedThroughput" => %{
            "ReadCapacityUnits" => 5,
            "WriteCapacityUnits" => 5
          }
        }
      ],
      "BillingMode" => "PROVISIONED",
      "ProvisionedThroughput" => %{
        "ReadCapacityUnits" => 5,
        "WriteCapacityUnits" => 5
      }
    }

    case DynamoDBClient.create_table(table_definition) do
      {:ok, _} -> IO.puts("Transactions table created successfully!")
      {:error, %{"__type" => "ResourceInUseException"}} -> IO.puts("Transactions table already exists.")
      {:error, reason} -> IO.puts("Failed to create transactions table: #{inspect(reason)}")
    end
  end

  defp create_transaction_events_table do
    IO.puts("Creating transaction events table...")

    table_name = Application.get_env(:remit, :dynamodb_transaction_events_table)

    table_definition = %{
      "TableName" => table_name,
      "KeySchema" => [
        %{
          "AttributeName" => "transaction_id",
          "KeyType" => "HASH"
        },
        %{
          "AttributeName" => "timestamp",
          "KeyType" => "RANGE"
        }
      ],
      "AttributeDefinitions" => [
        %{
          "AttributeName" => "transaction_id",
          "AttributeType" => "S"
        },
        %{
          "AttributeName" => "timestamp",
          "AttributeType" => "S"
        }
      ],
      "BillingMode" => "PROVISIONED",
      "ProvisionedThroughput" => %{
        "ReadCapacityUnits" => 5,
        "WriteCapacityUnits" => 5
      }
    }

    case DynamoDBClient.create_table(table_definition) do
      {:ok, _} -> IO.puts("Transaction events table created successfully!")
      {:error, %{"__type" => "ResourceInUseException"}} -> IO.puts("Transaction events table already exists.")
      {:error, reason} -> IO.puts("Failed to create transaction events table: #{inspect(reason)}")
    end
  end
end 