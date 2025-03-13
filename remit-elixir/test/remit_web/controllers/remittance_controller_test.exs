defmodule RemitWeb.RemittanceControllerTest do
  use RemitWeb.ConnCase
  alias Remit.Remittance.RemittanceService
  alias Remit.Remittance.Transaction

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup %{conn: conn} do
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

    # Mock Wise client
    Mox.stub(Remit.MockWiseClient, :transfer_funds, fn _transaction_id, _amount, _currency, _recipient_id ->
      {:ok, %{transaction_id: "wise_tx_123", status: "completed"}}
    end)

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create remittance" do
    test "renders transaction when data is valid", %{conn: conn} do
      create_params = %{
        source_amount: 10000,
        source_currency: "INR",
        destination_currency: "CAD",
        sender_id: "sender_123",
        recipient_id: "recipient_456"
      }

      conn = post(conn, ~p"/api/remittances", create_params)
      assert %{"transaction_id" => transaction_id} = json_response(conn, 201)["data"]
      assert %{"status" => "initiated"} = json_response(conn, 201)["data"]
      assert %{"payment_link" => _link} = json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      create_params = %{
        source_amount: -100,  # Invalid amount
        source_currency: "INR",
        destination_currency: "CAD",
        sender_id: "sender_123",
        recipient_id: "recipient_456"
      }

      conn = post(conn, ~p"/api/remittances", create_params)
      assert json_response(conn, 400)["error"] != nil
    end
  end

  describe "show transaction" do
    test "renders transaction when it exists", %{conn: conn} do
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
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      conn = get(conn, ~p"/api/remittances/#{transaction_id}")
      assert json_response(conn, 200)["data"]["transaction_id"] == transaction_id
    end

    test "renders 404 when transaction doesn't exist", %{conn: conn} do
      transaction_id = "non_existent_tx"
      
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, nil}
      end)

      conn = get(conn, ~p"/api/remittances/#{transaction_id}")
      assert json_response(conn, 404)["error"]["message"] =~ "not found"
    end
  end

  describe "get transactions by sender" do
    test "renders transactions when sender has transactions", %{conn: conn} do
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

      conn = get(conn, ~p"/api/remittances/sender/#{sender_id}")
      assert json_response(conn, 200)["data"] |> length() == 2
    end

    test "renders empty list when sender has no transactions", %{conn: conn} do
      sender_id = "sender_with_no_tx"
      
      Mox.stub(Remit.MockDynamoDBClient, :query, fn _table_name, _key_condition, _opts -> 
        {:ok, []}
      end)

      conn = get(conn, ~p"/api/remittances/sender/#{sender_id}")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "get transactions by recipient" do
    test "renders transactions when recipient has transactions", %{conn: conn} do
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

      conn = get(conn, ~p"/api/remittances/recipient/#{recipient_id}")
      assert json_response(conn, 200)["data"] |> length() == 1
    end
  end

  describe "get exchange rate" do
    test "renders exchange rate for valid currency pair", %{conn: conn} do
      conn = get(conn, ~p"/api/exchange-rates?source=INR&target=CAD")
      
      assert %{
        "source_currency" => "INR",
        "target_currency" => "CAD",
        "rate" => 0.016
      } = json_response(conn, 200)["data"]
    end

    test "renders error for invalid currency pair", %{conn: conn} do
      Mox.stub(Remit.MockADBankClient, :get_exchange_rate, fn "XYZ", "ABC" ->
        {:error, "Unsupported currency pair"}
      end)

      conn = get(conn, ~p"/api/exchange-rates?source=XYZ&target=ABC")
      assert json_response(conn, 400)["error"]["message"] =~ "Unsupported currency pair"
    end
  end

  describe "payment callback" do
    test "processes successful payment callback", %{conn: conn} do
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
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      callback_params = %{
        transaction_id: transaction_id,
        payment_id: "upi_123456789",
        status: "completed",
        completed_at: DateTime.utc_now()
      }

      conn = post(conn, ~p"/api/callbacks/payment", callback_params)
      assert json_response(conn, 200)["data"]["status"] == "funds_collected"
    end

    test "processes failed payment callback", %{conn: conn} do
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
          "payment_link" => "https://upi-provider.com/pay/123456789",
          "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }}
      end)

      callback_params = %{
        transaction_id: transaction_id,
        payment_id: "upi_123456789",
        status: "failed",
        completed_at: DateTime.utc_now(),
        failure_reason: "user_cancelled"
      }

      conn = post(conn, ~p"/api/callbacks/payment", callback_params)
      assert json_response(conn, 200)["data"]["status"] == "failed"
      assert json_response(conn, 200)["data"]["error_message"] =~ "user_cancelled"
    end

    test "renders error for invalid transaction in callback", %{conn: conn} do
      transaction_id = "non_existent_tx"
      
      Mox.stub(Remit.MockDynamoDBClient, :get_item, fn _table_name, %{"transaction_id" => ^transaction_id} -> 
        {:ok, nil}
      end)

      callback_params = %{
        transaction_id: transaction_id,
        payment_id: "upi_123456789",
        status: "completed",
        completed_at: DateTime.utc_now()
      }

      conn = post(conn, ~p"/api/callbacks/payment", callback_params)
      assert json_response(conn, 404)["error"]["message"] =~ "not found"
    end
  end
end 