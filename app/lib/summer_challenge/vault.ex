defmodule SummerChallenge.Vault do
  @moduledoc """
  Vault for encrypting sensitive data at rest.

  This module uses Cloak to provide encryption capabilities for sensitive fields
  in the database, such as OAuth tokens and credentials. The vault configuration
  is loaded from the application environment.
  """
  use Cloak.Vault, otp_app: :summer_challenge
end
