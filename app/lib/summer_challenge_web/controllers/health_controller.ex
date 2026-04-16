defmodule SummerChallengeWeb.HealthController do
  use SummerChallengeWeb, :controller

  @doc """
  Liveness probe for Kamal / Docker (see `config/deploy.yml` proxy healthcheck path `/up`).
  """
  def up(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end
