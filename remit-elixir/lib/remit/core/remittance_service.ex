defmodule Remit.Core.RemittanceService do
  @moduledoc """
  Core service for handling remittance operations.
  
  This service orchestrates the entire remittance process from India to Canada:
  1. Collect funds in India via UPI
  2. Convert currency from INR to CAD via AD Bank
  3. Transmit funds to Canada via Wise
  """
  
  require Logger
  
  alias Remit.Core.TransactionStatus
  alias Remit.Integrations.{UPIClient, ADBankClient, WiseClient}
  alias Remit.Persistence.Repositories.{TransactionRepository, TransactionEventRepository}
  alias Remit.Persistence.Schemas.Transaction

  @doc """
  Initiates a new remittance transaction.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec initiate_remittance(map()) :: {:ok, Transaction.t()} | {:error, term()}
  def initiate_remittance(params) do
    Logger.info("Initiating remittance: #{inspect(params)}")
    
    with :ok <- validate_remittance_params(params),
         {:ok, exchange_rate} <- get_exchange_rate(params.source_currency, params.destination_currency),
         {:ok, transaction} <- create_transaction(params, exchange_rate),
         {:ok, payment_link} <- generate_payment_link(transaction) do
      
      # Record the payment link in transaction metadata
      updated_transaction = %{transaction | metadata: Map.put(transaction.metadata, :payment_link, payment_link)}
      {:ok, _} = TransactionRepository.update(updated_transaction)
      
      # Record event
      TransactionEventRepository.record_system_event(
        transaction.transaction_id,
        "payment_link_generated",
        %{payment_link: payment_link}
      )
      
      {:ok, updated_transaction}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Processes a UPI payment callback.
  
  This is called when a UPI payment is completed or failed.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec process_payment_callback(String.t(), map()) :: {:ok, Transaction.t()} | {:error, term()}
  def process_payment_callback(transaction_id, payment_details) do
    Logger.info("Processing payment callback for transaction: #{transaction_id}")
    
    with {:ok, transaction} <- TransactionRepository.get(transaction_id),
         :ok <- validate_transaction_status(transaction, :initiated),
         {:ok, payment_status} <- verify_payment(payment_details) do
      
      if payment_status == "completed" do
        # Update transaction status to funds_collected
        {:ok, updated_transaction} = TransactionRepository.update_status(
          transaction_id, 
          :funds_collected,
          %{metadata: Map.put(transaction.metadata, :payment_id, payment_details["payment_id"])}
        )
        
        # Record event
        TransactionEventRepository.record_status_change(
          transaction_id,
          transaction.status,
          updated_transaction.status,
          "upi",
          %{payment_id: payment_details["payment_id"]}
        )
        
        # Automatically start currency conversion
        Task.start(fn -> start_currency_conversion(updated_transaction) end)
        
        {:ok, updated_transaction}
      else
        # Payment failed, mark transaction as failed
        {:ok, failed_transaction} = TransactionRepository.update_status(
          transaction_id,
          :failed,
          %{
            error_message: "Payment failed: #{payment_details["failure_reason"]}",
            error_code: "payment_failed"
          }
        )
        
        # Record event
        TransactionEventRepository.record_status_change(
          transaction_id,
          transaction.status,
          failed_transaction.status,
          "upi",
          %{
            payment_id: payment_details["payment_id"],
            failure_reason: payment_details["failure_reason"]
          }
        )
        
        {:ok, failed_transaction}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Starts the currency conversion process.
  
  This is called after funds are collected in India.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec start_currency_conversion(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def start_currency_conversion(transaction) do
    Logger.info("Starting currency conversion for transaction: #{transaction.transaction_id}")
    
    with :ok <- validate_transaction_status(transaction, :funds_collected),
         {:ok, updated_transaction} <- TransactionRepository.update_status(
           transaction.transaction_id, 
           :conversion_in_progress
         ),
         {:ok, conversion} <- initiate_currency_conversion(updated_transaction) do
      
      # Record event
      TransactionEventRepository.record_status_change(
        transaction.transaction_id,
        transaction.status,
        updated_transaction.status,
        "system",
        %{conversion_id: conversion["conversion_id"]}
      )
      
      # Store conversion ID in metadata
      metadata = Map.put(updated_transaction.metadata, :conversion_id, conversion["conversion_id"])
      {:ok, transaction_with_metadata} = TransactionRepository.update(%{updated_transaction | metadata: metadata})
      
      # Start a background task to check conversion status
      Task.start(fn -> 
        # Wait a bit before checking status
        :timer.sleep(5000)
        check_conversion_status(transaction_with_metadata) 
      end)
      
      {:ok, transaction_with_metadata}
    else
      {:error, reason} -> 
        # Handle conversion initiation failure
        {:ok, failed_transaction} = TransactionRepository.update_status(
          transaction.transaction_id,
          :failed,
          %{
            error_message: "Currency conversion failed: #{inspect(reason)}",
            error_code: "conversion_initiation_failed"
          }
        )
        
        # Record event
        TransactionEventRepository.record_status_change(
          transaction.transaction_id,
          transaction.status,
          failed_transaction.status,
          "system",
          %{error: inspect(reason)}
        )
        
        {:error, reason}
    end
  end

  @doc """
  Checks the status of a currency conversion.
  
  This is called periodically after conversion is initiated.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec check_conversion_status(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def check_conversion_status(transaction) do
    Logger.info("Checking conversion status for transaction: #{transaction.transaction_id}")
    
    conversion_id = transaction.metadata[:conversion_id]
    
    with :ok <- validate_transaction_status(transaction, :conversion_in_progress),
         {:ok, conversion_status} <- ADBankClient.check_conversion_status(conversion_id) do
      
      case conversion_status["status"] do
        "completed" ->
          # Update transaction status to conversion_completed
          {:ok, updated_transaction} = TransactionRepository.update_status(
            transaction.transaction_id, 
            :conversion_completed
          )
          
          # Record event
          TransactionEventRepository.record_status_change(
            transaction.transaction_id,
            transaction.status,
            updated_transaction.status,
            "ad_bank",
            %{conversion_id: conversion_id}
          )
          
          # Start transmission to Canada
          Task.start(fn -> start_transmission(updated_transaction) end)
          
          {:ok, updated_transaction}
          
        "failed" ->
          # Conversion failed, mark transaction as failed
          {:ok, failed_transaction} = TransactionRepository.update_status(
            transaction.transaction_id,
            :failed,
            %{
              error_message: "Currency conversion failed: #{conversion_status["failure_reason"]}",
              error_code: "conversion_failed"
            }
          )
          
          # Record event
          TransactionEventRepository.record_status_change(
            transaction.transaction_id,
            transaction.status,
            failed_transaction.status,
            "ad_bank",
            %{
              conversion_id: conversion_id,
              failure_reason: conversion_status["failure_reason"]
            }
          )
          
          {:ok, failed_transaction}
          
        "processing" ->
          # Still processing, check again later
          TransactionEventRepository.record_partner_event(
            transaction.transaction_id,
            "ad_bank",
            "conversion_processing",
            %{conversion_id: conversion_id}
          )
          
          # Schedule another check
          Task.start(fn -> 
            :timer.sleep(10000)  # Wait 10 seconds
            check_conversion_status(transaction) 
          end)
          
          {:ok, transaction}
      end
    else
      {:error, reason} -> 
        # Handle conversion status check failure
        Logger.error("Failed to check conversion status: #{inspect(reason)}")
        
        # Record event
        TransactionEventRepository.record_partner_event(
          transaction.transaction_id,
          "ad_bank",
          "conversion_status_check_failed",
          %{error: inspect(reason)}
        )
        
        # Schedule another check
        Task.start(fn -> 
          :timer.sleep(30000)  # Wait 30 seconds
          check_conversion_status(transaction) 
        end)
        
        {:error, reason}
    end
  end

  @doc """
  Starts the transmission of funds to Canada via Wise.
  
  This is called after currency conversion is completed.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec start_transmission(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def start_transmission(transaction) do
    Logger.info("Starting transmission to Canada for transaction: #{transaction.transaction_id}")
    
    with :ok <- validate_transaction_status(transaction, :conversion_completed),
         {:ok, updated_transaction} <- TransactionRepository.update_status(
           transaction.transaction_id, 
           :transmission_in_progress
         ),
         {:ok, transfer} <- create_wise_transfer(updated_transaction),
         {:ok, _funding} <- fund_wise_transfer(transfer["id"], updated_transaction) do
      
      # Record event
      TransactionEventRepository.record_status_change(
        transaction.transaction_id,
        transaction.status,
        updated_transaction.status,
        "system",
        %{transfer_id: transfer["id"]}
      )
      
      # Store transfer ID in metadata
      metadata = Map.put(updated_transaction.metadata, :transfer_id, transfer["id"])
      {:ok, transaction_with_metadata} = TransactionRepository.update(%{updated_transaction | metadata: metadata})
      
      # Start a background task to check transfer status
      Task.start(fn -> 
        # Wait a bit before checking status
        :timer.sleep(5000)
        check_transfer_status(transaction_with_metadata) 
      end)
      
      {:ok, transaction_with_metadata}
    else
      {:error, reason} -> 
        # Handle transmission initiation failure
        {:ok, failed_transaction} = TransactionRepository.update_status(
          transaction.transaction_id,
          :failed,
          %{
            error_message: "Transmission to Canada failed: #{inspect(reason)}",
            error_code: "transmission_initiation_failed"
          }
        )
        
        # Record event
        TransactionEventRepository.record_status_change(
          transaction.transaction_id,
          transaction.status,
          failed_transaction.status,
          "system",
          %{error: inspect(reason)}
        )
        
        {:error, reason}
    end
  end

  @doc """
  Checks the status of a Wise transfer.
  
  This is called periodically after transmission is initiated.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec check_transfer_status(Transaction.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def check_transfer_status(transaction) do
    Logger.info("Checking transfer status for transaction: #{transaction.transaction_id}")
    
    transfer_id = transaction.metadata[:transfer_id]
    
    with :ok <- validate_transaction_status(transaction, :transmission_in_progress),
         {:ok, transfer_status} <- WiseClient.get_transfer(transfer_id) do
      
      case transfer_status["status"] do
        "outgoing_payment_sent" ->
          # Update transaction status to completed
          {:ok, updated_transaction} = TransactionRepository.update_status(
            transaction.transaction_id, 
            :completed
          )
          
          # Record event
          TransactionEventRepository.record_status_change(
            transaction.transaction_id,
            transaction.status,
            updated_transaction.status,
            "wise",
            %{
              transfer_id: transfer_id,
              estimated_delivery_date: transfer_status["estimatedDeliveryDate"]
            }
          )
          
          {:ok, updated_transaction}
          
        "failed" ->
          # Transfer failed, mark transaction as failed
          {:ok, failed_transaction} = TransactionRepository.update_status(
            transaction.transaction_id,
            :failed,
            %{
              error_message: "Transfer to Canada failed: #{transfer_status["errorMessage"]}",
              error_code: transfer_status["errorCode"]
            }
          )
          
          # Record event
          TransactionEventRepository.record_status_change(
            transaction.transaction_id,
            transaction.status,
            failed_transaction.status,
            "wise",
            %{
              transfer_id: transfer_id,
              error_code: transfer_status["errorCode"],
              error_message: transfer_status["errorMessage"]
            }
          )
          
          {:ok, failed_transaction}
          
        _ ->
          # Still processing, check again later
          TransactionEventRepository.record_partner_event(
            transaction.transaction_id,
            "wise",
            "transfer_processing",
            %{
              transfer_id: transfer_id,
              status: transfer_status["status"]
            }
          )
          
          # Schedule another check
          Task.start(fn -> 
            :timer.sleep(10000)  # Wait 10 seconds
            check_transfer_status(transaction) 
          end)
          
          {:ok, transaction}
      end
    else
      {:error, reason} -> 
        # Handle transfer status check failure
        Logger.error("Failed to check transfer status: #{inspect(reason)}")
        
        # Record event
        TransactionEventRepository.record_partner_event(
          transaction.transaction_id,
          "wise",
          "transfer_status_check_failed",
          %{error: inspect(reason)}
        )
        
        # Schedule another check
        Task.start(fn -> 
          :timer.sleep(30000)  # Wait 30 seconds
          check_transfer_status(transaction) 
        end)
        
        {:error, reason}
    end
  end

  @doc """
  Gets a transaction by ID.
  
  Returns:
  - `{:ok, transaction}` on success
  - `{:error, reason}` on failure
  """
  @spec get_transaction(String.t()) :: {:ok, Transaction.t()} | {:error, term()}
  def get_transaction(transaction_id) do
    TransactionRepository.get(transaction_id)
  end

  @doc """
  Gets transactions by sender ID.
  
  Returns:
  - `{:ok, [transaction]}` on success
  - `{:error, reason}` on failure
  """
  @spec get_transactions_by_sender(String.t(), integer()) :: {:ok, [Transaction.t()]} | {:error, term()}
  def get_transactions_by_sender(sender_id, limit \\ 10) do
    TransactionRepository.get_by_sender(sender_id, limit)
  end

  @doc """
  Gets transactions by recipient ID.
  
  Returns:
  - `{:ok, [transaction]}` on success
  - `{:error, reason}` on failure
  """
  @spec get_transactions_by_recipient(String.t(), integer()) :: {:ok, [Transaction.t()]} | {:error, term()}
  def get_transactions_by_recipient(recipient_id, limit \\ 10) do
    TransactionRepository.get_by_recipient(recipient_id, limit)
  end

  @doc """
  Gets the current exchange rate from source to destination currency.
  
  Returns:
  - `{:ok, rate}` on success
  - `{:error, reason}` on failure
  """
  @spec get_current_exchange_rate(String.t(), String.t()) :: {:ok, float()} | {:error, term()}
  def get_current_exchange_rate(source_currency, destination_currency) do
    with {:ok, rate_details} <- ADBankClient.get_exchange_rate(source_currency, destination_currency) do
      {:ok, rate_details["rate"]}
    end
  end

  # Private functions

  defp validate_remittance_params(params) do
    # Get configuration
    config = Application.get_env(:remit, :remittance)
    min_amount = config[:min_transaction_amount_inr]
    max_amount = config[:max_transaction_amount_inr]
    
    cond do
      !Map.has_key?(params, :source_amount) ->
        {:error, "Source amount is required"}
        
      !Map.has_key?(params, :source_currency) ->
        {:error, "Source currency is required"}
        
      !Map.has_key?(params, :destination_currency) ->
        {:error, "Destination currency is required"}
        
      !Map.has_key?(params, :sender_id) ->
        {:error, "Sender ID is required"}
        
      !Map.has_key?(params, :recipient_id) ->
        {:error, "Recipient ID is required"}
        
      params.source_currency != "INR" ->
        {:error, "Source currency must be INR"}
        
      params.destination_currency != "CAD" ->
        {:error, "Destination currency must be CAD"}
        
      params.source_amount < min_amount ->
        {:error, "Source amount must be at least #{min_amount} INR"}
        
      params.source_amount > max_amount ->
        {:error, "Source amount must be at most #{max_amount} INR"}
        
      true ->
        :ok
    end
  end

  defp validate_transaction_status(transaction, expected_status) do
    if transaction.status == expected_status do
      :ok
    else
      {:error, "Invalid transaction status: expected #{expected_status}, got #{transaction.status}"}
    end
  end

  defp get_exchange_rate(source_currency, destination_currency) do
    with {:ok, rate_details} <- ADBankClient.get_exchange_rate(source_currency, destination_currency) do
      {:ok, rate_details["rate"]}
    end
  end

  defp create_transaction(params, exchange_rate) do
    # Calculate fees
    config = Application.get_env(:remit, :remittance)
    base_fee_percentage = config[:base_fee_percentage]
    min_fee = config[:min_fee_inr]
    
    calculated_fee = params.source_amount * (base_fee_percentage / 100)
    fee = max(calculated_fee, min_fee)
    
    # Calculate destination amount
    net_amount = params.source_amount - fee
    destination_amount = net_amount * exchange_rate
    
    # Create transaction
    transaction = Transaction.new(%{
      source_amount: params.source_amount,
      source_currency: params.source_currency,
      destination_amount: destination_amount,
      destination_currency: params.destination_currency,
      exchange_rate: exchange_rate,
      fees: fee,
      sender_id: params.sender_id,
      recipient_id: params.recipient_id
    })
    
    TransactionRepository.create(transaction)
  end

  defp generate_payment_link(transaction) do
    payment_params = %{
      "amount" => transaction.source_amount,
      "currency" => transaction.source_currency,
      "description" => "Remittance to Canada",
      "reference" => transaction.transaction_id
    }
    
    with {:ok, payment_link_details} <- UPIClient.generate_payment_link(payment_params) do
      {:ok, payment_link_details["payment_link"]}
    end
  end

  defp verify_payment(payment_details) do
    payment_id = payment_details["payment_id"]
    
    with {:ok, payment_status} <- UPIClient.verify_payment(payment_id) do
      {:ok, payment_status["status"]}
    end
  end

  defp initiate_currency_conversion(transaction) do
    conversion_params = %{
      "source_amount" => transaction.source_amount - transaction.fees,
      "source_currency" => transaction.source_currency,
      "target_currency" => transaction.destination_currency,
      "reference" => transaction.transaction_id
    }
    
    ADBankClient.initiate_conversion(conversion_params)
  end

  defp create_wise_transfer(transaction) do
    # First create a quote
    quote_params = %{
      "sourceAmount" => transaction.destination_amount,
      "sourceCurrency" => transaction.destination_currency,
      "targetCurrency" => transaction.destination_currency,
      "profile" => "personal"  # This would come from configuration in a real system
    }
    
    with {:ok, quote_details} <- WiseClient.create_quote(quote_params),
         # Then create a transfer using the quote
         transfer_params = %{
           "quoteId" => quote_details["id"],
           "targetAccount" => transaction.recipient_id,  # In a real system, this would be a Wise account ID
           "reference" => transaction.transaction_id,
           "sourceAmount" => quote_details["sourceAmount"],
           "targetAmount" => quote_details["targetAmount"],
           "sourceCurrency" => quote_details["sourceCurrency"],
           "targetCurrency" => quote_details["targetCurrency"]
         },
         {:ok, transfer} <- WiseClient.create_transfer(transfer_params) do
      
      # Store quote ID in metadata
      metadata = Map.put(transaction.metadata, :quote_id, quote_details["id"])
      {:ok, _} = TransactionRepository.update(%{transaction | metadata: metadata})
      
      {:ok, transfer}
    end
  end

  defp fund_wise_transfer(transfer_id, transaction) do
    funding_params = %{
      "type" => "balance"  # In a real system, this would be configurable
    }
    
    WiseClient.fund_transfer(transfer_id, funding_params)
  end
end 