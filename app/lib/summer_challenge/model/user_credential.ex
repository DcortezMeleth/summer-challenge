defmodule SummerChallenge.Model.UserCredential do
  @moduledoc """
  Schema for storing encrypted user credentials.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:user_id, :binary_id, autogenerate: false}
  schema "user_credentials" do
    field :access_token, SummerChallenge.Vault.Encrypted.Binary, source: :access_token_enc
    field :refresh_token, SummerChallenge.Vault.Encrypted.Binary, source: :refresh_token_enc
    field :expires_at, :utc_datetime_usec

    belongs_to :user, SummerChallenge.Model.User, define_field: false

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:user_id, :access_token, :refresh_token, :expires_at])
    |> validate_required([:user_id, :access_token, :refresh_token, :expires_at])
    |> foreign_key_constraint(:user_id)
  end
end
