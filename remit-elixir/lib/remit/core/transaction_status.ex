defmodule Remit.Core.TransactionStatus do
  @moduledoc """
  Defines the possible states of a remittance transaction.

  Flow:
  INITIATED -> FUNDS_COLLECTED -> CONVERSION_IN_PROGRESS -> CONVERSION_COMPLETED -> TRANSMISSION_IN_PROGRESS -> COMPLETED
  
  At any stage, a transaction can move to FAILED state.
  """

  @type t ::
          :initiated
          | :funds_collected
          | :conversion_in_progress
          | :conversion_completed
          | :transmission_in_progress
          | :completed
          | :failed

  @statuses [
    :initiated,
    :funds_collected,
    :conversion_in_progress,
    :conversion_completed,
    :transmission_in_progress,
    :completed,
    :failed
  ]

  @doc """
  Returns a list of all possible transaction statuses.
  """
  @spec all() :: [t()]
  def all, do: @statuses

  @doc """
  Checks if a status is valid.
  """
  @spec valid?(any()) :: boolean()
  def valid?(status) when status in @statuses, do: true
  def valid?(_), do: false

  @doc """
  Converts a string to a transaction status atom.
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_status}
  def from_string(status_str) when is_binary(status_str) do
    status_atom = String.downcase(status_str) |> String.to_atom()
    if valid?(status_atom), do: {:ok, status_atom}, else: {:error, :invalid_status}
  end

  def from_string(_), do: {:error, :invalid_status}

  @doc """
  Checks if a transition from one status to another is valid.
  """
  @spec valid_transition?(t(), t()) :: boolean()
  def valid_transition?(from, to) do
    case from do
      :initiated -> to in [:funds_collected, :failed]
      :funds_collected -> to in [:conversion_in_progress, :failed]
      :conversion_in_progress -> to in [:conversion_completed, :failed]
      :conversion_completed -> to in [:transmission_in_progress, :failed]
      :transmission_in_progress -> to in [:completed, :failed]
      :completed -> false
      :failed -> false
      _ -> false
    end
  end

  @doc """
  Gets the next valid statuses for a given status.
  """
  @spec next_statuses(t()) :: [t()]
  def next_statuses(status) do
    @statuses
    |> Enum.filter(fn next_status -> valid_transition?(status, next_status) end)
  end

  @doc """
  Checks if a status is a terminal status (no further transitions possible).
  """
  @spec terminal?(t()) :: boolean()
  def terminal?(status), do: status in [:completed, :failed]

  @doc """
  Checks if a status is a success status.
  """
  @spec success?(t()) :: boolean()
  def success?(status), do: status == :completed
end 