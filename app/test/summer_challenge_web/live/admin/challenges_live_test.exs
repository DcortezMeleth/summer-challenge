defmodule SummerChallengeWeb.Admin.ChallengesLiveTest do
  use SummerChallengeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SummerChallenge.{Repo, Challenges}
  alias SummerChallenge.Model.User

  describe "Admin Challenges LiveView - Authorization" do
    test "redirects non-authenticated users to leaderboard", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/leaderboard/running"}}} =
               live(conn, ~p"/admin/challenges")
    end

    test "allows authenticated admin users to access", %{conn: conn} do
      admin_user = create_admin_user()
      conn = authenticate_conn(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/challenges")

      assert html =~ "Manage Challenges"
      assert html =~ "New Challenge"
    end

    test "authenticated non-admin users can access (authorization should be in context)", %{
      conn: conn
    } do
      regular_user = create_regular_user()
      conn = authenticate_conn(conn, regular_user)

      # The route is protected by authenticated session, but admin-specific
      # functionality should be controlled at the context level
      {:ok, _view, html} = live(conn, ~p"/admin/challenges")

      assert html =~ "Manage Challenges"
    end
  end

  describe "Listing Challenges" do
    setup do
      admin_user = create_admin_user()
      %{admin_user: admin_user}
    end

    test "displays all challenges including archived for admins", %{
      conn: conn,
      admin_user: admin_user
    } do
      # Create challenges with different statuses
      {:ok, _active} =
        Challenges.create_challenge(%{
          name: "Active Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -5, :day),
          end_date: DateTime.add(DateTime.utc_now(), 15, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      {:ok, _inactive} =
        Challenges.create_challenge(%{
          name: "Inactive Challenge",
          start_date: DateTime.add(DateTime.utc_now(), 30, :day),
          end_date: DateTime.add(DateTime.utc_now(), 60, :day),
          allowed_sport_types: ["Ride"],
          status: "inactive"
        })

      {:ok, past} =
        Challenges.create_challenge(%{
          name: "Past Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -30, :day),
          end_date: DateTime.add(DateTime.utc_now(), -5, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      {:ok, _archived} = Challenges.archive_challenge(past)

      conn = authenticate_conn(conn, admin_user)
      {:ok, _view, html} = live(conn, ~p"/admin/challenges")

      # Should display all challenges
      assert html =~ "Active Challenge"
      assert html =~ "Inactive Challenge"
      assert html =~ "Past Challenge"
      assert html =~ "Archived"
    end

    test "displays challenge details correctly", %{conn: conn, admin_user: admin_user} do
      {:ok, _challenge} =
        Challenges.create_challenge(%{
          name: "Test Challenge",
          start_date: ~U[2026-06-01 00:00:00Z],
          end_date: ~U[2026-08-31 23:59:59Z],
          allowed_sport_types: ["Run", "TrailRun", "Ride"],
          status: "active"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, _view, html} = live(conn, ~p"/admin/challenges")

      assert html =~ "Test Challenge"
      assert html =~ "Jun 01, 2026"
      assert html =~ "Aug 31, 2026"
      assert html =~ "Run"
      assert html =~ "TrailRun"
      assert html =~ "Ride"
    end

    test "shows correct action buttons based on challenge state", %{
      conn: conn,
      admin_user: admin_user
    } do
      # Future challenge - can delete
      {:ok, future} =
        Challenges.create_challenge(%{
          name: "Future Challenge",
          start_date: DateTime.add(DateTime.utc_now(), 30, :day),
          end_date: DateTime.add(DateTime.utc_now(), 60, :day),
          allowed_sport_types: ["Run"],
          status: "inactive"
        })

      # Past challenge - can archive
      {:ok, past} =
        Challenges.create_challenge(%{
          name: "Past Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -30, :day),
          end_date: DateTime.add(DateTime.utc_now(), -5, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges")

      # Check that delete button exists for future challenge
      assert view
             |> element("button[phx-click='delete'][phx-value-id='#{future.id}']")
             |> has_element?()

      # Check that archive button exists for past challenge
      assert view
             |> element("button[phx-click='archive'][phx-value-id='#{past.id}']")
             |> has_element?()
    end
  end

  describe "Creating a Challenge" do
    setup do
      admin_user = create_admin_user()
      %{admin_user: admin_user}
    end

    test "renders new challenge form", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      {:ok, _view, html} = live(conn, ~p"/admin/challenges/new")

      assert html =~ "New Challenge"
      assert html =~ "Challenge Name"
      assert html =~ "Start Date"
      assert html =~ "End Date"
      assert html =~ "Allowed Sport Types"
      assert html =~ "Running (Outdoor)"
      assert html =~ "Cycling (Outdoor)"
    end

    test "creates challenge with valid data", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/new")

      start_date = DateTime.add(DateTime.utc_now(), 10, :day)
      end_date = DateTime.add(DateTime.utc_now(), 40, :day)

      view
      |> form("#challenge-form", %{
        challenge: %{
          name: "New Test Challenge",
          start_date: format_datetime_local(start_date),
          end_date: format_datetime_local(end_date),
          allowed_sport_types: ["Run", "Ride"],
          status: "inactive"
        }
      })
      |> render_submit()

      # Verify challenge was created in database
      challenges = Challenges.list_challenges()
      created_challenge = Enum.find(challenges, &(&1.name == "New Test Challenge"))
      assert created_challenge
      assert created_challenge.allowed_sport_types == ["Run", "Ride"]
    end

    test "shows validation errors for invalid data", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/new")

      # Submit with empty name
      html =
        view
        |> form("#challenge-form", %{
          challenge: %{
            name: "",
            start_date: format_datetime_local(DateTime.utc_now()),
            end_date: format_datetime_local(DateTime.add(DateTime.utc_now(), 10, :day)),
            allowed_sport_types: ["Run"]
          }
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "validates minimum 7-day duration", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/new")

      start_date = DateTime.utc_now()
      end_date = DateTime.add(start_date, 5, :day)

      view
      |> form("#challenge-form", %{
        challenge: %{
          name: "Short Challenge",
          start_date: format_datetime_local(start_date),
          end_date: format_datetime_local(end_date),
          allowed_sport_types: ["Run"],
          status: "active"
        }
      })
      |> render_submit()

      # Verify challenge was NOT created due to validation error
      challenges = Challenges.list_challenges()
      refute Enum.any?(challenges, &(&1.name == "Short Challenge"))
    end

    test "requires at least one sport type", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/new")

      start_date = DateTime.utc_now()
      end_date = DateTime.add(start_date, 10, :day)

      view
      |> form("#challenge-form", %{
        challenge: %{
          name: "No Sports Challenge",
          start_date: format_datetime_local(start_date),
          end_date: format_datetime_local(end_date),
          allowed_sport_types: [],
          status: "active"
        }
      })
      |> render_submit()

      # Verify challenge was NOT created due to validation error
      challenges = Challenges.list_challenges()
      refute Enum.any?(challenges, &(&1.name == "No Sports Challenge"))
    end
  end

  describe "Editing a Challenge" do
    setup do
      admin_user = create_admin_user()

      {:ok, challenge} =
        Challenges.create_challenge(%{
          name: "Original Challenge",
          start_date: DateTime.add(DateTime.utc_now(), 10, :day),
          end_date: DateTime.add(DateTime.utc_now(), 40, :day),
          allowed_sport_types: ["Run"],
          status: "inactive"
        })

      %{admin_user: admin_user, challenge: challenge}
    end

    test "renders edit form with existing data", %{
      conn: conn,
      admin_user: admin_user,
      challenge: challenge
    } do
      conn = authenticate_conn(conn, admin_user)
      {:ok, _view, html} = live(conn, ~p"/admin/challenges/#{challenge.id}/edit")

      assert html =~ "Edit Challenge"
      assert html =~ "Original Challenge"
    end

    test "updates challenge with valid data", %{
      conn: conn,
      admin_user: admin_user,
      challenge: challenge
    } do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/#{challenge.id}/edit")

      view
      |> form("#challenge-form", %{
        challenge: %{
          name: "Updated Challenge Name",
          allowed_sport_types: ["Run", "TrailRun", "Ride"]
        }
      })
      |> render_submit()

      # Verify update in database
      {:ok, updated} = Challenges.get_challenge(challenge.id)
      assert updated.name == "Updated Challenge Name"
      assert "TrailRun" in updated.allowed_sport_types
      assert "Ride" in updated.allowed_sport_types
    end

    test "shows error for non-existent challenge", %{conn: conn, admin_user: admin_user} do
      conn = authenticate_conn(conn, admin_user)
      fake_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/admin/challenges", flash: %{"error" => message}}}} =
               live(conn, ~p"/admin/challenges/#{fake_id}/edit")

      assert message =~ "Challenge not found"
    end
  end

  describe "Deleting a Challenge" do
    setup do
      admin_user = create_admin_user()
      %{admin_user: admin_user}
    end

    test "deletes future challenge successfully", %{conn: conn, admin_user: admin_user} do
      {:ok, future_challenge} =
        Challenges.create_challenge(%{
          name: "Future Challenge",
          start_date: DateTime.add(DateTime.utc_now(), 30, :day),
          end_date: DateTime.add(DateTime.utc_now(), 60, :day),
          allowed_sport_types: ["Run"],
          status: "inactive"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges")

      html =
        view
        |> element("button[phx-click='delete'][phx-value-id='#{future_challenge.id}']")
        |> render_click()

      assert html =~ "Challenge deleted successfully"
      assert {:error, :not_found} = Challenges.get_challenge(future_challenge.id)
    end

    test "cannot delete challenge that has started", %{conn: conn, admin_user: admin_user} do
      {:ok, started_challenge} =
        Challenges.create_challenge(%{
          name: "Started Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -5, :day),
          end_date: DateTime.add(DateTime.utc_now(), 25, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges")

      # The delete button should not be visible for started challenges
      refute view
             |> element("button[phx-click='delete'][phx-value-id='#{started_challenge.id}']")
             |> has_element?()

      # Verify challenge still exists
      assert {:ok, _challenge} = Challenges.get_challenge(started_challenge.id)
    end
  end

  describe "Archiving a Challenge" do
    setup do
      admin_user = create_admin_user()
      %{admin_user: admin_user}
    end

    test "archives past challenge successfully", %{conn: conn, admin_user: admin_user} do
      {:ok, past_challenge} =
        Challenges.create_challenge(%{
          name: "Past Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -30, :day),
          end_date: DateTime.add(DateTime.utc_now(), -5, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges")

      html =
        view
        |> element("button[phx-click='archive'][phx-value-id='#{past_challenge.id}']")
        |> render_click()

      assert html =~ "Challenge archived successfully"

      # Verify challenge was archived
      {:ok, archived} = Challenges.get_challenge(past_challenge.id)
      assert archived.status == "archived"
    end

    test "cannot archive ongoing challenge", %{conn: conn, admin_user: admin_user} do
      {:ok, ongoing_challenge} =
        Challenges.create_challenge(%{
          name: "Ongoing Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -5, :day),
          end_date: DateTime.add(DateTime.utc_now(), 25, :day),
          allowed_sport_types: ["Run"],
          status: "active"
        })

      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges")

      # The archive button should not be visible for ongoing challenges
      refute view
             |> element("button[phx-click='archive'][phx-value-id='#{ongoing_challenge.id}']")
             |> has_element?()

      # Verify challenge status unchanged
      {:ok, challenge} = Challenges.get_challenge(ongoing_challenge.id)
      assert challenge.status == "active"
    end
  end

  describe "Cloning a Challenge" do
    setup do
      admin_user = create_admin_user()

      {:ok, source_challenge} =
        Challenges.create_challenge(%{
          name: "Source Challenge",
          start_date: ~U[2026-06-01 00:00:00Z],
          end_date: ~U[2026-08-31 23:59:59Z],
          allowed_sport_types: ["Run", "TrailRun", "Ride"],
          status: "active"
        })

      %{admin_user: admin_user, source_challenge: source_challenge}
    end

    test "renders clone form with copied sport types", %{
      conn: conn,
      admin_user: admin_user,
      source_challenge: source
    } do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, html} = live(conn, ~p"/admin/challenges/#{source.id}/clone")

      assert html =~ "Clone Challenge"
      assert html =~ "Copy of Source Challenge"

      # Check that sport types are pre-selected
      assert view
             |> element("input[type='checkbox'][value='Run'][checked]")
             |> has_element?()

      assert view
             |> element("input[type='checkbox'][value='TrailRun'][checked]")
             |> has_element?()

      assert view
             |> element("input[type='checkbox'][value='Ride'][checked]")
             |> has_element?()
    end

    test "creates cloned challenge successfully", %{
      conn: conn,
      admin_user: admin_user,
      source_challenge: source
    } do
      conn = authenticate_conn(conn, admin_user)
      {:ok, view, _html} = live(conn, ~p"/admin/challenges/#{source.id}/clone")

      start_date = DateTime.add(DateTime.utc_now(), 90, :day)
      end_date = DateTime.add(DateTime.utc_now(), 180, :day)

      view
      |> form("#challenge-form", %{
        challenge: %{
          name: "Cloned Challenge 2027",
          start_date: format_datetime_local(start_date),
          end_date: format_datetime_local(end_date),
          allowed_sport_types: ["Run", "TrailRun", "Ride"],
          status: "inactive"
        }
      })
      |> render_submit()

      # Verify cloned challenge has same sport types as source
      challenges = Challenges.list_challenges()
      cloned = Enum.find(challenges, &(&1.name == "Cloned Challenge 2027"))
      assert cloned
      assert Enum.sort(cloned.allowed_sport_types) == Enum.sort(source.allowed_sport_types)
    end
  end

  # Helper functions

  defp create_admin_user do
    Repo.insert!(%User{
      id: Ecto.UUID.generate(),
      display_name: "Admin User",
      strava_athlete_id: 999_999,
      is_admin: true,
      joined_at: DateTime.utc_now()
    })
  end

  defp create_regular_user do
    Repo.insert!(%User{
      id: Ecto.UUID.generate(),
      display_name: "Regular User",
      strava_athlete_id: 888_888,
      is_admin: false,
      joined_at: DateTime.utc_now()
    })
  end

  defp authenticate_conn(conn, user) do
    conn
    |> init_test_session(%{user_id: user.id})
    |> assign(:current_user, user)
    |> assign(:current_scope, %{
      authenticated?: true,
      user_id: user.id,
      is_admin: user.is_admin
    })
  end

  defp format_datetime_local(datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
    |> String.replace("Z", "")
  end
end
