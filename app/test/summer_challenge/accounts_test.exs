defmodule SummerChallenge.AccountsTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.Accounts

  describe "find_or_create_user_from_strava/1" do
    test "creates new user when one doesn't exist" do
      athlete_data = %{
        "id" => 12_345,
        "firstname" => "John",
        "lastname" => "Doe",
        "email" => "john@example.com"
      }

      assert {:ok, %{id: _id, display_name: "John D."} = user} =
               Accounts.find_or_create_user_from_strava(athlete_data)

      assert user.team_id == nil
      assert user.team_name == nil
    end

    test "updates existing user" do
      athlete_data = %{
        "id" => 12_345,
        "firstname" => "John",
        "lastname" => "Doe"
      }

      {:ok, %{id: user_id} = user} = Accounts.find_or_create_user_from_strava(athlete_data)

      assert {:ok, %{id: ^user_id} = updated_user} =
               Accounts.find_or_create_user_from_strava(athlete_data)

      assert updated_user.id == user.id
    end
  end

  describe "complete_onboarding/2" do
    test "updates user display name and sets joined_at" do
      athlete_data = %{"id" => 55_555, "firstname" => "New", "lastname" => "User"}
      {:ok, user} = Accounts.find_or_create_user_from_strava(athlete_data)

      assert user.joined_at == nil

      {:ok, updated_user} = Accounts.complete_onboarding(user.id, "Brand New Name")

      assert updated_user.display_name == "Brand New Name"
      assert updated_user.joined_at != nil
    end

    test "does not update if display name is invalid" do
      athlete_data = %{"id" => 66_666, "firstname" => "Another", "lastname" => "User"}
      {:ok, user} = Accounts.find_or_create_user_from_strava(athlete_data)

      {:error, changeset} = Accounts.complete_onboarding(user.id, "")
      assert "can't be blank" in errors_on(changeset).display_name
    end
  end

  describe "get_user/1" do
    test "returns user with unloaded team association handled correctly" do
      # Create a user directly to bypass Accounts logic if needed, but here we use Accounts
      athlete_data = %{"id" => 98_765, "firstname" => "Jane", "lastname" => "Doe"}
      {:ok, user} = Accounts.find_or_create_user_from_strava(athlete_data)

      # Reload from DB ensuring we test the retrieval logic
      retrieved_user = Accounts.get_user(user.id)
      assert retrieved_user.id == user.id
      assert retrieved_user.team_name == nil
    end
  end
end
