defmodule SummerChallengeWeb.PageController do
  use SummerChallengeWeb, :controller

  import Phoenix.Controller

  def home(conn, _params) do
    conn
    |> redirect(to: "/leaderboard/running")
  end
end
