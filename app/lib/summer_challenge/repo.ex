defmodule SummerChallenge.Repo do
  use Ecto.Repo,
    otp_app: :summer_challenge,
    adapter: Ecto.Adapters.Postgres
end
