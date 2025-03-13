defmodule Remit.RemittanceServiceTest do
  use ExUnit.Case
  alias Remit.Remittance.RemittanceService
  alias Remit.Remittance.Transaction
  alias Remit.Remittance.TransactionRepository
  alias Remit.Remittance.TransactionEventRepository
  alias Remit.Partners.UPI.UPIClient
  alias Remit.Partners.ADBank.ADBankClient
  alias Remit.Partners.Wise.WiseClient

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    # Setup mock expectations for the happy path
    Mox.stub(Remit.MockDynamoDBClient, :put_item, fn _table_name, item -> {:ok, item} end)
    Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, _key -> {:ok, nil} end)
    Mox.stub(Remit.MockDynamoDBClient, :query, fn _table_name, _key_condition, _opts -> {:ok, []} end)
    Mox.stub(Remit.MockDynamoDBClient, :update_item, fn _table_name, _key, _update_expression, _expression_attribute_values -> {:ok, %{}} end)

    # Mock UPI client
    Mox.stub(Remit.MockUPIClient, :generate_payment_link, fn _transaction_id, _amount, _currency ->
      {:ok, "https://upi-provider.com/pay/123456789"}
    end)

    # Mock AD Bank client
    Mox.stub(Remit.MockADBankClient, :get_exchange_rate, fn "INR", "CAD" ->
      {:ok, %{rate: 0.016, timestamp: DateTime.utc_now()}}
    end)
    Mox.stub(Remit.MockADBankClient, :convert_currency, fn _transaction_id, _source_amount, _source_currency, _target_currency ->
      {:ok, %{
        transaction_id: "adbank_tx_123",
        source_amount: 10000,
        source_currency: "INR",
        target_amount: 160,
        target_currency: "CAD",
        rate: 0.016,
        fees: 50,
        status: "completed"
      }}
    end)

    # Mock Wise client
    Mox.stub(Remit.MockWiseClient, :transfer_funds, fn _transaction_id, _amount, _currency, _recipient_id ->
      {:ok, %{
        transaction_id: "wise_tx_123",
        status: "completed"
      }}
    end)

    :ok
  end

  describe "initiate_transaction/1" do
    test "successfully initiates a transaction" do
      params = %{
        source_amount: 10000,
        source_currency: "INR",
        destination_currency: "CAD",
        sender_id: "sender_123",
        recipient_id: "recipient_456"
      }

      {:ok, transaction} = RemittanceService.initiate_transaction(params)

      assert transaction.status == :initiated
      assert transaction.source_amount == 10000
      assert transaction.source_currency == "INR"
      assert transaction.destination_currency == "CAD"
      assert transaction.sender_id == "sender_123"
      assert transaction.recipient_id == "recipient_456"
      assert transaction.payment_link != nil
    end

    test "returns error with invalid parameters" do
      params = %{
        source_amount: -100,  # Invalid amount
        source_currency: "INR",
        destination_currency: "CAD",
        sender_id: "sender_123",
        recipient_id: "recipient_456"
      }

      {:error, reason} = RemittanceService.initiate_transaction(params)
      assert reason =~ "Invalid source amount"
    end
  end

  describe "process_payment_callback/1" do
    test "successfully processes a payment callback" do
      # First create a transaction
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => "tx_123"} -> 
        {:ok, %{
          "transaction_id" => "tx_123",
          "status" => "initiated",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_currency" => "CAD",
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      callback_params = %{
        transaction_id: "tx_123",
        payment_id: "upi_123456789",
        status: "completed",
        completed_at: DateTime.utc_now()
      }

      {:ok, transaction} = RemittanceService.process_payment_callback(callback_params)

      assert transaction.status == :funds_collected
    end

    test "handles failed payment" do
      # First create a transaction
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => "tx_123"} -> 
        {:ok, %{
          "transaction_id" => "tx_123",
          "status" => "initiated",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_currency" => "CAD",
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      callback_params = %{
        transaction_id: "tx_123",
        payment_id: "upi_123456789",
        status: "failed",
        completed_at: DateTime.utc_now(),
        failure_reason: "user_cancelled"
      }

      {:ok, transaction} = RemittanceService.process_payment_callback(callback_params)

      assert transaction.status == :failed
      assert transaction.error_message =~ "user_cancelled"
    end
  end

  describe "get_transaction/1" do
    test "returns transaction when it exists" do
      transaction_id = "tx_123"
      
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, %{
          "transaction_id" => transaction_id,
          "status" => "initiated",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_currency" => "CAD",
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      {:ok, transaction} = RemittanceService.get_transaction(transaction_id)
      
      assert transaction.transaction_id == transaction_id
      assert transaction.status == :initiated
    end

    test "returns error when transaction does not exist" do
      transaction_id = "non_existent_tx"
      
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, nil}
      end)

      {:error, reason} = RemittanceService.get_transaction(transaction_id)
      
      assert reason =~ "not found"
    end
  end

  describe "get_exchange_rate/2" do
    test "returns current exchange rate" do
      {:ok, exchange_rate} = RemittanceService.get_exchange_rate("INR", "CAD")
      
      assert exchange_rate.source_currency == "INR"
      assert exchange_rate.target_currency == "CAD"
      assert exchange_rate.rate == 0.016
      assert exchange_rate.timestamp != nil
    end

    test "returns error for unsupported currency pair" do
      Mox.stub(Remit.MockADBankClient, :get_exchange_rate, fn "XYZ", "ABC" ->
        {:error, "Unsupported currency pair"}
      end)

      {:error, reason} = RemittanceService.get_exchange_rate("XYZ", "ABC")
      
      assert reason =~ "Unsupported currency pair"
    end
  end

  describe "get_transactions_by_sender/2" do
    test "returns transactions for a sender" do
      sender_id = "sender_123"
      
      Mox.stub(Remit.MockDynamoDBClient, :query, fn _table_name, _key_condition, _opts -> 
        {:ok, [
          %{
            "transaction_id" => "tx_123",
            "status" => "completed",
            "source_amount" => 10000,
            "source_currency" => "INR",
            "destination_amount" => 160,
            "destination_currency" => "CAD",
            "sender_id" => sender_id,
            "recipient_id" => "recipient_456",
            "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "completion_time" => DateTime.utc_now() |> DateTime.to_iso8601()
          },
          %{
            "transaction_id" => "tx_124",
            "status" => "initiated",
            "source_amount" => 5000,
            "source_currency" => "INR",
            "destination_currency" => "CAD",
            "sender_id" => sender_id,
            "recipient_id" => "recipient_789",
            "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        ]}
      end)

      {:ok, transactions} = RemittanceService.get_transactions_by_sender(sender_id)
      
      assert length(transactions) == 2
      assert Enum.all?(transactions, fn tx -> tx.sender_id == sender_id end)
    end
  end

  describe "get_transactions_by_recipient/2" do
    test "returns transactions for a recipient" do
      recipient_id = "recipient_456"
      
      Mox.stub(Remit.MockDynamoDBClient, :query, fn _table_name, _key_condition, _opts -> 
        {:ok, [
          %{
            "transaction_id" => "tx_123",
            "status" => "completed",
            "source_amount" => 10000,
            "source_currency" => "INR",
            "destination_amount" => 160,
            "destination_currency" => "CAD",
            "sender_id" => "sender_123",
            "recipient_id" => recipient_id,
            "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "completion_time" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        ]}
      end)

      {:ok, transactions} = RemittanceService.get_transactions_by_recipient(recipient_id)
      
      assert length(transactions) == 1
      assert Enum.all?(transactions, fn tx -> tx.recipient_id == recipient_id end)
    end
  end

  # Test the full remittance flow
  describe "full remittance flow" do
    test "successfully completes a full remittance transaction" do
      # 1. Initiate transaction
      params = %{
        source_amount: 10000,
        source_currency: "INR",
        destination_currency: "CAD",
        sender_id: "sender_123",
        recipient_id: "recipient_456"
      }

      {:ok, transaction} = RemittanceService.initiate_transaction(params)
      transaction_id = transaction.transaction_id
      
      # Mock the transaction retrieval for subsequent steps
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, %{
          "transaction_id" => transaction_id,
          "status" => "initiated",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_currency" => "CAD",
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      # 2. Process payment callback
      callback_params = %{
        transaction_id: transaction_id,
        payment_id: "upi_123456789",
        status: "completed",
        completed_at: DateTime.utc_now()
      }

      {:ok, updated_transaction} = RemittanceService.process_payment_callback(callback_params)
      assert updated_transaction.status == :funds_collected

      # Mock the updated transaction for subsequent steps
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, %{
          "transaction_id" => transaction_id,
          "status" => "funds_collected",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_currency" => "CAD",
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      # 3. Process currency conversion (this would normally be triggered by a background job)
      {:ok, conversion_result} = RemittanceService.process_currency_conversion(transaction_id)
      assert conversion_result.status == :conversion_completed
      assert conversion_result.destination_amount == 160

      # Mock the updated transaction after conversion
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, %{
          "transaction_id" => transaction_id,
          "status" => "conversion_completed",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_amount" => 160,
          "destination_currency" => "CAD",
          "exchange_rate" => 0.016,
          "fees" => 50,
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      # 4. Process funds transmission (this would normally be triggered by a background job)
      {:ok, transmission_result} = RemittanceService.process_funds_transmission(transaction_id)
      assert transmission_result.status == :completed

      # 5. Verify final transaction state
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, %{
          "transaction_id" => transaction_id,
          "status" => "completed",
          "source_amount" => 10000,
          "source_currency" => "INR",
          "destination_amount" => 160,
          "destination_currency" => "CAD",
          "exchange_rate" => 0.016,
          "fees" => 50,
          "sender_id" => "sender_123",
          "recipient_id" => "recipient_456",
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "completion_time" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      {:ok, final_transaction} = RemittanceService.get_transaction(transaction_id)
      assert final_transaction.status == :completed
      assert final_transaction.destination_amount == 160
      assert final_transaction.completion_time != nil
    end
  end
end 