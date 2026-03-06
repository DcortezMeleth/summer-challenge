defmodule SummerChallenge.TeamsTest do
  use SummerChallenge.DataCase, async: true

  alias SummerChallenge.Accounts
  alias SummerChallenge.Model.Team
  alias SummerChallenge.Model.User
  alias SummerChallenge.Teams

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp create_user(strava_id, first_name \\ nil, last_name \\ "X") do
    first_name = first_name || "User#{strava_id}"

    {:ok, user} =
      Accounts.find_or_create_user_from_strava(%{
        "id" => strava_id,
        "firstname" => first_name,
        "lastname" => last_name
      })

    user
  end

  defp create_user_and_team(strava_id, team_name) do
    user = create_user(strava_id)
    {:ok, team} = Teams.create_team(user.id, %{name: team_name})
    {user, team}
  end

  # ---------------------------------------------------------------------------
  # create_team/2
  # ---------------------------------------------------------------------------

  describe "create_team/2" do
    test "creates a team with the user as owner and first member" do
      user = create_user(1001)

      assert {:ok, team} = Teams.create_team(user.id, %{name: "Flying Foxes"})

      assert team.name == "Flying Foxes"
      assert team.owner_user_id == user.id
      assert team.member_count == 1
      assert Enum.any?(team.members, &(&1.id == user.id))
    end

    test "trims whitespace from team name" do
      user = create_user(1002)

      assert {:ok, team} = Teams.create_team(user.id, %{name: "  Padded Name  "})
      assert team.name == "Padded Name"
    end

    test "returns error when user is already in a team" do
      user = create_user(1003)
      {:ok, _team} = Teams.create_team(user.id, %{name: "First Team"})

      assert {:error, :already_in_team} = Teams.create_team(user.id, %{name: "Second Team"})
    end

    test "returns changeset error for blank name" do
      user = create_user(1004)

      assert {:error, changeset} = Teams.create_team(user.id, %{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns changeset error for whitespace-only name" do
      user = create_user(1005)

      assert {:error, changeset} = Teams.create_team(user.id, %{name: "   "})
      refute changeset.valid?
    end

    test "returns changeset error for duplicate team name" do
      user1 = create_user(1006)
      user2 = create_user(1007)
      {:ok, _} = Teams.create_team(user1.id, %{name: "Unique Name"})

      assert {:error, changeset} = Teams.create_team(user2.id, %{name: "Unique Name"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "returns error for unknown user" do
      assert {:error, :user_not_found} =
               Teams.create_team("00000000-0000-0000-0000-000000000000", %{name: "Team"})
    end
  end

  # ---------------------------------------------------------------------------
  # join_team/2
  # ---------------------------------------------------------------------------

  describe "join_team/2" do
    test "user joins a team and their team_id is updated" do
      {_owner, team} = create_user_and_team(2001, "Joinable Team")
      joiner = create_user(2002, "Bob")

      assert {:ok, updated_team} = Teams.join_team(joiner.id, team.id)
      assert updated_team.member_count == 2
      assert Enum.any?(updated_team.members, &(&1.id == joiner.id))
    end

    test "returns error when user is already in a team" do
      {user, _team} = create_user_and_team(2003, "My Team")
      {_other_owner, other_team} = create_user_and_team(2004, "Other Team")

      assert {:error, :already_in_team} = Teams.join_team(user.id, other_team.id)
    end

    test "returns error when team is full" do
      {_owner, team} = create_user_and_team(2005, "Full Team")

      for strava_id <- 2006..2009 do
        user = create_user(strava_id)
        assert {:ok, _} = Teams.join_team(user.id, team.id)
      end

      late_user = create_user(2010)
      assert {:error, :team_full} = Teams.join_team(late_user.id, team.id)
    end

    test "returns error when team does not exist" do
      user = create_user(2011)

      assert {:error, :not_found} =
               Teams.join_team(user.id, "00000000-0000-0000-0000-000000000000")
    end

    test "returns error for unknown user" do
      {_owner, team} = create_user_and_team(2012, "Some Team")

      assert {:error, :user_not_found} =
               Teams.join_team("00000000-0000-0000-0000-000000000000", team.id)
    end
  end

  # ---------------------------------------------------------------------------
  # leave_team/1
  # ---------------------------------------------------------------------------

  describe "leave_team/1" do
    test "user leaves their team and team_id is cleared" do
      {user, _team} = create_user_and_team(3001, "Leavable Team")

      assert {:ok, :left} = Teams.leave_team(user.id)

      updated_user = Repo.get!(User, user.id)
      assert is_nil(updated_user.team_id)
    end

    test "clears owner_user_id when the owner leaves" do
      {owner, team} = create_user_and_team(3002, "Owner Leaves")

      assert {:ok, :left} = Teams.leave_team(owner.id)

      updated_team = Repo.get!(Team, team.id)
      assert is_nil(updated_team.owner_user_id)
    end

    test "non-owner leaving does not clear owner_user_id" do
      {owner, team} = create_user_and_team(3003, "Owner Stays")
      member = create_user(3004, "Member")
      {:ok, _} = Teams.join_team(member.id, team.id)

      assert {:ok, :left} = Teams.leave_team(member.id)

      updated_team = Repo.get!(Team, team.id)
      assert updated_team.owner_user_id == owner.id
    end

    test "returns error when user is not in a team" do
      user = create_user(3005)

      assert {:error, :not_in_team} = Teams.leave_team(user.id)
    end

    test "returns error for unknown user" do
      assert {:error, :user_not_found} =
               Teams.leave_team("00000000-0000-0000-0000-000000000000")
    end
  end

  # ---------------------------------------------------------------------------
  # rename_team/3
  # ---------------------------------------------------------------------------

  describe "rename_team/3" do
    test "owner can rename the team" do
      {owner, team} = create_user_and_team(4001, "Old Name")

      assert {:ok, updated_team} = Teams.rename_team(team.id, owner.id, "New Name")
      assert updated_team.name == "New Name"
    end

    test "admin can rename any team" do
      {_owner, team} = create_user_and_team(4002, "Rename Target")

      {:ok, admin} =
        Accounts.find_or_create_user_from_strava(%{
          "id" => 4003,
          "firstname" => "Admin",
          "lastname" => "User",
          "email" => "admin@example.com"
        })

      admin_record = Repo.get!(User, admin.id)
      admin_record |> Ecto.Changeset.change(%{is_admin: true}) |> Repo.update!()

      assert {:ok, updated_team} = Teams.rename_team(team.id, admin.id, "Admin Renamed")
      assert updated_team.name == "Admin Renamed"
    end

    test "non-owner non-admin gets unauthorized error" do
      {_owner, team} = create_user_and_team(4004, "Protected Team")
      other = create_user(4005, "Other")

      assert {:error, :unauthorized} = Teams.rename_team(team.id, other.id, "Hijacked")
    end

    test "trims whitespace from new name" do
      {owner, team} = create_user_and_team(4006, "Trim Me")

      assert {:ok, updated_team} = Teams.rename_team(team.id, owner.id, "  Trimmed  ")
      assert updated_team.name == "Trimmed"
    end

    test "returns changeset error for blank name" do
      {owner, team} = create_user_and_team(4007, "Valid Name")

      assert {:error, changeset} = Teams.rename_team(team.id, owner.id, "")
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error for unknown team" do
      user = create_user(4008)

      assert {:error, :not_found} =
               Teams.rename_team("00000000-0000-0000-0000-000000000000", user.id, "Name")
    end
  end

  # ---------------------------------------------------------------------------
  # delete_team/2
  # ---------------------------------------------------------------------------

  describe "delete_team/2" do
    test "owner can delete the team" do
      {owner, team} = create_user_and_team(5001, "To Be Deleted")

      assert {:ok, :deleted} = Teams.delete_team(team.id, owner.id)
      assert is_nil(Repo.get(Team, team.id))
    end

    test "all members become teamless on deletion" do
      {owner, team} = create_user_and_team(5002, "Delete Me")
      member = create_user(5003, "Member")
      {:ok, _} = Teams.join_team(member.id, team.id)

      assert {:ok, :deleted} = Teams.delete_team(team.id, owner.id)

      updated_owner = Repo.get!(User, owner.id)
      updated_member = Repo.get!(User, member.id)

      assert is_nil(updated_owner.team_id)
      assert is_nil(updated_member.team_id)
    end

    test "admin can delete any team" do
      {_owner, team} = create_user_and_team(5004, "Admin Delete")

      {:ok, admin} =
        Accounts.find_or_create_user_from_strava(%{
          "id" => 5005,
          "firstname" => "Admin",
          "lastname" => "Delete",
          "email" => "admin2@example.com"
        })

      admin_record = Repo.get!(User, admin.id)
      admin_record |> Ecto.Changeset.change(%{is_admin: true}) |> Repo.update!()

      assert {:ok, :deleted} = Teams.delete_team(team.id, admin.id)
    end

    test "non-owner non-admin gets unauthorized error" do
      {_owner, team} = create_user_and_team(5006, "Protected Delete")
      other = create_user(5007, "Other")

      assert {:error, :unauthorized} = Teams.delete_team(team.id, other.id)
      assert Repo.get(Team, team.id)
    end

    test "returns error for unknown team" do
      user = create_user(5008)

      assert {:error, :not_found} =
               Teams.delete_team("00000000-0000-0000-0000-000000000000", user.id)
    end
  end

  # ---------------------------------------------------------------------------
  # list_teams/0
  # ---------------------------------------------------------------------------

  describe "list_teams/0" do
    test "returns empty list when no teams exist" do
      assert Teams.list_teams() == []
    end

    test "returns all teams with member counts" do
      {_owner1, _} = create_user_and_team(6001, "Alpha Team")
      {_owner2, t2} = create_user_and_team(6002, "Beta Team")
      extra = create_user(6003, "Extra")
      {:ok, _} = Teams.join_team(extra.id, t2.id)

      teams = Teams.list_teams()
      assert length(teams) == 2

      alpha = Enum.find(teams, &(&1.name == "Alpha Team"))
      beta = Enum.find(teams, &(&1.name == "Beta Team"))

      assert alpha.member_count == 1
      assert beta.member_count == 2
    end

    test "returns teams ordered alphabetically" do
      {_owner, _} = create_user_and_team(6004, "Zephyr")
      {_owner, _} = create_user_and_team(6005, "Alpha")
      {_owner, _} = create_user_and_team(6006, "Midway")

      names = Enum.map(Teams.list_teams(), & &1.name)
      assert names == ["Alpha", "Midway", "Zephyr"]
    end
  end

  # ---------------------------------------------------------------------------
  # get_team/1
  # ---------------------------------------------------------------------------

  describe "get_team/1" do
    test "returns team with members preloaded" do
      {owner, team} = create_user_and_team(7001, "Fetch Me")
      member = create_user(7002, "Member")
      {:ok, _} = Teams.join_team(member.id, team.id)

      assert {:ok, fetched} = Teams.get_team(team.id)
      assert fetched.name == "Fetch Me"
      assert fetched.member_count == 2
      assert Enum.any?(fetched.members, &(&1.id == owner.id))
      assert Enum.any?(fetched.members, &(&1.id == member.id))
    end

    test "returns error for unknown team" do
      assert {:error, :not_found} =
               Teams.get_team("00000000-0000-0000-0000-000000000000")
    end
  end

  # ---------------------------------------------------------------------------
  # team_size_cap/0
  # ---------------------------------------------------------------------------

  describe "team_size_cap/0" do
    test "returns the configured cap" do
      assert Teams.team_size_cap() == 5
    end
  end
end
