defmodule SummerChallenge.AccountsTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.Accounts

  describe "find_or_create_user_from_strava/1" do
    test "creates new user when one doesn't exist" do
      athlete_data = %{
        "id" => 12345,
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
        "id" => 12345,
        "firstname" => "John",
        "lastname" => "Doe"
      }

      {:ok, %{id: user_id} = user} = Accounts.find_or_create_user_from_strava(athlete_data)

      assert {:ok, %{id: ^user_id} = updated_user} =
               Accounts.find_or_create_user_from_strava(athlete_data)

      assert updated_user.id == user.id
    end
  end

  describe "get_user/1" do
    test "returns user with unloaded team association handled correctly" do
      # Create a user directly to bypass Accounts logic if needed, but here we use Accounts
      athlete_data = %{"id" => 98765, "firstname" => "Jane", "lastname" => "Doe"}
      {:ok, user} = Accounts.find_or_create_user_from_strava(athlete_data)

      # Reload from DB ensuring we test the retrieval logic
      retrieved_user = Accounts.get_user(user.id)
      assert retrieved_user.id == user.id
      assert retrieved_user.team_name == nil
    end
  end
end
