defmodule SummerChallengeWeb.HealthControllerTest do
  use SummerChallengeWeb.ConnCase, async: true

  test "GET /up returns 200 for proxy health checks", %{conn: conn} do
    conn = get(conn, ~p"/up")
    assert response(conn, 200) == "OK"
  end
end
