defmodule SummerChallengeWeb.PageController do
  use SummerChallengeWeb, :controller

  import Phoenix.Controller

  def home(conn, _params) do
    redirect(conn, to: "/leaderboard")
  end
end
