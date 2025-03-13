defmodule RemitWeb.RemittanceView do
  use RemitWeb, :view
  
  alias Remit.Persistence.Schemas.Transaction

  def render("transaction.json", %{transaction: transaction}) do
    %{
      transaction_id: transaction.transaction_id,
      status: transaction.status,
      source_amount: transaction.source_amount,
      source_currency: transaction.source_currency,
      destination_amount: transaction.destination_amount,
      destination_currency: transaction.destination_currency,
      exchange_rate: transaction.exchange_rate,
      fees: transaction.fees,
      sender_id: transaction.sender_id,
      recipient_id: transaction.recipient_id,
      created_at: transaction.created_at,
      updated_at: transaction.updated_at,
      completion_time: transaction.completion_time,
      error_message: transaction.error_message,
      error_code: transaction.error_code,
      payment_link: transaction.metadata[:payment_link]
    }
  end

  def render("transactions.json", %{transactions: transactions}) do
    %{
      data: Enum.map(transactions, &render("transaction.json", %{transaction: &1}))
    }
  end

  def render("exchange_rate.json", %{source_currency: source, target_currency: target, rate: rate, timestamp: timestamp}) do
    %{
      source_currency: source,
      target_currency: target,
      rate: rate,
      timestamp: timestamp
    }
  end
end 