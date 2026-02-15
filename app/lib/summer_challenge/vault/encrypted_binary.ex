defmodule SummerChallenge.Vault.Encrypted.Binary do
  @moduledoc """
  Custom Ecto type for encrypted binary fields.

  This type automatically encrypts data when writing to the database and decrypts
  when reading. Used for storing sensitive information like OAuth access tokens
  and refresh tokens.
  """
  use Cloak.Ecto.Binary, vault: SummerChallenge.Vault
end
