ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SummerChallenge.Repo, :manual)

Mox.defmock(SummerChallenge.OAuth.StravaMock, for: SummerChallenge.OAuth.Strava.API)
