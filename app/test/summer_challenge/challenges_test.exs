defmodule SummerChallenge.ChallengesTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.Challenges
  alias SummerChallenge.Model.Challenge

  describe "create_challenge/1" do
    test "creates a challenge with valid attributes" do
      attrs = %{
        name: "Summer Challenge 2026",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run", "TrailRun", "Ride"],
        status: "active"
      }

      assert {:ok, %Challenge{} = challenge} = Challenges.create_challenge(attrs)
      assert challenge.name == "Summer Challenge 2026"
      assert challenge.status == "active"
      assert challenge.allowed_sport_types == ["Run", "TrailRun", "Ride"]
    end

    test "validates name length" do
      attrs = %{
        name: "",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "validates name uniqueness" do
      attrs = %{
        name: "Unique Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      }

      assert {:ok, _challenge} = Challenges.create_challenge(attrs)
      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "validates minimum duration of 7 days" do
      attrs = %{
        name: "Too Short Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-06-05 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "challenge must be at least 7 days long" in errors_on(changeset).end_date
    end

    test "validates end date is after start date" do
      attrs = %{
        name: "Invalid Date Range",
        start_date: ~U[2026-06-15 00:00:00Z],
        end_date: ~U[2026-06-10 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "must be after start date" in errors_on(changeset).end_date
    end

    test "validates status is one of allowed values" do
      attrs = %{
        name: "Invalid Status",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "invalid_status"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "is invalid" in errors_on(changeset).status
    end

    test "validates sport types are valid" do
      attrs = %{
        name: "Invalid Sport Types",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run", "InvalidSport", "Swimming"],
        status: "active"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "contains invalid sport types: InvalidSport, Swimming" in errors_on(changeset).allowed_sport_types
    end

    test "requires at least one sport type" do
      attrs = %{
        name: "No Sports Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: [],
        status: "active"
      }

      assert {:error, changeset} = Challenges.create_challenge(attrs)
      assert "must include at least one sport type" in errors_on(changeset).allowed_sport_types
    end
  end

  describe "list_challenges/1" do
    setup do
      # Create challenges with different statuses
      {:ok, active} = Challenges.create_challenge(%{
        name: "Active Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      {:ok, inactive} = Challenges.create_challenge(%{
        name: "Inactive Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      {:ok, archived} = Challenges.create_challenge(%{
        name: "Archived Challenge",
        start_date: ~U[2025-01-01 00:00:00Z],
        end_date: ~U[2025-03-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      %{active: active, inactive: inactive, archived: archived}
    end

    test "lists all non-archived challenges by default", %{active: active, inactive: inactive} do
      challenges = Challenges.list_challenges()
      
      assert length(challenges) == 2
      assert Enum.any?(challenges, &(&1.id == active.id))
      assert Enum.any?(challenges, &(&1.id == inactive.id))
    end

    test "includes archived challenges when requested", %{active: active, inactive: inactive, archived: archived} do
      challenges = Challenges.list_challenges(include_archived: true)
      
      assert length(challenges) == 3
      assert Enum.any?(challenges, &(&1.id == active.id))
      assert Enum.any?(challenges, &(&1.id == inactive.id))
      assert Enum.any?(challenges, &(&1.id == archived.id))
    end

    test "orders challenges for selector (active first, then by start_date desc)" do
      challenges = Challenges.list_challenges(order_by: :selector_order)
      
      # First challenge should be the active one
      assert hd(challenges).name == "Active Challenge"
    end
  end

  describe "get_challenge/1" do
    test "returns challenge when it exists" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Test Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:ok, found_challenge} = Challenges.get_challenge(challenge.id)
      assert found_challenge.id == challenge.id
      assert found_challenge.name == "Test Challenge"
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Challenges.get_challenge(Ecto.UUID.generate())
    end
  end

  describe "get_default_challenge/0" do
    test "returns active challenge with latest start date" do
      # Create an older active challenge
      {:ok, _older_active} = Challenges.create_challenge(%{
        name: "Older Active",
        start_date: DateTime.add(DateTime.utc_now(), -30, :day),
        end_date: DateTime.add(DateTime.utc_now(), 10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      # Create a newer active challenge
      {:ok, newer_active} = Challenges.create_challenge(%{
        name: "Newer Active",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 20, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:ok, default} = Challenges.get_default_challenge()
      assert default.id == newer_active.id
    end

    test "returns most recent inactive challenge when no active challenges" do
      {:ok, recent_inactive} = Challenges.create_challenge(%{
        name: "Recent Inactive",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      {:ok, _older_inactive} = Challenges.create_challenge(%{
        name: "Older Inactive",
        start_date: ~U[2025-06-01 00:00:00Z],
        end_date: ~U[2025-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      assert {:ok, default} = Challenges.get_default_challenge()
      assert default.id == recent_inactive.id
    end

    test "returns error when no challenges exist" do
      assert {:error, :no_challenges} = Challenges.get_default_challenge()
    end

    test "ignores archived challenges" do
      {:ok, _archived} = Challenges.create_challenge(%{
        name: "Archived",
        start_date: ~U[2025-01-01 00:00:00Z],
        end_date: ~U[2025-03-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      assert {:error, :no_challenges} = Challenges.get_default_challenge()
    end
  end

  describe "update_challenge/2" do
    test "updates challenge with valid attributes" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Original Name",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:ok, updated} = Challenges.update_challenge(challenge, %{
        name: "Updated Name",
        allowed_sport_types: ["Run", "TrailRun", "Ride"]
      })

      assert updated.name == "Updated Name"
      assert updated.allowed_sport_types == ["Run", "TrailRun", "Ride"]
    end

    test "validates updated attributes" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Test Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:error, changeset} = Challenges.update_challenge(challenge, %{
        end_date: ~U[2026-05-01 23:59:59Z]
      })

      assert "must be after start date" in errors_on(changeset).end_date
    end
  end

  describe "delete_challenge/1" do
    test "deletes challenge that has not started" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Future Challenge",
        start_date: DateTime.add(DateTime.utc_now(), 10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 40, :day),
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      assert {:ok, _deleted} = Challenges.delete_challenge(challenge)
      assert {:error, :not_found} = Challenges.get_challenge(challenge.id)
    end

    test "cannot delete challenge that has already started" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Started Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 20, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:error, :cannot_delete} = Challenges.delete_challenge(challenge)
    end
  end

  describe "archive_challenge/1" do
    test "archives challenge that has ended" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Ended Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:ok, archived} = Challenges.archive_challenge(challenge)
      assert archived.status == "archived"
    end

    test "cannot archive challenge that has not ended" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Ongoing Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 20, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:error, :cannot_archive} = Challenges.archive_challenge(challenge)
    end

    test "cannot archive already archived challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Already Archived",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      assert {:error, :cannot_archive} = Challenges.archive_challenge(challenge)
    end
  end

  describe "clone_challenge/2" do
    test "clones challenge with new name and dates" do
      {:ok, original} = Challenges.create_challenge(%{
        name: "Original Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run", "TrailRun", "Ride"],
        status: "active"
      })

      assert {:ok, cloned} = Challenges.clone_challenge(original, %{
        new_name: "Cloned Challenge",
        new_start_date: ~U[2027-06-01 00:00:00Z],
        new_end_date: ~U[2027-08-31 23:59:59Z]
      })

      assert cloned.name == "Cloned Challenge"
      assert cloned.allowed_sport_types == original.allowed_sport_types
      assert cloned.start_date == ~U[2027-06-01 00:00:00Z]
      assert cloned.status == "inactive"
    end

    test "uses default name if not provided" do
      {:ok, original} = Challenges.create_challenge(%{
        name: "Original",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert {:ok, cloned} = Challenges.clone_challenge(original, %{
        new_start_date: ~U[2027-06-01 00:00:00Z],
        new_end_date: ~U[2027-08-31 23:59:59Z]
      })

      assert cloned.name == "Copy of Original"
    end
  end

  describe "get_sport_type_groups_for_challenge/1" do
    test "returns active sport groups for challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Multi-Sport Challenge",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run", "TrailRun", "VirtualRun", "Ride"],
        status: "active"
      })

      groups = Challenges.get_sport_type_groups_for_challenge(challenge)

      assert :running_outdoor in groups
      assert :running_virtual in groups
      assert :cycling_outdoor in groups
      refute :cycling_virtual in groups
    end

    test "returns empty list when no sport types match groups" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Running Only",
        start_date: ~U[2026-06-01 00:00:00Z],
        end_date: ~U[2026-08-31 23:59:59Z],
        allowed_sport_types: ["Run"],
        status: "active"
      })

      groups = Challenges.get_sport_type_groups_for_challenge(challenge)

      assert :running_outdoor in groups
      refute :cycling_outdoor in groups
      refute :running_virtual in groups
      refute :cycling_virtual in groups
    end
  end

  describe "Challenge.active?/1" do
    test "returns true for challenge within date range" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Current Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert Challenge.active?(challenge)
    end

    test "returns false for future challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Future Challenge",
        start_date: DateTime.add(DateTime.utc_now(), 10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 40, :day),
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      refute Challenge.active?(challenge)
    end

    test "returns false for past challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Past Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      refute Challenge.active?(challenge)
    end

    test "returns false for archived challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Archived Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      refute Challenge.active?(challenge)
    end
  end

  describe "Challenge.can_delete?/1" do
    test "returns true for future challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Future Challenge",
        start_date: DateTime.add(DateTime.utc_now(), 10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 40, :day),
        allowed_sport_types: ["Run"],
        status: "inactive"
      })

      assert Challenge.can_delete?(challenge)
    end

    test "returns false for started challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Started Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 20, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      refute Challenge.can_delete?(challenge)
    end
  end

  describe "Challenge.can_archive?/1" do
    test "returns true for ended challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Ended Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      assert Challenge.can_archive?(challenge)
    end

    test "returns false for ongoing challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Ongoing Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -10, :day),
        end_date: DateTime.add(DateTime.utc_now(), 20, :day),
        allowed_sport_types: ["Run"],
        status: "active"
      })

      refute Challenge.can_archive?(challenge)
    end

    test "returns false for already archived challenge" do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Already Archived",
        start_date: DateTime.add(DateTime.utc_now(), -40, :day),
        end_date: DateTime.add(DateTime.utc_now(), -10, :day),
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      refute Challenge.can_archive?(challenge)
    end
  end
end
