defmodule SummerChallenge.Workers.SyncAllWorkerTest do
  use SummerChallenge.DataCase, async: true
  use Oban.Testing, repo: SummerChallenge.Repo

  import Mox

  alias SummerChallenge.Challenges
  alias SummerChallenge.Model.Activity
  alias SummerChallenge.Model.User
  alias SummerChallenge.Model.UserCredential
  alias SummerChallenge.OAuth.StravaMock
  alias SummerChallenge.Workers.SyncAllWorker

  setup :verify_on_exit!

  describe "perform/1" do
    setup do
      # Create a default challenge for testing
      {:ok, challenge} =
        Challenges.create_challenge(%{
          name: "Test Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -7, :day),
          end_date: DateTime.add(DateTime.utc_now(), 7, :day),
          allowed_sport_types: ["Run", "Ride"],
          status: "active"
        })

      user1 = Repo.insert!(%User{display_name: "User 1", strava_athlete_id: 1001})
      user2 = Repo.insert!(%User{display_name: "User 2", strava_athlete_id: 1002})

      Repo.insert!(%UserCredential{
        user_id: user1.id,
        access_token: "token1",
        refresh_token: "refresh1",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

      Repo.insert!(%UserCredential{
        user_id: user2.id,
        access_token: "token2",
        refresh_token: "refresh2",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

      {:ok, challenge: challenge, user1: user1, user2: user2}
    end

    test "successfully syncs all users", %{challenge: challenge} do
      expect(StravaMock, :list_activities, 2, fn %{access_token: _token}, _params ->
        {:ok,
         [
           %{
             "id" => :rand.uniform(100_000),
             "type" => "Run",
             "start_date" => DateTime.to_iso8601(DateTime.utc_now()),
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 100
           }
         ]}
      end)

      assert {:ok, result} = perform_job(SyncAllWorker, %{})

      assert result.total == 2
      assert result.success == 2
      assert result.error == 0

      # Verify activities were created
      activities = Repo.all(Activity)
      assert length(activities) == 2
      assert Enum.all?(activities, &(&1.challenge_id == challenge.id))
    end

    test "handles errors gracefully when no challenge exists" do
      # Delete all challenges
      Repo.delete_all(SummerChallenge.Model.Challenge)

      assert {:error, :no_challenges} = perform_job(SyncAllWorker, %{})
    end

    test "returns stats even when some users fail" do
      # Make one user's sync fail by having the API return an error
      StravaMock
      |> expect(:list_activities, fn %{access_token: "token1"}, _params ->
        {:error, :api_error}
      end)
      |> expect(:list_activities, fn %{access_token: "token2"}, _params ->
        {:ok, []}
      end)

      assert {:ok, result} = perform_job(SyncAllWorker, %{})

      assert result.total == 2
      assert result.success == 1
      assert result.error == 1
    end

    test "can be enqueued" do
      # Test that the job can be enqueued successfully
      assert {:ok, %Oban.Job{}} = %{} |> SyncAllWorker.new() |> Oban.insert()

      # Verify job is in the queue
      assert_enqueued(worker: SyncAllWorker)
    end

    test "enforces unique constraint to prevent duplicate jobs" do
      # Insert first job
      assert {:ok, job1} = %{} |> SyncAllWorker.new() |> Oban.insert()

      # Try to insert duplicate job (should return the same job due to unique constraint)
      assert {:ok, job2} = %{} |> SyncAllWorker.new() |> Oban.insert()

      # Should be the same job ID due to unique constraint
      assert job1.id == job2.id
    end
  end
end
