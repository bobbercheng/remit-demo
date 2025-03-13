defmodule Remit.Mocks do
  @moduledoc """
  Mocks for external dependencies.
  """

  # Define mocks for external dependencies
  Mox.defmock(Remit.MockDynamoDBClient, for: Remit.Persistence.DynamoDBClient)
  Mox.defmock(Remit.MockUPIClient, for: Remit.Partners.UPI.UPIClient)
  Mox.defmock(Remit.MockADBankClient, for: Remit.Partners.ADBank.ADBankClient)
  Mox.defmock(Remit.MockWiseClient, for: Remit.Partners.Wise.WiseClient)
end 